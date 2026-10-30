# Casinha: cuidar dos bichinhos

A Casinha agora funciona como um espaço de bichinhos virtuais, com arte própria do GuardiPatas. Não usa imagens, personagens ou código do Pou.

## Como brincar

1. Abra **Casinha** no menu. Escolha um amigo na lista ou toque nele. Os animais resgatados e companheiros adquiridos aparecem juntos. Antes de resgatar alguém, a Capitu já fica disponível.
2. **Comida:** escolha Refeição ou Frutinhas e toque no bichinho para oferecer. Petisco é um atalho para alimentar o amigo selecionado. Uma barriguinha cheia não recebe mais comida.
3. **Banho:** toque em Sabão e esfregue o bichinho com o dedo/mouse ou dê quatro toques. Ao chegar em 100% de espuma, toque em Enxaguar. A sujeira desaparece e há feedback de água e som. Sabão sozinho não completa o banho.
4. **Soneca:** apague a luz para descansar. O bichinho fecha os olhos e recupera energia enquanto a Casinha estiver aberta. Toque em Acordar para voltar a comer e brincar.
5. **Brincar:** toque na bola na sala ou em Jogar bola. O amigo corre para brincar, ganha carinho e gasta um pouco de energia. Se estiver cansado, ofereça uma soneca. Também é possível fazer carinho diretamente no bichinho.
6. **Roupas:** toque no nome do acessório para experimentar sem comprar. Vestir usa um item já adquirido; o botão de moedas compra e veste. Sem acessório tira a roupa. A prévia não dá direito ao item e desaparece ao trocar de seção/bichinho ou sair.
7. **Álbum** continua acessível no topo. Voltar retorna ao menu.

As quatro barras são **Barriguinha, Higiene, Energia e Carinho**, com texto numérico além da cor. Todos os cuidados básicos e alimentos são gratuitos e ilimitados. Só roupas custam moedas do jogo, com saldo e preço visíveis. Não há anúncios, cobrança real, remédios, morte, doença, perda de animais ou penalidade por deixar de jogar. Nenhum cuidado libera moeda para evitar uma rotina de farm.

## Progresso

- Necessidades e estado de sono são individuais, guardados em `care` no save ativo. Saves anteriores recebem os valores iniciais ao conhecer esse recurso.
- O tempo das necessidades só avança com a Casinha aberta; não usamos relógio do sistema, data de retorno ou redução de barras enquanto o jogo estiver fechado. Uma pausa longa de frame é limitada a dois segundos de simulação.
- Ações são salvas imediatamente. O avanço passivo é salvo a cada 15 segundos, ao sair e ao minimizar. Encerramento forçado pode perder até esse intervalo de avanço passivo.
- Falha de gravação reverte o cuidado ou compra de roupa e informa o erro. A troca de roupa também reverte se não puder ser gravada.
- A simulação de compras continua usando save separado. Apagar progresso limpa os cuidados do modo ativo.
- Roupas são visuais. Cuidados não afetam vitórias, atributos físicos, tinta ou dificuldade das fases.
- Bichinhos dormindo não comem nem brincam. Espuma parcial e rodadas da bola são efeitos de sessão; trocar de bichinho limpa a espuma, sem transferir banho a outro amigo.

## Acessibilidade e testes

Controles por toque ou mouse; banho também funciona só com toques. A Casinha respeita texto grande e reduz movimento de pulos, corações, chuva e nuvens. Há traduções dos novos controles e mensagens de cuidado em português, inglês e espanhol.

Teste dedicado (Godot 4.7.2, a partir da raiz):

```bash
export XDG_CACHE_HOME=/workspace/.cache XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/guardipatas-care-tests
mkdir -p "$XDG_DATA_HOME"
/workspace/.tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path . res://tests/pet_care_test.tscn -- --test-io
```

O diretório precisa terminar em `/guardipatas-care-tests` e o argumento `--test-io` precisa estar presente para executar a etapa de persistência. Isso evita apagar o progresso pessoal por acidente. Os testes exercitam cuidados individuais, limites, sono, alimentação por toque, espuma/esfregar/enxaguar, prévia sem débito, compra de roupa, persistência e falhas de gravação. O CI inclui esse teste.

A interface foi renderizada e inspecionada no desktop com OpenGL Compatibility/Mesa, incluindo banho, roupas e soneca com texto grande. Isso não substitui testes de toque e desempenho no Android. Permanecem avisos de recursos de áudio no encerramento, já observados antes deste recurso.

## Validação desta entrega

- 48 verificações de cuidados aprovadas, incluindo persistência, falha de gravação, localização EN/ES e limites de layout com texto grande.
- 405 verificações da campanha, 40 do fluxo da interface e 52 da loja aprovadas.
- 73 scripts compilados sem erros; `git diff --check` passou.
- Renderização desktop inspecionada para banho com espuma, prévia de roupas e sono com texto grande. Testes Android e execução remota do CI continuam pendentes.
