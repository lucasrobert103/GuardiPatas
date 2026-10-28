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
    x = normalize(np.asarray(x, dtype=np.float64), peak)
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


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("Efeitos:")
    sfx_all()
    print("Músicas:")
    music_all()
