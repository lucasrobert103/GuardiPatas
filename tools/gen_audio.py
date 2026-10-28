#!/usr/bin/env python3
"""Gera todos os efeitos sonoros e músicas do GuardiPatas.

Tudo é sintetizado do zero (sem amostras de terceiros), então o áudio é 100%
original e pode ser regenerado/ajustado a qualquer momento:

    python3 tools/gen_audio.py            # grava em assets/audio/

Dependência: numpy. Saída: WAV PCM 16 bits mono. Sons em loop recebem um
chunk 'smpl' com os pontos de loop, que o importador de WAV do Godot 4 lê
automaticamente (modo de loop "Detect From WAV").
"""
import os
import struct
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(1234)  # determinístico: mesmo resultado a cada execução


# ---------------------------------------------------------------- utilidades
def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env_adsr(n, a=0.005, d=0.05, s=0.6, r=0.1):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, n - a_n - d_n - r_n)
    e = np.concatenate([
        np.linspace(0, 1, max(a_n, 1)),
        np.linspace(1, s, max(d_n, 1)),
        np.full(s_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    return e[:n] if len(e) >= n else np.pad(e, (0, n - len(e)))


def env_exp(n, decay):
    return np.exp(-np.arange(n) / (SR * decay))


def sweep_phase(f0, f1, n, curve=1.0):
    k = np.linspace(0, 1, n) ** curve
    freq = f0 + (f1 - f0) * k
    return 2 * np.pi * np.cumsum(freq) / SR


def lowpass(x, cutoff):
    # filtro de um polo, suficiente para suavizar ruído
    # cutoff pode ser um número ou um array (filtro que "abre" com o tempo)
    a = np.broadcast_to(np.exp(-2 * np.pi * np.asarray(cutoff, dtype=np.float64) / SR), x.shape)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a[i]) * v + a[i] * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def noise(n):
    return rng.uniform(-1, 1, n)


def tri(phase):
    return 2 / np.pi * np.arcsin(np.sin(phase))


def saw(phase):
    return 2 * ((phase / (2 * np.pi)) % 1.0) - 1


def normalize(x, peak=0.85):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def mix_at(buf, x, start):
    end = min(len(buf), start + len(x))
    buf[start:end] += x[: end - start]


def write_wav(name, x, loop=False, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    if peak is not None:
        x = normalize(x, peak)
    pcm = np.clip(x * 32767, -32768, 32767).astype("<i2").tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(pcm)) + pcm
    if len(pcm) % 2:
        chunks += b"\0"
    if loop:
        frames = len(pcm) // 2
        # 9 campos de cabeçalho (o 8º = número de loops) + 1 loop de 6 campos
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, frames - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    riff = b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks
    with open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.write(riff)
    print(f"  {name}.wav  {len(x) / SR:5.2f}s{'  (loop)' if loop else ''}")


def crossfade_loop(x, fade=0.05):
    """Deixa o fim emendar no começo sem clique."""
    n = int(fade * SR)
    head, tail = x[:n].copy(), x[-n:].copy()
    w = np.linspace(0, 1, n)
    x = x[:-n].copy()
    x[:n] = head * w + tail * (1 - w)
    return x


# ---------------------------------------------------------------- instrumentos
def bell(freq, dur, bright=1.0):
    t = t_axis(dur)
    n = len(t)
    x = (np.sin(2 * np.pi * freq * t)
         + 0.45 * bright * np.sin(2 * np.pi * freq * 2.76 * t) * env_exp(n, dur * 0.25)
         + 0.25 * bright * np.sin(2 * np.pi * freq * 5.40 * t) * env_exp(n, dur * 0.12))
    return x * env_exp(n, dur * 0.35) * env_adsr(n, 0.002, 0.01, 1.0, 0.02)


def marimba(freq, dur=0.35):
    t = t_axis(dur)
    n = len(t)
    x = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 4.0 * t) * env_exp(n, 0.03)
    return x * env_exp(n, 0.12) * env_adsr(n, 0.002, 0.01, 1.0, 0.03)


def pluck_bass(freq, dur=0.3):
    t = t_axis(dur)
    n = len(t)
    x = tri(2 * np.pi * freq * t) + 0.2 * np.sin(2 * np.pi * freq * 2 * t)
    return x * env_exp(n, 0.18) * env_adsr(n, 0.004, 0.02, 1.0, 0.04)


def soft_kick(dur=0.18):
    n = int(SR * dur)
    return np.sin(sweep_phase(140, 45, n, 0.4)) * env_exp(n, 0.06)


def hat(dur=0.05):
    n = int(SR * dur)
    return highpass(noise(n), 5000) * env_exp(n, 0.012)


def shaker(dur=0.08):
    n = int(SR * dur)
    return highpass(noise(n), 3000) * env_adsr(n, 0.02, 0.02, 0.5, 0.03) * 0.6


def note(name):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    midi = 12 * (octave + 1) + names[pitch]
    return 440.0 * 2 ** ((midi - 69) / 12)


# ---------------------------------------------------------------- efeitos
def sfx_all():
    # Interface
    n = int(0.07 * SR)
    write_wav("ui_click", np.sin(sweep_phase(700, 1300, n, 0.5)) * env_exp(n, 0.025))
    n = int(0.09 * SR)
    write_wav("ui_back", np.sin(sweep_phase(1100, 600, n, 0.7)) * env_exp(n, 0.03))
    write_wav("ui_locked", np.concatenate([
        np.sin(2 * np.pi * 220 * t_axis(0.08)) * env_exp(int(0.08 * SR), 0.03),
        np.sin(2 * np.pi * 185 * t_axis(0.12)) * env_exp(int(0.12 * SR), 0.04)]) * 0.8)

    # Desenho: rabisco de giz de cera (ruído filtrado com "grãos")
    dur = 0.6
    n = int(dur * SR)
    grain = (np.sin(2 * np.pi * 37 * t_axis(dur)) * 0.5 + 0.5) ** 2
    scribble = lowpass(highpass(noise(n), 900), 4200) * (0.55 + 0.45 * grain)
    write_wav("draw_loop", crossfade_loop(scribble), loop=True, peak=0.6)

    n = int(0.16 * SR)
    write_wav("draw_end", np.sin(sweep_phase(520, 260, n, 0.6)) * env_exp(n, 0.05)
              + 0.3 * lowpass(noise(n), 1500) * env_exp(n, 0.02))
    n = int(0.35 * SR)
    write_wav("ink_empty", (np.sin(sweep_phase(330, 160, n)) + 0.3 * tri(sweep_phase(330, 160, n)))
              * env_adsr(n, 0.005, 0.05, 0.7, 0.15), peak=0.7)
    n = int(0.12 * SR)
    write_wav("draw_blocked", tri(2 * np.pi * 140 * t_axis(0.12)) * env_exp(n, 0.04), peak=0.5)

    # Linha caindo no chão
    n = int(0.25 * SR)
    write_wav("line_land", np.sin(sweep_phase(180, 60, n, 0.5)) * env_exp(n, 0.06)
              + 0.5 * lowpass(noise(n), 800) * env_exp(n, 0.03))

    # Zumbido de abelha (loop): dente-de-serra com vibrato, filtrado
    dur = 0.8
    t = t_axis(dur)
    vib = 6 * np.sin(2 * np.pi * 9 * t)
    ph = 2 * np.pi * np.cumsum(205 + vib) / SR
    buzz = lowpass(saw(ph) + 0.5 * saw(ph * 1.01), 1600) * (0.8 + 0.2 * np.sin(2 * np.pi * 25 * t))
    write_wav("buzz_bee", crossfade_loop(buzz), loop=True, peak=0.5)

    # Mosquito (loop): agudo e fino
    ph = 2 * np.pi * np.cumsum(620 + 25 * np.sin(2 * np.pi * 5 * t)) / SR
    write_wav("buzz_mosquito", crossfade_loop(lowpass(saw(ph), 3000)), loop=True, peak=0.35)

    # Vespa: carga subindo + avanço
    n = int(0.5 * SR)
    ph = sweep_phase(160, 420, n, 1.5)
    write_wav("wasp_charge", lowpass(saw(ph), 2200) * env_adsr(n, 0.05, 0.1, 0.9, 0.05), peak=0.6)
    n = int(0.3 * SR)
    write_wav("wasp_dash", lowpass(noise(n), 2500) * env_adsr(n, 0.01, 0.05, 0.6, 0.2)
              + 0.4 * np.sin(sweep_phase(500, 200, n)) * env_exp(n, 0.1), peak=0.6)

    # Passinhos
    n = int(0.03 * SR)
    write_wav("ant_step", highpass(noise(n), 2500) * env_exp(n, 0.005), peak=0.35)
    n = int(0.09 * SR)
    write_wav("beetle_step", np.sin(sweep_phase(160, 90, n)) * env_exp(n, 0.025)
              + 0.4 * lowpass(noise(n), 600) * env_exp(n, 0.015), peak=0.6)

    # Mariposa batendo asas (loop)
    dur = 0.5
    n = int(dur * SR)
    flap = (np.sin(2 * np.pi * 8 * t_axis(dur)) * 0.5 + 0.5) ** 3
    write_wav("moth_flutter", crossfade_loop(lowpass(noise(n), 900) * flap), loop=True, peak=0.4)

    # Inseto batendo na barreira: "boink" de desenho animado
    n = int(0.18 * SR)
    t = t_axis(0.18)
    f = 520 + 180 * np.sin(2 * np.pi * 18 * t) * env_exp(n, 0.06)
    write_wav("bonk", np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.06), peak=0.55)

    # Picada (não violenta): "boing" + guincho cômico
    n1 = int(0.18 * SR)
    boing = np.sin(sweep_phase(300, 900, n1, 0.5)) * env_exp(n1, 0.08)
    n2 = int(0.3 * SR)
    t2 = t_axis(0.3)
    squeak = np.sin(2 * np.pi * np.cumsum(1200 + 300 * np.sin(2 * np.pi * 12 * t2)) / SR) * env_adsr(n2, 0.01, 0.05, 0.6, 0.15)
    write_wav("sting", np.concatenate([boing, squeak * 0.7]))

    # Susto: "glup"
    n = int(0.22 * SR)
    write_wav("gasp", np.sin(sweep_phase(400, 900, n, 0.3)) * env_adsr(n, 0.01, 0.05, 0.5, 0.1), peak=0.5)

    # Splash (insetos levados pela água)
    n = int(0.45 * SR)
    sp = lowpass(noise(n), 2500) * env_exp(n, 0.12)
    bub = np.zeros(n)
    for k in range(5):
        st = int(rng.uniform(0.02, 0.3) * SR)
        bn = int(0.06 * SR)
        mix_at(bub, np.sin(sweep_phase(500 + 150 * k, 1200 + 150 * k, bn)) * env_exp(bn, 0.02) * 0.4, st)
    write_wav("splash", sp + bub, peak=0.6)

    # Estrelas (ding ascendente)
    for i, f in enumerate([note("E6"), note("G6"), note("C7")]):
        write_wav(f"star{i + 1}", bell(f, 0.7), peak=0.6)

    # Moeda
    a = bell(note("B5"), 0.08, 0.3)
    b = bell(note("E6"), 0.35, 0.3)
    write_wav("coin", np.concatenate([a, b]), peak=0.5)

    # Tique do cronômetro (bloco de madeira)
    n = int(0.06 * SR)
    write_wav("tick", np.sin(2 * np.pi * 1800 * t_axis(0.06)) * env_exp(n, 0.01)
              + 0.3 * np.sin(2 * np.pi * 900 * t_axis(0.06)) * env_exp(n, 0.015), peak=0.45)

    # Pop de confete
    n = int(0.12 * SR)
    write_wav("pop", np.sin(sweep_phase(900, 300, n, 0.3)) * env_exp(n, 0.02)
              + 0.6 * highpass(noise(n), 2000) * env_exp(n, 0.01), peak=0.6)

    # Dica: brilho mágico
    dur = 0.9
    buf = np.zeros(int(dur * SR))
    for i, nm in enumerate(["C6", "E6", "G6", "B6", "D7"]):
        mix_at(buf, bell(note(nm), 0.5, 0.6) * 0.5, int(i * 0.07 * SR))
    write_wav("hint", buf, peak=0.55)

    # Vitória: arpejo alegre + acorde final
    dur = 1.8
    buf = np.zeros(int(dur * SR))
    for i, nm in enumerate(["C5", "E5", "G5", "C6"]):
        mix_at(buf, marimba(note(nm), 0.4), int(i * 0.11 * SR))
    for nm in ["C5", "E5", "G5", "C6", "E6"]:
        mix_at(buf, bell(note(nm), 1.3, 0.5) * 0.35, int(0.48 * SR))
    mix_at(buf, soft_kick() * 0.6, int(0.48 * SR))
    write_wav("win", buf)

    # Derrota: "wah wah wah waaah" de trombone de brinquedo
    buf = np.zeros(int(2.0 * SR))
    for i, (nm, d) in enumerate([("G4", 0.32), ("F#4", 0.32), ("F4", 0.32), ("E4", 0.9)]):
        n = int(d * SR)
        t = t_axis(d)
        f0 = note(nm)
        vib = 1 + (0.02 * np.sin(2 * np.pi * 6 * t) if i == 3 else 0)
        ph = 2 * np.pi * np.cumsum(f0 * vib * (1 - 0.03 * t / d)) / SR
        tone = lowpass(saw(ph) * 0.6 + tri(ph) * 0.6, 1200 + 900 * np.sin(np.pi * t / d))
        mix_at(buf, tone * env_adsr(n, 0.03, 0.05, 0.8, 0.12), int(i * 0.34 * SR))
    write_wav("lose", buf, peak=0.7)

    # Abertura RetroNexa: arpejo chiptune (onda quadrada) + acorde brilhante
    def square(freq, dur, duty=0.5):
        t = t_axis(dur)
        ph = (freq * t) % 1.0
        n = len(t)
        return np.where(ph < duty, 1.0, -1.0) * env_adsr(n, 0.002, 0.03, 0.7, 0.04)
    buf = np.zeros(int(2.2 * SR))
    seq = ["C5", "E5", "G5", "C6", "E6", "G6"]
    for i, nm in enumerate(seq):
        mix_at(buf, square(note(nm), 0.12, 0.25) * 0.35, int(i * 0.09 * SR))
    for nm in ["C5", "G5", "C6", "E6"]:
        mix_at(buf, square(note(nm), 1.1, 0.5) * 0.16 * env_exp(int(1.1 * SR), 0.5), int(0.6 * SR))
    mix_at(buf, bell(note("C7"), 1.2, 0.8) * 0.3, int(0.6 * SR))
    mix_at(buf, soft_kick() * 0.7, int(0.6 * SR))
    write_wav("retro_jingle", buf, peak=0.7)

    # Sustos com "voz" própria (Patinha, Nuvem, Tito/Lulu)
    def formant_voice(f0, f1, dur, vib=0.0, bright=1800):
        n = int(dur * SR)
        t = t_axis(dur)
        f = np.linspace(f0, f1, n) * (1 + vib * np.sin(2 * np.pi * 7 * t))
        ph = 2 * np.pi * np.cumsum(f) / SR
        return lowpass(saw(ph) + 0.4 * saw(ph * 2), bright) * env_adsr(n, 0.01, 0.04, 0.8, 0.06)
    write_wav("quack", np.concatenate([formant_voice(520, 420, 0.11, 0, 1400), np.zeros(int(0.03 * SR)), formant_voice(560, 380, 0.16, 0, 1300)]), peak=0.6)
    write_wav("baa", formant_voice(330, 300, 0.5, 0.06, 1700), peak=0.55)
    n = int(0.3 * SR)
    bl = np.sin(sweep_phase(300, 1100, n, 0.5)) * env_exp(n, 0.1)
    for k in range(3):
        bn = int(0.06 * SR)
        mix_at(bl, np.sin(sweep_phase(700 + 200 * k, 1500 + 200 * k, bn)) * env_exp(bn, 0.02) * 0.5, int((0.08 + k * 0.06) * SR))
    write_wav("bloop", bl, peak=0.55)

    # Desbloqueio: fanfarrinha
    buf = np.zeros(int(1.4 * SR))
    for i, nm in enumerate(["G5", "C6", "E6", "G6"]):
        mix_at(buf, bell(note(nm), 0.9, 0.8) * 0.6, int(i * 0.09 * SR))
    write_wav("unlock", buf)


