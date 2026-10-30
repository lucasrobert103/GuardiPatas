# Publicação, segurança e loja de testes

Revisão em 30/10/2026. Branch `ccr-69427eab-1v26vu`.

**Parecer: ainda não elegível para publicar com compras reais.** O jogo pode ser preparado para testes internos; não há evidência de AAB assinado, instalação Android ou aprovação da Play Console. A revisão de código e os testes headless não equivalem a auditoria independente ou certificação de segurança.

## O que foi implementado

- Lojinha acessível pelo menu principal e Coleção, com descrição do conteúdo, preço **ilustrativo em BRL**, confirmação, cancelar e mensagem de resultado.
- 3 pacotes consumíveis: 300 / 900 / 2.000 moedas; kit único de 500 moedas + 5 dicas + Tiara da Lua + Cartola.
- Amora (gatinha), Bambu (panda) e Gotinha (lontra), cada um com arte e descrição próprias. São **companheiros da Casinha**, com carinho, petisco e acessórios; não são personagens selecionáveis nas 63 fases, nem alteram sua física. Aparecem também na Coleção.
- 6 novos acessórios desenhados: Tiara da Lua, Cartola Mágica, Chapéu Pirata, Fones Coloridos, Gravata Borboleta e Auréola Solar. Agora há 15 acessórios. Todos podem ser obtidos com moedas do jogo; campanha e editor continuam gratuitos.
- Sem assinaturas, anúncios, loot boxes, recompensas aleatórias, contagem regressiva de oferta, renovação automática ou venda de dados.

## Como testar as compras agora

Abra o projeto no **Godot 4.7.2** e use F5. No menu: **Lojinha · teste** → produto → peça a um responsável para responder a conta → **Pagar (simulação)**. O pagamento retorna sucesso e entrega o conteúdo imediatamente. **Não há cobrança, API financeira nem coleta de dados de cartão.** Os preços são placeholders de design, não propostas finais de preço.

A simulação depende de `OS.is_debug_build()` e é recusada quando há a feature `release`. Não existe argumento para habilitá-la em release. `--store-production` só pode desabilitar a simulação. No APK de debug também será teste; validar no aparelho antes de distribuir.

A loja usa `user://save-store-test.json` e `user://album-store-test/`, separados do progresso normal (`save.json` e `album/`). Reiniciar preserva o conteúdo de teste; apagar progresso apaga moedas, direitos de teste e fotos daquele modo. Desinstalar perde os dados locais. Não há restauração entre aparelhos. Não importar estes saves para produção.

A conta matemática é uma barreira de UX para responsáveis, **não autenticação nem comprovação de idade**. Confirmar adequação do fluxo ao público infantil antes de publicar. A autorização de compra real deverá ser do Google Play e das configurações da família.

### Testes automatizados

Use o executável 4.7.2, não o `godot` global 4.6.3 desta máquina. Exemplo (a partir da raiz do checkout):

```bash
GODOT=/workspace/.tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64
export XDG_CACHE_HOME=/workspace/.cache XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/guardipatas-store-tests
mkdir -p "$XDG_DATA_HOME"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . res://tests/check_scripts.tscn
"$GODOT" --headless --path . res://tests/store_test.tscn -- --test-io
"$GODOT" --headless --path . res://tests/store_test.tscn -- --store-production
"$GODOT" --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
"$GODOT" --headless --fixed-fps 60 --path . res://tests/flow_test.tscn
```

O teste com escrita exige `--test-io` e `XDG_DATA_HOME` terminando em `/guardipatas-store-tests` para não apagar progresso de desenvolvimento. Sem isso, informa que a etapa de persistência não foi executada. A falha de gravação é injetada e seu warning é esperado. Os testes preexistentes deixam recursos de áudio alocados ao encerrar: não confundir isso com ausência de falhas funcionais. Não foram feitos testes visuais ou em dispositivo Android nesta revisão.

## Resultado desta execução

