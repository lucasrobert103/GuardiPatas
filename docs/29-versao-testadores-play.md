# 29 — Versão para testadores na Google Play

## O que muda nesta versão

- **Tudo grátis, nenhuma cobrança:** a loja mostra "VERSÃO DE TESTE · Tudo grátis". Cada produto (bichinhos mágicos, pacotes, moedas, dicas, efeitos) tem o botão **Pegar grátis** e é liberado na hora, sem a Área dos responsáveis, porque não envolve dinheiro.
- **Sem Google Play Billing:** o plugin de pagamento não entra no pacote e o app não pede a permissão de compra. Na Play Console, responda **"Não"** para compras no app nesta versão.
- **Como ligar as compras depois:** tudo fica em `src/autoload/store.gd`:
  - `const FREE_FOR_TESTERS := true` liga a versão de testes. Mude para `false` quando a integração de pagamento estiver pronta.
  - O bloco **"INTEGRAÇÃO DE PAGAMENTO"** em `_ready()` conecta o `PlayBilling`. Ele já existe e só fica desligado enquanto a versão grátis estiver ativa.
  - Para a versão paga ainda falta: plugin GodotGooglePlayBilling, servidor de verificação (`guardipatas/billing/verify_url`) e produtos criados na Play Console. Veja o [doc 16](16-publicacao-seguranca-e-compras.md).
- **Builds de debug** (instalados pelo `atualizar.sh`) continuam com a compra **simulada** dos testes automáticos. A versão grátis vale para o build de **release** que vai para a loja.

## Gerar o arquivo para a Play Store

```bash
cd ~/Desktop/frontend/GuardiPatas
git fetch origin ccr-69427eab-1v26vu && git reset --hard FETCH_HEAD
bash tools/build_play.sh
```

O script:
- **Ferramentas:** usa o mesmo Godot, Android SDK e Java (17 a 21) do `atualizar.sh`.
- **Chave de upload:** na primeira vez cria `~/.guardipatas/guardipatas-upload.jks` e pede uma senha. **Faça backup do arquivo e guarde a senha.** Toda atualização do jogo na loja precisa da mesma chave. Ela nunca vai para o repositório.
- **Número da versão:** gera o `versionCode` sozinho no formato AAMMDDHH (por exemplo 26110818), que sempre cresce. Basta rodar de novo a cada envio. Para escolher o número: `VERSION_CODE=123 bash tools/build_play.sh`.
- **Arquivo final:** gera pelo Gradle o **AAB assinado** em `export/GuardiPatas-1.1.0-<código>.aab`. É esse arquivo que você envia para a Play Console.

## Antes do primeiro envio (não dá para mudar depois)

- **ID do pacote:** hoje é `br.com.guardipatas` (em `export_presets.cfg`, `package/unique_name`). Depois do primeiro envio ele **nunca mais muda**, nem se o nome do jogo mudar.
  - O usual é usar o domínio da empresa ao contrário, por exemplo `br.com.retronexa.guardipatas`.
  - Se for trocar, troque antes do primeiro envio. Mude também `PACKAGE` em `tools/atualizar.sh`.
- **Play App Signing:** aceite o "Play App Signing" na criação do app. O Google guarda a chave final e você só usa a chave de upload.

## Na Play Console (versão de testadores)

1. **Criar o app:** Jogo, Gratuito. O nome pode ser trocado depois.
2. **Configuração do app** (o painel lista o que falta):
   - **Política de privacidade:** URL pública da `docs/site/privacidade.html` (veja o doc 26).
   - **Acesso ao app:** tudo disponível sem login.
   - **Anúncios:** **Não**.
   - **Classificação de conteúdo:** questionário IARC. Não há violência real, linguagem, apostas, chat nem compartilhamento de localização.
   - **Público-alvo:** escolha as faixas etárias reais. Se incluir menores de 13, siga as regras do programa Famílias, que o jogo já atende: sem anúncios, sem coleta de dados, notificações locais e barreira para responsáveis antes de compras reais.
   - **Segurança dos dados:** **nenhum dado coletado e nenhum dado compartilhado**. As notificações são criadas no próprio aparelho.
   - **Compras no app** (nesta versão): **Não**.
3. **Testar e lançar > Teste interno:**
   - crie uma lista de testadores com os e-mails das contas Google;
   - em **Criar nova versão**, envie o `.aab` e escreva as notas da versão;
   - toque em **Lançar**;
   - mande aos testadores o **link de participação**. O teste interno libera em minutos, sem revisão completa, para até 100 pessoas.
4. **Teste fechado:** contas de desenvolvedor pessoais novas precisam de um teste fechado com testadores (a regra conhecida é de 12 pessoas por 14 dias) antes de liberar a produção. Confira a exigência atual na Console.

## Notas da versão sugeridas (pt-BR)

> Versão de teste do GuardiPatas! Desenhe abrigos para proteger os bichinhos dos insetos em 123 fases, no Modo Infinito e no Desafio do Dia. Cuide da turma na Casinha, pinte no Ateliê e crie suas próprias fases. Nesta versão de teste tudo na loja é grátis. Conte pra gente o que achou!