# ---------------------------------------------------------------- músicas
def render_song(bpm, bars, chords, melody, swing=0.0, drums=True, mel_inst=marimba, mel_gain=0.55):
    beat = 60.0 / bpm
    total = bars * 4 * beat
    buf = np.zeros(int(total * SR) + SR)

    def at(b):
        # b em batidas; swing atrasa colcheias fracas
        frac = b % 1.0
        if abs(frac - 0.5) < 1e-6:
            b += swing * 0.5
        return int(b * beat * SR)

    for bar in range(bars):
        root, third, fifth = chords[bar % len(chords)]
        base = bar * 4
        # baixo: tônica nos tempos 1 e 3, quinta no 2.5
        mix_at(buf, pluck_bass(note(root), beat * 0.9) * 0.55, at(base))
        mix_at(buf, pluck_bass(note(root), beat * 0.9) * 0.45, at(base + 2))
        mix_at(buf, pluck_bass(note(fifth), beat * 0.5) * 0.35, at(base + 3.5))
        # acompanhamento: acorde em colcheias suaves (bell leve)
        for k, b in enumerate([0.5, 1.5, 2.5, 3.5]):
            for nm in (third, fifth):
                mix_at(buf, bell(note(nm), beat * 0.6, 0.2) * 0.10, at(base + b))
        if drums:
            mix_at(buf, soft_kick() * 0.5, at(base))
            mix_at(buf, soft_kick() * 0.35, at(base + 2))
            for b in np.arange(0, 4, 0.5):
                mix_at(buf, hat() * (0.18 if b % 1 else 0.1), at(base + b))
            mix_at(buf, shaker() * 0.25, at(base + 1))
            mix_at(buf, shaker() * 0.25, at(base + 3))

    for (b, nm, d) in melody:
        if nm is None:
            continue
        mix_at(buf, mel_inst(note(nm), max(0.2, d * beat * 1.2)) * mel_gain, at(b))

    loop_len = int(total * SR)
    # a cauda que passa do fim volta para o começo, para emendar sem corte
    tail = buf[loop_len:]
    out = buf[:loop_len].copy()
    out[: len(tail)] += tail
    return out