- 71 scripts compilados sem erro.
- 405 verificações da suíte principal aprovadas; fluxo da interface: 40 verificações aprovadas.
- Loja: 52 verificações aprovadas, incluindo escrita/recarga, cancelamento, duplicação, resposta incorreta, corrupção básica de save e rollback após falha de gravação; mais 3 verificações aprovadas com simulação desabilitada.
- Smoke de 600 frames concluído sem erros de script. `git diff --check` passou.
- Permanecem avisos de objetos/recursos de áudio alocados ao encerrar os testes, também presentes antes da loja. Não é uma execução livre de avisos de limpeza.
- CI foi atualizado, mas sua execução remota não foi iniciada. Não foi gerado AAB/APK nem validado o export release real.

## Revisão de segurança

| Área | Evidência e resultado |
|---|---|
| Cobrança indevida de teste | Não há SDK financeiro, formulário de cartão ou requisição de compra; release não entrega conteúdo simulado. Testado também com modo de produção forçado em desktop debug; ainda falta executar export release real. |
| Duplicação | ID de pedido não pode repetir, produtos permanentes/kit não podem ser recomprados; consumíveis exigem novo pedido. Entrega e registro são gravados juntos. Falha de save reverte todo o estado em memória. |
| Confiança no cliente | JSON é modificável pelo dono do aparelho. IDs/recibos locais e a barreira de responsáveis **não impedem fraude em produção**. Não usar esse mecanismo como verificação de pagamento real. |
| Persistência | Escrita temporária + rename mantém o save anterior em caso de falha antes da troca. Limite de leitura de 4 MiB, checagem de tipos básicos, normalização de saldo, acessórios e elenco; isso não é validação completa dos dados do editor. |
| Fotos | Caminhos aceitos apenas dentro do diretório de álbum ativo; recusados `..` e outros arquivos. Apagar progresso agora também remove as fotos referenciadas daquele modo. Fotos são imagens do jogo, sem câmera/galeria. |
| Superfície externa | Não foram encontrados HTTPRequest, execução de shell ou abertura de URLs no código do jogo. Sem contas, chat, conteúdo remoto ou SDK de publicidade. A permissão Internet está desabilitada no preset atual. |
| Segredos e assinatura | Nenhum keystore/JKS/arquivo de credenciais encontrado entre os arquivos versionados pelos nomes convencionais. Isso não é varredura certificada de histórico nem prova de ausência de todos os segredos. Manter chaves fora do repositório e da aplicação. |
| Dependências/CI | Engine fixada em 4.7.2. O download local foi conferido com SHA-512 oficial; adicionada conferência equivalente ao download no CI. A fonte Inter acompanha licença. Ainda confirmar autoria/licenças de toda arte, sons e marca antes do envio. |
| Limites | Sem pentest de APK, inspeção de manifesto final, análise de bibliotecas nativas, teste de backup, testes de acessibilidade visual, bateria/performance ou aparelhos reais. Persistência offline continua adulterável. |

## Bloqueios antes de vender

1. **Google Play Billing:** bens digitais dentro do app distribuído pelo Play normalmente usam Play Billing; não integrar uma API genérica de cartão para contornar isso. Verificar eventuais programas/exceções aplicáveis com a conta/região, sem presumi-los. Usar plugin Godot compatível com a versão exigida da Billing Library; conferir manutenção e licença.
2. **Catálogo real:** criar os sete IDs no Play Console (ou mapear IDs definitivos), classificar moedas como consumíveis e pets/kit como direitos únicos. Os preços/moeda devem vir de `ProductDetails`, com localização. Não usar strings BRL como preço real.
3. **Backend confiável:** receber `purchaseToken`, verificar pacote/produto/estado no Google Play Developer API, conferir usuário e quantidade e persistir entrega idempotente. Não entregar compras `PENDING`, canceladas ou recusadas. Confirmar (`acknowledge`) ou consumir após entrega durável conforme o tipo. Tratar reembolso, revogação, eventos em tempo real, retries, reinstalação e restauração de não consumíveis. Nunca embutir credenciais da conta de serviço no app. Consumir moedas requer saldo/ledger confiável se houver prevenção de fraude.
4. **Sem misturar saves:** simulações nunca devem criar direitos reais. Definir conta/identidade e restauração antes de prometer recuperação de compras. O reset atual é apenas local; desenhar o reset/restauração real antes de habilitar Billing.
5. **Famílias:** selecionar faixas etárias honestamente, rever apelos de compra, barreira para responsáveis, divulgação de custos e configuração de aprovação da família. Não anunciar conformidade automaticamente. Não pressionar crianças a comprar.
6. **Privacidade/Data safety:** atualizar a política publicada e os formulários de acordo com o SDK e backend efetivamente integrados (tokens, histórico de compras, IDs, logs, retenção, exclusão e compartilhamento). A política offline atual não descreve um backend de compras. Prover URL pública estável, contato real e identificação do desenvolvedor.
7. **Loja e localização:** revisar os textos marcados como antigos em doc 15; remover promessas incompatíveis com compras. A nova lojinha está em português: concluir EN/ES e validar preços/textos grandes antes da distribuição nesses idiomas. Não publicar loja com botões de pagamento indisponíveis como se fossem funcionais.

