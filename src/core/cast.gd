class_name Cast
## Textos do elenco exibidos na Coleção (ficha completa em docs/05-personagens.md).

const ORDER := ["capi", "brasa", "pingo", "nino", "tuca", "lulu", "gelinho", "nuvem", "kiko", "tata", "pompom", "patinha", "fofa", "tito"]

const INFO := {
	"capi": {
		"species": "Capivara",
		"bio": "Capitu é a capivara mais tranquila do quintal. Usa uma laranjinha na cabeça como chapéu e acha que todo problema se resolve com um cochilo.",
		"trait": "Grandona e pesada: precisa de abrigos largos, mas não é empurrada fácil.",
	},
	"brasa": {
		"species": "Raposa",
		"bio": "Brasa é curiosa, rápida e fala pelos cotovelos. Coleciona pedrinhas brilhantes e jura que já domou uma vespa (ninguém acredita).",
		"trait": "Orelhas altas: o abrigo precisa ser mais alto que o normal.",
	},
	"pingo": {
		"species": "Ouriço",
		"bio": "Pingo é tímido e carrega sempre uma folhinha presa nos espinhos. Quando se assusta, vira uma bolinha... e rola!",
		"trait": "Redondo: rola em rampas. Prenda o Pingo com a linha antes que ele escorregue.",
	},
	"nino": {
		"species": "Esquilo",
		"bio": "Nino nunca larga sua bolota favorita. Mora no alto dos galhos e é leve como uma pluma.",
		"trait": "Levinho: uma linha caindo em cima pode derrubá-lo do galho.",
	},
	"tuca": {
		"species": "Tartaruga",
		"bio": "Tuca é a vovó da turma, com seu cachecol vermelho tricotado à mão. Lenta, sábia e sempre com uma história para contar.",
		"trait": "Casco firme: aguenta UMA picadinha sem problema.",
	},
	"lulu": {
		"species": "Axolote",
		"bio": "Lulu vive sorrindo no seu aquário. Ama bolhas, cantar debaixo d'água e fazer amizade com qualquer um — até com mosquitos (que não merecem).",
		"trait": "Vive na água: insetos que mergulham são levados embora.",
	},
	"gelinho": {
		"species": "Pinguim",
		"bio": "Gelinho desceu da montanha de barriga, escorregando, e nunca mais quis andar de outro jeito. Usa um cachecol azul que a Tuca tricotou.",
		"trait": "Escorregadio: quase não tem atrito — um empurrãozinho e lá vai ele.",
	},
	"nuvem": {
		"species": "Ovelha",
		"bio": "Nuvem é tão fofinha que os passarinhos tentam fazer ninho nela. Conta estrelas para dormir e sempre perde a conta.",
		"trait": "Lã grossa: aguenta DUAS picadinhas antes de reclamar.",
	},
	"kiko": {
		"species": "Coala",
		"bio": "Kiko dorme 20 horas por dia e passa as outras 4 procurando a folha de eucalipto perfeita. É calmo como uma tarde de domingo.",
		"trait": "Leve e sonolento: mora nos galhos, cuidado para não derrubá-lo.",
	},
	"tata": {
		"species": "Tatu-bola",
		"bio": "Tatá ama rolar ladeira abaixo. Diz que é esporte; os amigos dizem que é preguiça de andar.",
		"trait": "Vira bolinha e ROLA: nas fases de toca, faça uma rampa até a casa dele.",
	},
	"pompom": {
		"species": "Coelho",
		"bio": "Pompom nunca solta a cenoura da sorte. É o mais rápido da turma — e o mais medroso também.",
		"trait": "Orelhas compridas: o abrigo precisa ser bem alto.",
	},
	"patinha": {
		"species": "Pato",
		"bio": "Patinha nada desde que saiu do ovo e acha que todo mundo deveria fazer o mesmo. Faz 'quá' quando está feliz.",
		"trait": "Levinha e nadadora: água não a assusta.",
	},
	"fofa": {
		"species": "Foca",
		"bio": "Fofa equilibra qualquer coisa no nariz — bolas, conchas, até a laranja da Capitu (sem permissão).",
		"trait": "Grandona e nadadora: precisa de abrigo comprido.",
	},
	"tito": {
		"species": "Polvo",
		"bio": "Tito é o marinheiro do fundo do mar: tem oito braços e usa todos para abraçar os amigos.",
		"trait": "Mora no fundo do mar: proteja-o das águas-vivas e dos baiacus.",
	},
}

const INSECTS := {
	"drillfish": {"name": "Baiacu-broca", "desc": "Fura linhas como a abelha-broca. Tampe a toca no coral antes que ele saia."},
	"bee": {"name": "Abelha Zumbi", "desc": "Persegue o bichinho e contorna as barreiras procurando frestas."},
	"ant": {"name": "Formiga Tilim", "desc": "Anda em fila pelo chão, sobe degraus baixos, mas não paredes."},
	"beetle": {"name": "Besouro Bolota", "desc": "Lento e forte: empurra linhas leves. Use barreiras pesadas."},
	"mosquito": {"name": "Mosquito Zizi", "desc": "Pequeno e rápido: passa por qualquer brechinha."},
	"wasp": {"name": "Vespa Faísca", "desc": "Mira (\"!\") e dá uma investida em linha reta."},
	"moth": {"name": "Mariposa Lumi", "desc": "Ama a luz: gira em volta das lâmpadas acesas."},
	"termite": {"name": "Cupim Roque-Roque", "desc": "Rói caixas e tábuas de madeira até quebrarem."},
	"caterpillar": {"name": "Lagarta Gulosa", "desc": "Lenta, mas sobe qualquer parede — até a sua linha."},
	"cricket": {"name": "Grilo Saltitante", "desc": "Pula por cima de paredes. Só teto segura."},
	"broca": {"name": "Abelha Broca", "desc": "Fura a linha depois de um tempinho. Use parede dupla!"},
	"spider": {"name": "Aranha Fiandeira", "desc": "Anda pelo alto e desce reto pelo fio."},
	"crab": {"name": "Caranguejo Belisco", "desc": "Empurra forte e não tem medo de água."},
	"jellyfish": {"name": "Água-viva Gelatina", "desc": "Nada em pulsos lentos no fundo do mar."},
	"puffer": {"name": "Baiacu Bolha", "desc": "Incha quando chega perto e empurra tudo."},
	"traca": {"name": "Traça Come-Tinta", "desc": "Rói a linha mais perto. Dê outra linha para ela roer!"},
	"rino": {"name": "Besouro-Rinoceronte", "desc": "Levanta linhas soltas com o chifre. Trave o abrigo!"},
}