def melody_from(pattern, bars_per_phrase=4):
    """pattern: lista de frases; cada frase é lista de (batida_relativa, nota, duração)."""
    mel = []
    for i, phrase in enumerate(pattern):
        off = i * bars_per_phrase * 4
        for (b, nm, d) in phrase:
            mel.append((off + b, nm, d))
    return mel


def music_all():
    # Tema do menu: calmo, 92 bpm, I - vi - IV - V em Dó
    chords = [("C3", "E4", "G4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"), ("G2", "B3", "D4")]
    a = [(0, "E5", 1), (1, "G5", 1), (2, "A5", 0.5), (2.5, "G5", 0.5), (3, "E5", 1),
         (4, "C5", 1), (5, "E5", 0.5), (5.5, "D5", 0.5), (6, "C5", 2),
         (8, "A4", 1), (9, "C5", 1), (10, "F5", 1), (11, "E5", 1),
         (12, "D5", 1.5), (13.5, "E5", 0.5), (14, "D5", 1), (15, "B4", 1)]
    b = [(0, "G5", 0.5), (0.5, "A5", 0.5), (1, "G5", 1), (2, "E5", 1), (3, "C5", 1),
         (4, "E5", 1), (5, "D5", 1), (6, "C5", 1), (7, "A4", 1),
         (8, "F5", 1), (9, "E5", 0.5), (9.5, "D5", 0.5), (10, "C5", 1), (11, "A4", 1),
         (12, "B4", 1), (13, "D5", 1), (14, "G5", 2)]
    song = render_song(92, 8, chords, melody_from([a, b]), swing=0.15, drums=False)
    write_wav("music_menu", song, loop=True, peak=0.7)

    # Tema das fases: brincalhão, 112 bpm, com bateria leve
    chords = [("C3", "E4", "G4"), ("F2", "A3", "C4"), ("A2", "C4", "E4"), ("G2", "B3", "D4")]
    a = [(0, "C5", 0.5), (0.5, "E5", 0.5), (1, "G5", 0.5), (1.5, "E5", 0.5), (2, "A5", 1), (3, "G5", 1),
         (4, "F5", 0.5), (4.5, "A5", 0.5), (5, "C6", 1), (6, "A5", 0.5), (6.5, "G5", 0.5), (7, "F5", 1),
         (8, "E5", 0.5), (8.5, "G5", 0.5), (9, "C6", 0.5), (9.5, "B5", 0.5), (10, "A5", 1), (11, "E5", 1),
         (12, "D5", 0.5), (12.5, "E5", 0.5), (13, "G5", 1), (14, "B4", 1), (15, "D5", 1)]
    b = [(0, "G5", 1), (1, "E5", 0.5), (1.5, "G5", 0.5), (2, "C6", 1.5), (3.5, "B5", 0.5),
         (4, "A5", 1), (5, "F5", 0.5), (5.5, "A5", 0.5), (6, "C6", 1), (7, "A5", 1),
         (8, "G5", 0.5), (8.5, "E5", 0.5), (9, "C5", 0.5), (9.5, "E5", 0.5), (10, "A5", 1), (11, "G5", 1),
         (12, "F5", 0.5), (12.5, "E5", 0.5), (13, "D5", 0.5), (13.5, "B4", 0.5), (14, "C5", 2)]
    song = render_song(112, 8, chords, melody_from([a, b]), swing=0.1, drums=True)
    write_wav("music_level", song, loop=True, peak=0.7)