## Bloqueios Android/Play Console

| Item | Situação |
|---|---|
| Identidade do pacote | `br.com.guardipatas` é um placeholder documentado. Confirmar domínio/identidade e app existente; não mudar depois de publicado. |
| Target/min SDK | Preset declara target 36 / min 24 e ARM32/ARM64. Confirmar requisitos vigentes na data do envio; configuração não prova o manifesto final. |
| Build | Faltam SDK Android, templates 4.7.2, build Gradle e validação do AAB assinado. JDK/SDK compatíveis precisam ser instalados e configurados para esse fluxo. |
| Bibliotecas nativas | Confirmar suporte a páginas de memória de **16 KiB** da engine e de todos os plugins no artefato final, além de ARM64. Testar instalação/dispositivo ou emulador apropriado; não inferir só pela versão. |
| Assinatura | Gerar e proteger upload key fora do repo; ativar Play App Signing. Nunca enviar senha/chave em chat, código ou logs. |
| Versionamento | Preset ainda `versionCode=1`, versão 0.3.0. Incrementar de acordo com versões já enviadas. |
| Testes | Rodar track interno, license testers para Billing, compra aprovada/recusada/pendente, cancelamento, perda de conexão, repetição de callback, reembolso, reinstalação, restauração, rotação, suspensão e aparelhos de entrada. |
| Acesso à produção | Conferir tipo/data de criação da conta e exigência de teste fechado. Para contas pessoais sujeitas à regra conhecida, 12 participantes por 14 dias; confirmar na Console, não foi verificado nesta sessão. |
| Formulários | Identidade/verificação do desenvolvedor, IARC, faixa etária/Famílias, declaração de anúncios, compras, Data safety, política de privacidade, e-mail de suporte e direitos do conteúdo precisam estar preenchidos e coerentes. A classificação é atribuída pelo formulário, não por este documento. |
| Assets | Conferir capturas representativas da versão nova, nome/descrições, ícones e destaque. Não prometer funcionalidades ainda simuladas. |

## Referências oficiais a conferir

O acesso às páginas abaixo foi recusado pelo proxy desta máquina (HTTP 403). São referências para verificação, **não consultas bem-sucedidas às regras atuais**. Datas e versões exigidas devem ser confirmadas na documentação e na Console antes do envio.

- Segurança de Billing: https://developer.android.com/google/play/billing/security
- Integração e ciclo de vida: https://developer.android.com/google/play/billing/integrate
- Política de pagamentos: https://support.google.com/googleplay/android-developer/answer/9858738
- Famílias: https://support.google.com/googleplay/android-developer/answer/9893335
- Target API: https://support.google.com/googleplay/android-developer/answer/11926878
- Teste fechado: https://support.google.com/googleplay/android-developer/answer/14151465
- Páginas de 16 KiB: https://developer.android.com/guide/practices/page-sizes

Nenhum app foi enviado à Play Console, nenhuma cobrança real foi feita e nenhum requisito externo foi marcado como concluído sem evidência.
