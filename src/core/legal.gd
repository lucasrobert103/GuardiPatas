class_name Legal
## Termos de Uso, Política de Privacidade (LGPD), direitos do titular e guia para responsáveis.
## Os textos vêm de data/legal.json (gerado por tools/make_legal.py, em PT/EN/ES) e
## o aceite fica gravado no save: {"accepted": versão, "date": dia}.

const PATH := "res://data/legal.json"
const ORDER := ["terms", "privacy", "rights", "parents"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return _data


static func version() -> String:
	return str(data().get("version", "1.0"))


static func email() -> String:
	return str(data().get("email", ""))


## "pt" | "en" | "es" a partir do idioma do jogo.
static func lang() -> String:
	var code := Game.lang_code()
	return "pt" if code.begins_with("pt") else (code if code in ["en", "es"] else "pt")


## Texto no idioma atual (cai para o português se faltar a tradução).
static func text(entry: Variant) -> String:
	if entry is Dictionary:
		return str(entry.get(lang(), entry.get("pt", "")))
	return str(entry)


static func doc(id: String) -> Dictionary:
	for d in data().get("docs", []):
		if str(d.get("id", "")) == id:
			return d
	return {}


static func updated_line() -> String:
	var ui: Dictionary = data().get("ui", {})
	return text(ui.get("updated", "")) % [text(data().get("date", {})), version()]


static func by_line() -> String:
	return text(data().get("ui", {}).get("by", ""))


static func accepted_version() -> String:
	return str(Game.data.get("legal", {}).get("accepted", ""))


static func accepted_date() -> String:
	var date := str(Game.data.get("legal", {}).get("date", ""))
	var parts := date.split("-")
	if parts.size() == 3 and lang() != "en":
		return "%s/%s/%s" % [parts[2], parts[1], parts[0]]
	return date


## Já aceitou a versão atual?
static func accepted() -> bool:
	return accepted_version() == version()


## Aceitou uma versão anterior (mostra "Atualizamos os termos" em vez de "Boas-vindas").
static func is_update() -> bool:
	return accepted_version() != "" and not accepted()


static func accept() -> void:
	if not Game.data.has("legal"):
		Game.data["legal"] = {}
	Game.data["legal"]["accepted"] = version()
	Game.data["legal"]["date"] = Time.get_date_string_from_system()
	Game.save()


## Resumo do que o jogo guarda agora neste aparelho (direito de acesso, LGPD art. 18 II).
static func stored_summary() -> Array:
	var d := Game.data
	var owned: int = d.get("owned", []).size() + d.get("fx_owned", []).size() + d.get("store", {}).get("owned", []).size()
	return [
		["Fases vencidas", str(Game.completed_count())],
		["Moedas", str(Game.coins())],
		["Itens e acessórios", str(owned)],
		["Conquistas", str(d.get("achievements", []).size())],
		["Fotos do Álbum", str(d.get("album", []).size())],
		["Fases criadas no editor", str(d.get("custom", []).size())],
		["Termos aceitos", accepted_version() if accepted_version() != "" else "—"],
	]
