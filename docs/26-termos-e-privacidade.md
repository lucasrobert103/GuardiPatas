# 26 — Termos de Uso, Política de Privacidade (LGPD) e Google Play

O jogo agora tem uma parte completa de **Termos e privacidade**, com a **RetroNexa** identificada como desenvolvedora e controladora dos dados. Ela tem quatro documentos em português, inglês e espanhol, e um aviso de aceite.

## O que o jogador vê

| Onde | O que aparece |
|---|---|
| **Primeira abertura** (tela inicial) | Cartão "Boas-vindas ao GuardiPatas!" com um resumo de privacidade e o texto **"Ao continuar e usar o jogo, você concorda com os Termos de Uso e a Política de Privacidade da RetroNexa"**. Também orienta: "Se você tem menos de 18 anos, leia com um adulto responsável". Os botões são **Termos de Uso**, **Privacidade** e **Concordar e continuar**. O menu só fica livre depois de concordar; ler os documentos e voltar mantém o aviso. |
| **Termos atualizados** | Se a versão dos termos mudar (`VERSION` em `tools/make_legal.py`), o mesmo cartão volta com o título "Atualizamos os termos". |
| **Ajustes > Termos e privacidade** | Aviso "Ao usar o GuardiPatas, você concorda…", botões para os quatro documentos e a versão aceita com a data do aceite. |
| **Ajustes > Seus dados** | Resumo de privacidade (sem dados pessoais, sem anúncios, nada compartilhado) e **Apagar progresso**. |
| **Tela Termos e privacidade** | Quatro abas, texto rolável por arraste, rodapé com data, versão, RetroNexa, site e e-mail. |

### Os quatro documentos

1. **Termos de Uso:**
   - aceitação ao baixar, instalar ou usar;
   - uso por menores com um responsável;
   - licença pessoal e não comercial, e o que é proibido;
   - propriedade intelectual da RetroNexa;
   - fases e fotos que ficam só no aparelho;
   - moedas sem valor em dinheiro;
   - compras somente pelo Google Play, com a barreira para responsáveis, os reembolsos pelo Google Play e o CDC preservado;
   - sem anúncios e sem chat;
   - atualizações, uso saudável e limites de responsabilidade dentro do CDC;
   - mudanças com aviso no jogo;
   - lei brasileira e foro do consumidor.
2. **Política de Privacidade (LGPD):**
   - controladora RetroNexa e canal do encarregado;
   - o que fica salvo no aparelho e o que não coletamos;
   - permissão de vibração;
   - compras pelo Google Play: o que a RetroNexa receberia, com bases legais (art. 7º, II e V) e retenção;
   - crianças (art. 14, Famílias do Google Play, COPPA);
   - compartilhamento e transferência internacional;
   - segurança, com o backup automático desligado;
   - retenção e exclusão;
   - direitos do art. 18, com prazo de 15 dias e a ANPD;
   - mudanças na política.
3. **Seus direitos (LGPD):**
   - o quadro ao vivo **"Guardado neste aparelho agora"** (fases, moedas, itens, conquistas, fotos, fases do editor e versão aceita);
   - como confirmar, corrigir, eliminar e revogar;
   - um atalho que leva direto ao botão **Apagar progresso**.
4. **Para pais e responsáveis:**
   - o que o jogo nunca faz;
   - compras, a barreira para responsáveis e o Family Link;
   - conforto e acessibilidade;
   - tempo de tela.

## Fonte única dos textos

`tools/make_legal.py` guarda todos os textos nos três idiomas e gera:

| Arquivo | Uso |
|---|---|
| `data/legal.json` | Lido pelo jogo (`src/core/legal.gd`, `src/ui/legal_screen.gd`). Entra no APK pelo filtro `data/*.json`. |
| `docs/termos.md`, `docs/privacidade.md` | Versão em Markdown, com os três idiomas. |
| `docs/site/termos.html`, `privacidade.html`, `direitos.html`, `responsaveis.html` | Páginas prontas para publicar, com tema claro e escuro e largura de celular. |