# ---------------------------------------------------------------- trilhas por mundo
# Instrumentos extras (todos sintetizados) para dar cara própria a cada mundo.
def flute(freq, dur):
    t = t_axis(dur)
    n = len(t)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.25, 0, 1)
    ph = 2 * np.pi * freq * np.cumsum(vib) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = lowpass(noise(n), 2500) * 0.08 * env_exp(n, 0.08)
    return (x + breath) * env_adsr(n, 0.045, 0.08, 0.8, 0.08)


def ks_pluck(freq, dur, bright=0.5):
    """Karplus-Strong: violão/harpa."""
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    y = np.zeros(n + period + 1)
    y[: period + 1] = lowpass(noise(period + 1), 1500 + 6000 * bright)
    k = period + 1
    while k < len(y):
        e = min(len(y), k + period)
        y[k:e] = 0.5 * (y[k - period:e - period] + y[k - period - 1:e - period - 1]) * 0.996
        k = e
    return y[:n] * env_adsr(n, 0.001, 0.01, 1.0, 0.05)


def steel(freq, dur):
    t = t_axis(dur)
    n = len(t)
    f = freq * (1 + 0.004 * env_exp(n, 0.03))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = (np.sin(ph) + 0.6 * np.sin(2 * ph) * env_exp(n, 0.25) + 0.35 * np.sin(3.01 * ph) * env_exp(n, 0.12)
         + 0.15 * np.sin(4.2 * ph) * env_exp(n, 0.05))
    return x * env_exp(n, 0.45) * env_adsr(n, 0.003, 0.02, 1.0, 0.04)


