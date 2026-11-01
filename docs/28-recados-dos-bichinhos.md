# 28 — Recados dos bichinhos (notificações locais)

Os bichinhos mandam notificações pedindo ajuda e lembrando do Desafio do Dia, da Casinha, do progresso, do Modo Infinito e do Ateliê.

Tudo é **local**: os recados são montados e agendados no próprio celular, sem internet, sem servidor e sem coletar dados.

## Como funciona

- **Frequência:** em Ajustes > *Recados dos bichinhos* dá para escolher *Desligados*, *1 por dia*, **3 por dia** (padrão) ou *5 por dia*.
- **Horário:** só entre **9h30 e 20h**, nunca de madrugada nem à noite. Os horários são sorteados dentro de faixas do dia, para não chegarem todos juntos.
- **Respeita quem acabou de jogar:** o primeiro recado só sai **2 horas** depois que o jogo foi fechado.
- **Agenda e cancelamento:** a cada vez que o jogo é minimizado ou fechado, os recados antigos são cancelados e os próximos **3 dias** são agendados de novo, com o progresso mais recente. Quem joga todo dia recebe textos sempre atualizados. Quem para de jogar recebe no máximo 3 dias de recados, e eles param sozinhos.
- **Textos:** há 15 a 17 recados diferentes. Recados do mesmo dia não se repetem. Eles chamam os bichinhos que o jogador já conhece pelo nome. Exemplos:
  - "Capitu precisa de ajuda! Tem abelhas rondando a toca. Vem desenhar um abrigo?"
  - "Próxima: Fase 37. Você já venceu 36 fases…"
  - "Pingo está com fome. Leva um petisco na Casinha?"
  - "Recorde: 12 fases. Será que você passa do seu recorde no Modo Infinito?"
- **O que os recados nunca fazem:** propaganda, convite para comprar, falar da loja ou de moedas.
- **Idiomas:** português, inglês e espanhol.
- **Permissão:**
  - depois de vencer 3 fases, a tela inicial convida uma única vez: "Os bichinhos podem te chamar?";
  - só depois disso o Android pede a permissão de notificações;
  - nos Ajustes também existe o botão *Permitir notificações*.

## Por que não 15 por dia

Foi pedido algo como 15 notificações por dia. O jogo oferece no máximo 5, por quatro motivos:

- **Desinstalação:** muitas notificações são a principal causa de alguém bloquear as notificações ou desinstalar o app. A partir daí não chega mais nenhuma.
- **Público infantil:** o jogo é para crianças (programa Famílias do Google Play, LGPD art. 14). Empurrar crianças a voltar a cada hora é considerado "design manipulativo" e pode atrapalhar a aprovação.
- **Limites do Android:** o Android agrupa e silencia apps que notificam demais.
- **Responsáveis:** os pais e responsáveis veem os recados e julgam o jogo por eles.

Se mesmo assim quiser mais, basta mudar `FREQUENCIES` em `src/autoload/reminders.gd` e o texto da política em `tools/make_legal.py`.

## Como os recados chegam no celular (sozinhos)

- **Nada é enviado por você:** não há servidor nem envio manual. O próprio jogo agenda os recados no Android com o plugin **Notification Scheduler** (versão 6.0, para Godot 4.7, licença MIT, https://github.com/godot-mobile-plugins/godot-notification-scheduler). Ele está em `addons/NotificationSchedulerPlugin`, aprovado pela RetroNexa.
- **Funcionamento sozinho:** o Android mostra cada recado na hora marcada, **mesmo com o jogo fechado**. Tocar no recado abre o jogo. Se o celular for reiniciado, o plugin reagenda os recados sozinho.
- **Atualização dos recados:** toda vez que o jogo é minimizado ou fechado, os recados são refeitos com o progresso atual para os próximos 3 dias.
- **Ícone:** uma patinha branca, em `assets/NotificationSchedulerPlugin/android/drawable-*/ic_default_notification.png`. A pasta tem `.gdignore`, então o Godot não a importa; o plugin copia o ícone para o APK.
- **Permissões removidas:** `addons/guardipatas_android` tira do APK as permissões que o plugin declara e o jogo não usa (`SCHEDULE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` e `WAKE_LOCK`). A Google Play restringe as duas primeiras. Sem alarme exato, o plugin usa alarmes inexatos, que podem atrasar alguns minutos, o que é ótimo para recados.
- **Build:** plugins Android só entram no **build Gradle**. O `tools/atualizar.sh` instala o Modelo de Build Android na primeira vez, junto com o export, e gera o APK pelo Gradle. Na primeira vez ele baixa o Gradle e as bibliotecas do Android, o que leva alguns minutos e exige internet e o Android Studio instalado.
- **Se o Gradle falhar:** o script gera o APK sem as notificações e avisa. O jogo funciona igual, e a seção dos Ajustes diz que o aparelho ainda não recebe recados.
- **Play Console:** na Segurança dos dados, nenhum dado é coletado, porque as notificações são locais. A permissão de notificações aparece no APK. A política de privacidade e o guia para responsáveis (versão 1.1 dos termos) já descrevem os recados.

## Testes

`tests/reminders_test.gd` faz 111 verificações:

- **Sem o plugin:** o jogo continua funcionando e nada é agendado.
- **Textos:**
  - mais de 14 recados completos, chamando os bichinhos pelo nome;
  - recados sobre ajuda, Desafio do Dia, Casinha, Ateliê e fases;
  - nenhum fala em compra, loja ou moedas;
  - versão em inglês.
- **Horários:** com 1, 3 e 5 por dia, a partir de 0h, 7h, 9h, 13h, 19h e 23h:
  - sempre entre 9h30 e 20h;
  - nunca nas 2 horas depois de jogar;
  - no máximo N por dia, nos próximos dias;
  - sem repetir texto no mesmo dia.
- **Ajustes:** 4 opções, e é possível desligar ou escolher 5 por dia.