O CI roda o gerador e falha se os arquivos gerados estiverem desatualizados. Para mudar um texto, edite o script e rode `python3 tools/make_legal.py`. Quando a mudança alterar direitos ou obrigações, aumente `VERSION` para o aviso aparecer de novo.

O aceite fica em `save.json`, no campo `"legal": {"accepted": "1.0", "date": "AAAA-MM-DD"}`. **Apagar progresso** mantém esse registro, assim como mantém os ajustes. Valores adulterados viram texto e não valem como aceite.

## Antes de publicar: o que a RetroNexa precisa confirmar

- [ ] **E-mail de contato:** os textos usam `contato@retronexa.com.br`. Crie e monitore essa caixa, ou troque `EMAIL` em `tools/make_legal.py` e rode o gerador. A LGPD exige um canal de atendimento, e a Play Console exige o mesmo e-mail de suporte.
- [ ] **Publicar as páginas:** suba `docs/site/privacidade.html` em `https://retronexa.com.br/guardipatas/privacidade` e `termos.html` em `/guardipatas/termos` (ou ajuste `PAGES`). Cole o link da privacidade na Play Console. Ele precisa ser público, estável, sem login e sem PDF.
- [ ] **Identificação legal:** se a RetroNexa tiver CNPJ e razão social, vale incluir na seção "Quem somos" dos dois documentos.
- [ ] **Revisão jurídica:** os textos foram escritos para refletir com fidelidade o que o código faz. Eles não substituem a revisão de um advogado, principalmente antes de ativar compras reais.

## Respostas na Play Console (versão atual: sem internet e sem compras reais)

| Formulário | Resposta coerente com o código e com a política |
|---|---|
| Política de privacidade | URL da página publicada (acima). |
| Anúncios | **Não**, o app não contém anúncios. |
| Acesso ao app | Todo o conteúdo fica disponível sem login. |
| Público-alvo | Selecione as faixas etárias reais. Se incluir menores de 13 anos, o app entra no programa **Famílias** e segue as regras dele: sem anúncios, sem coleta de dados, barreira para responsáveis antes de compras e conteúdo adequado. |
| Segurança dos dados | **Nenhum dado coletado** e **nenhum dado compartilhado**. Os dados ficam só no aparelho e não são transmitidos, por isso não precisam ser declarados. O app não oferece contas, então não há exclusão de conta a declarar. |
| Permissões | Apenas `VIBRATE`. `INTERNET` está desligada no preset. |
| Classificação (IARC) | Responder ao questionário com honestidade. O doc 15 descreve o conteúdo. |
| Apps de saúde, financeiros ou governamentais | Não se aplica. |

## Quando ativar compras com dinheiro real

A política já descreve esse caso, mas antes da versão com compras reais é preciso:

1. Ligar a permissão `INTERNET` no preset, porque a verificação no servidor precisa dela.
2. Atualizar a **Segurança dos dados** para declarar "Informações financeiras > Histórico de compras" como coletado, **não compartilhado**, para "Funcionalidade do app" e "Prevenção de fraudes". Confirme na Console como classificar o token da Billing.
3. Publicar a política com o prazo de retenção definido pelo backend.
4. Aumentar `VERSION` para que todos vejam o aviso de termos atualizados.

Os demais requisitos estão em [16 — publicação, segurança e compras](16-publicacao-seguranca-e-compras.md).

## Testes

`tests/legal_test.gd` faz 316 verificações:

- todos os documentos, nos três idiomas;
- citações obrigatórias (LGPD, art. 14 e 18, ANPD, COPPA, Google Play, CDC);
- o aviso na primeira abertura, que só some depois de concordar;
- o aviso de termos atualizados;
- o registro que sobrevive ao "Apagar progresso";
- as quatro abas dentro da tela e o texto acima da faixa de gestos;
- o atalho para apagar progresso;
- os botões nos Ajustes.

O `flow_test` percorre o caminho real: aviso, Privacidade, voltar, Concordar, Ajustes, Termos de Uso, Seus direitos e voltar.