def music_box(freq, dur):
    return bell(freq, max(dur, 0.6), 1.3) * 0.9


def glock(freq, dur):
    t = t_axis(max(dur, 0.5))
    n = len(t)
    x = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 3.0 * t) * env_exp(n, 0.05)
    return x * env_exp(n, 0.3) * env_adsr(n, 0.001, 0.01, 1.0, 0.03)


def chip(freq, dur):
    """Quadrada macia (chefão divertido, nada assustador)."""
    t = t_axis(dur)
    n = len(t)
    x = np.sign(np.sin(2 * np.pi * freq * t)) * 0.5 + 0.5 * np.sin(2 * np.pi * freq * t)
    return lowpass(x, 3200) * env_adsr(n, 0.005, 0.05, 0.6, 0.05)


def pad(freq, dur):
    t = t_axis(dur)
    n = len(t)
    x = sum(saw(2 * np.pi * freq * d * t) for d in (0.996, 1.0, 1.005)) / 3
    return lowpass(x, 900) * env_adsr(n, min(0.5, dur * 0.3), 0.2, 0.8, min(0.6, dur * 0.3))


def woodblock(freq=900, dur=0.07):
    n = int(SR * dur)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * freq * t) * 0.8 + highpass(noise(n), 2000) * 0.3) * env_exp(n, 0.015)


def sleigh(dur=0.12):
    n = int(SR * dur)
    x = np.zeros(n)
    for k in range(4):
        st = int(k * n / 6)
        b = highpass(noise(n - st), 6000) * env_exp(n - st, 0.02)
        x[st:] += b
    return x * 0.5


def bubble(dur=0.12, f0=300, f1=900):
    n = int(SR * dur)
    return np.sin(sweep_phase(f0, f1, n, 0.6)) * env_exp(n, 0.04) * env_adsr(n, 0.004, 0.01, 1.0, 0.02)


def chirp(dur=0.18):
    n = int(SR * dur)
    t = np.arange(n) / SR
    gate = (np.sin(2 * np.pi * 38 * t) > 0.2).astype(float)
    return np.sin(2 * np.pi * 4300 * t) * gate * env_adsr(n, 0.01, 0.02, 0.8, 0.04) * 0.25


def clap(dur=0.12):
    n = int(SR * dur)
    x = highpass(noise(n), 1500)
    e = np.zeros(n)
    for k in range(3):
        st = int(k * 0.01 * SR)
        e[st:] += env_exp(n - st, 0.012 if k < 2 else 0.04)
    return x * e * 0.6


