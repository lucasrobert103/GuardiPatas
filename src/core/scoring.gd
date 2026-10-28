class_name Scoring
## Regras de pontuação, puras e testáveis.

const COINS_PER_NEW_STAR := 10
const COINS_PER_WIN := 3
const COINS_PERFECT_BONUS := 5


## Estrelas por economia de tinta. `ink_used` é a fração 0..1 do orçamento.
## thresholds = [máx p/ 3 estrelas, máx p/ 2 estrelas]. Vencer sempre dá ao menos 1.
static func stars_for(ink_used: float, thresholds: Array) -> int:
	var t3: float = thresholds[0] if thresholds.size() > 0 else 0.4
	var t2: float = thresholds[1] if thresholds.size() > 1 else 0.7
	if ink_used <= t3 + 0.0001:
		return 3
	if ink_used <= t2 + 0.0001:
		return 2
	return 1


## Moedas ganhas: estrelas novas valem mais que repetir a fase (sem "farm" agressivo).
static func coins_for(prev_best: int, stars: int) -> int:
	var gained := maxi(stars - prev_best, 0) * COINS_PER_NEW_STAR
	gained += COINS_PER_WIN
	if stars == 3 and prev_best < 3:
		gained += COINS_PERFECT_BONUS
	return gained