def phrase(spec, scale, octave):
    """Notação compacta: "5:1 6:.5 3, 8 -:2"  grau[:duração]; ',' oitava abaixo, "'" acima, '-' pausa.
    Graus acima de 7 sobem de oitava (8 = tônica uma oitava acima)."""
    out, b = [], 0.0
    for tok in spec.replace("|", " ").split():
        deg, _, dur = tok.partition(":")
        d = float(dur) if dur else 1.0
        if deg != "-":
            shift = deg.count("'") - deg.count(",")
            k = int(deg.strip("',")) - 1
            name = scale[k % len(scale)]
            out.append((b, f"{name}{octave + k // len(scale) + shift}", d))
        b += d
    assert abs(b - 16) < 1e-6, (spec, b)
    return out


def render_track(bpm, chords, phrases, scale, octave, lead, lead_gain=0.5, accomp="bell", drums="soft",
                 swing=0.0, extra=None):
    """16 compassos no formato A B A C (cada frase = 4 compassos)."""
    beat = 60.0 / bpm
    order = [phrases[0], phrases[1], phrases[0], phrases[2]]
    bars = 16
    total = bars * 4 * beat
    buf = np.zeros(int(total * SR) + 3 * SR)

    def at(b):
        if abs(b % 1.0 - 0.5) < 1e-6:
            b += swing * 0.5
        return int(b * beat * SR)

    for bar in range(bars):
        root, third, fifth = chords[bar % len(chords)]
        base = bar * 4
        mix_at(buf, pluck_bass(note(root), beat * 0.9) * 0.55, at(base))
        mix_at(buf, pluck_bass(note(root), beat * 0.9) * 0.42, at(base + 2))
        mix_at(buf, pluck_bass(note(fifth), beat * 0.5) * 0.3, at(base + 3.5))
        if accomp == "bell":
            for b in (0.5, 1.5, 2.5, 3.5):
                for nm in (third, fifth):
                    mix_at(buf, bell(note(nm), beat * 0.6, 0.2) * 0.10, at(base + b))
        elif accomp == "skank":
            for b in (0.5, 1.5, 2.5, 3.5):
                for nm in (third, fifth):
                    mix_at(buf, ks_pluck(note(nm), beat * 0.4, 0.3) * 0.16, at(base + b))
        elif accomp == "harp":
            arp = [root, third, fifth, third]
            for i, b in enumerate(np.arange(0, 4, 0.5)):
                nm = arp[i % 4]
                f = note(nm) * (2 if nm == root else 1)
                mix_at(buf, ks_pluck(f, beat * 0.9, 0.6) * 0.14, at(base + b))
        elif accomp == "pad":
            for nm in (third, fifth):
                mix_at(buf, pad(note(nm), beat * 4.2) * 0.16, at(base))
            for i, b in enumerate((0, 1, 2, 3)):
                nm = (root, third, fifth, third)[i]
                mix_at(buf, bell(note(nm) * 2, beat * 1.2, 0.4) * 0.07, at(base + b + 0.5))
        if drums == "soft":
            mix_at(buf, soft_kick() * 0.5, at(base))
            mix_at(buf, soft_kick() * 0.35, at(base + 2))
            for b in np.arange(0, 4, 0.5):
                mix_at(buf, hat() * (0.16 if b % 1 else 0.09), at(base + b))
        elif drums == "brush":
            mix_at(buf, soft_kick() * 0.35, at(base))
            for b in (1, 3):
                mix_at(buf, shaker() * 0.3, at(base + b))
            for b in (0.5, 1.5, 2.5, 3.5):
                mix_at(buf, shaker() * 0.14, at(base + b))
        elif drums == "trot":
            mix_at(buf, soft_kick() * 0.4, at(base))
            mix_at(buf, soft_kick() * 0.3, at(base + 2))
            for b in (0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5):
                mix_at(buf, woodblock(1100 if b % 1 else 800) * (0.12 if b % 1 else 0.2), at(base + b))
        elif drums == "calypso":
            for b in (0, 1.5, 2, 3):
                mix_at(buf, soft_kick() * 0.42, at(base + b))
            for b in (0, 0.75, 1.5, 2.5, 3) if bar % 2 == 0 else (0.5, 1, 2, 2.75, 3.5):
                mix_at(buf, woodblock(1500) * 0.16, at(base + b))
            for b in np.arange(0, 4, 0.5):
                mix_at(buf, shaker() * (0.18 if b % 1 else 0.1), at(base + b))
        elif drums == "jingle":
            mix_at(buf, soft_kick() * 0.45, at(base))
            mix_at(buf, soft_kick() * 0.32, at(base + 2))
            for b in np.arange(0, 4, 0.5):
                mix_at(buf, sleigh() * (0.28 if b % 1 else 0.14), at(base + b))
        elif drums == "lullaby":
            for b in (0, 2):
                mix_at(buf, shaker() * 0.16, at(base + b + 1))
        elif drums == "sea":
            mix_at(buf, soft_kick() * 0.28, at(base))
        elif drums == "march":
            for b in range(4):
                mix_at(buf, soft_kick() * (0.55 if b % 2 == 0 else 0.4), at(base + b))
            for b in (1, 3):
                mix_at(buf, clap() * 0.35, at(base + b))
            for b in np.arange(0, 4, 0.5):
                mix_at(buf, hat() * 0.14, at(base + b))
        if extra:
            extra(buf, at, base, bar)

    for i, ph in enumerate(order):
        for (b, nm, d) in phrase(ph, scale, octave):
            mix_at(buf, lead(note(nm), max(0.2, d * beat * 1.15)) * lead_gain, at(i * 16 + b))

    loop_len = int(total * SR)
    tail = buf[loop_len:]
    out = buf[:loop_len].copy()
    out[: len(tail)] += tail
    return out


def even_loudness(x, target_rms=0.088):
    """Todas as trilhas de mundo com o mesmo volume médio da música das fases (picos suavizados)."""
    x = np.asarray(x, dtype=np.float64)
    x = x * (target_rms / np.sqrt(np.mean(x ** 2)))
    return np.tanh(x / 0.9) * 0.9


def world_music():
    # Mundo 2 — Floresta: flauta e harpa, ré dórico
    song = render_track(
        100, [("D3", "F4", "A4"), ("C3", "E4", "G4"), ("G2", "B3", "D4"), ("D3", "F4", "A4")],
        ["5:1 6:.5 5:.5 3:1 1:1 | 2:1.5 3:.5 4:1 3:1 | 5:1 7:.5 6:.5 5:1 3:1 | 2:3 -:1",
         "8:1 7:1 6:1 5:1 | 4:1.5 5:.5 6:2 | 5:1 4:1 3:1 2:1 | 1:2 5,:1 7,:1",
         "5:1 6:.5 5:.5 3:1 1:1 | 2:1 3:1 4:1 5:1 | 6:1.5 5:.5 4:1 2:1 | 1:4"],
        ["D", "E", "F", "G", "A", "B", "C"], 5, flute, 0.5, accomp="harp", drums="brush", swing=0.1)
    write_wav("music_forest", even_loudness(song), loop=True, peak=None)

    # Mundo 3 — Vale das Formigas: violão de faroeste e "cavalgada" de blocos de madeira
    song = render_track(
        120, [("A2", "C#4", "E4"), ("G2", "B3", "D4"), ("D3", "F#4", "A4"), ("A2", "C#4", "E4")],
        ["1:.5 3:.5 5:1 5:.5 6:.5 5:1 | 4:.5 3:.5 2:1 1:2 | 7,:.5 1:.5 2:1 3:.5 2:.5 1:1 | 5,:3 -:1",
         "5:1 8:1 7:.5 6:.5 5:1 | 6:.5 5:.5 4:1 3:2 | 4:1 6:1 5:.5 4:.5 3:1 | 2:2 5,:2",
         "1:.5 3:.5 5:1 5:.5 6:.5 5:1 | 8:1 7:.5 6:.5 5:2 | 4:.5 3:.5 2:.5 3:.5 2:1 7,:1 | 1:4"],
        ["A", "B", "C#", "D", "E", "F#", "G"], 4, lambda f, d: ks_pluck(f, d + 0.3, 0.7), 0.75,
        accomp="bell", drums="trot", swing=0.3)
    write_wav("music_valley", even_loudness(song), loop=True, peak=None)

    # Mundo 4 — Lagoa: marimba e bolhinhas
    def pond_extra(buf, at, base, bar):
        for b in (1.5, 3.25):
            f0 = 260 + 60 * ((bar * 3 + int(b)) % 5)
            mix_at(buf, bubble(0.12, f0, f0 * 2.6) * 0.18, at(base + b))
    song = render_track(
        96, [("F2", "A3", "C4"), ("D3", "F4", "A4"), ("A#2", "D4", "F4"), ("C3", "E4", "G4")],
        ["3:1 5:1 6:.5 5:.5 3:1 | 2:1 3:.5 2:.5 1:2 | 4:1 6:1 8:.5 7:.5 6:1 | 5:4",
         "8:.5 7:.5 6:1 5:1 3:1 | 4:.5 5:.5 6:1 5:2 | 3:.5 4:.5 5:1 6:1 4:1 | 2:2 5:2",
         "3:1 5:1 6:.5 5:.5 3:1 | 2:1 3:.5 2:.5 1:2 | 6,:1 1:1 2:1 7,:1 | 1:4"],
        ["F", "G", "A", "A#", "C", "D", "E"], 5, marimba, 0.6, accomp="bell", drums="soft", swing=0.12,
        extra=pond_extra)
    write_wav("music_pond", even_loudness(song), loop=True, peak=None)

    # Mundo 5 — Acampamento: caixinha de música e grilos (canção de ninar)
    def camp_extra(buf, at, base, bar):
        if bar % 2 == 0:
            mix_at(buf, chirp() * 0.5, at(base + 0.25))
            mix_at(buf, chirp() * 0.4, at(base + 0.75))
    song = render_track(
        84, [("G2", "B3", "D4"), ("E3", "G4", "B4"), ("C3", "E4", "G4"), ("D3", "F#4", "A4")],
        ["5:1.5 6:.5 5:1 3:1 | 5:1.5 6:.5 5:2 | 8:1 7:1 6:1 5:1 | 4:2 2:2",
         "3:1 4:1 5:2 | 6:1 5:1 3:2 | 2:1 3:1 4:1 6:1 | 5:4",
         "5:1.5 6:.5 5:1 3:1 | 5:1.5 6:.5 5:2 | 8:1.5 7:.5 6:1 4:1 | 1:4"],
        ["G", "A", "B", "C", "D", "E", "F#"], 5, music_box, 0.55, accomp="harp", drums="lullaby",
        extra=camp_extra)
    write_wav("music_camp", even_loudness(song), loop=True, peak=None)

    # Mundo 6 — Montanha: glockenspiel e guizos de trenó, mi menor
    song = render_track(
        108, [("E3", "G4", "B4"), ("C3", "E4", "G4"), ("G2", "B3", "D4"), ("D3", "F#4", "A4")],
        ["1:.5 3:.5 5:1 4:.5 3:.5 2:1 | 3:1 5:1 8:2 | 7:.5 8:.5 7:.5 5:.5 4:1 3:1 | 2:3 -:1",
         "5:1 6:1 7:1 8:1 | 9:1.5 8:.5 7:2 | 6:1 5:1 4:.5 3:.5 2:1 | 3:2 5,:2",
         "1:.5 3:.5 5:1 4:.5 3:.5 2:1 | 3:1 5:1 8:2 | 7:1 5:1 2:1 7,:1 | 1:4"],
        ["E", "F#", "G", "A", "B", "C", "D"], 5, glock, 0.6, accomp="bell", drums="jingle")
    write_wav("music_mountain", even_loudness(song), loop=True, peak=None)

    # Mundo 7 — Praia: steel drum e calipso
    song = render_track(
        116, [("C3", "E4", "G4"), ("F2", "A3", "C4"), ("G2", "B3", "D4"), ("C3", "E4", "G4")],
        ["5:.5 5:.5 6:.5 5:.5 3:1 1:1 | 2:.5 3:.5 4:1 3:.5 2:.5 1:1 | 5:.5 5:.5 6:.5 8:.5 7:1 5:1 | 6:1 5:1 3:2",
         "8:1 7:.5 6:.5 5:1 3:1 | 4:.5 4:.5 6:1 5:2 | 3:.5 4:.5 5:1 4:.5 3:.5 2:1 | 1:2 5,:1 7,:1",
         "5:.5 5:.5 6:.5 5:.5 3:1 1:1 | 2:.5 3:.5 4:1 3:.5 2:.5 1:1 | 6:.5 6:.5 5:.5 4:.5 3:1 2:1 | 1:4"],
        ["C", "D", "E", "F", "G", "A", "B"], 5, steel, 0.55, accomp="skank", drums="calypso")
    write_wav("music_beach", even_loudness(song), loop=True, peak=None)

    # Mundo 8 — Fundo do Mar: colchão de sintetizador, sininhos e bolhas, mi bemol
    def sea_extra(buf, at, base, bar):
        for k in range(3):
            f0 = 200 + 90 * ((bar * 7 + k * 3) % 6)
            mix_at(buf, bubble(0.16, f0, f0 * 3.0) * 0.12, at(base + 0.6 + k * 1.3))
    song = render_track(
        80, [("D#3", "G4", "A#4"), ("C3", "D#4", "G4"), ("G#2", "C4", "D#4"), ("A#2", "D4", "F4")],
        ["5:2 6:1 5:1 | 3:3 2:1 | 1:1 2:1 3:1 5:1 | 2:4",
         "8:1.5 7:.5 6:2 | 5:1 6:1 3:2 | 4:1 5:1 6:1 7:1 | 5:4",
         "5:2 6:1 5:1 | 3:3 2:1 | 6,:1 7,:1 1:1 2:1 | 1:4"],
        ["D#", "F", "G", "G#", "A#", "C", "D"], 5, lambda f, d: bell(f, d + 0.4, 0.5), 0.5, accomp="pad",
        drums="sea", extra=sea_extra)
    write_wav("music_sea", even_loudness(song), loop=True, peak=None)

    # Chefões — animada e com "marcha", lá menor harmônico (divertida, não assustadora)
    song = render_track(
        132, [("A2", "C4", "E4"), ("F2", "A3", "C4"), ("E2", "G#3", "B3"), ("A2", "C4", "E4")],
        ["1:.5 1:.5 3:.5 5:.5 8:1 7:1 | 6:.5 5:.5 4:.5 3:.5 2:2 | 7,:.5 7,:.5 2:.5 4:.5 7:1 6:1 | 5:2 3:1 7,:1",
         "6:1 5:.5 6:.5 8:1 6:1 | 5:1 4:.5 3:.5 2:2 | 3:.5 4:.5 5:.5 6:.5 7:1 9:1 | 8:2 5:2",
         "1:.5 1:.5 3:.5 5:.5 8:1 7:1 | 6:.5 5:.5 4:.5 3:.5 2:2 | 4:.5 3:.5 2:.5 7,:.5 5,:1 7,:1 | 1:4"],
        ["A", "B", "C", "D", "E", "F", "G#"], 5, chip, 0.42, accomp="skank", drums="march")
    write_wav("music_boss", even_loudness(song), loop=True, peak=None)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("Efeitos:")
    sfx_all()
    print("Músicas:")
    music_all()
    world_music()
