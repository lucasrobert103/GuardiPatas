@tool
extends EditorPlugin
## Ajustes do APK do GuardiPatas. O plugin de notificações declara permissões que a Google
## Play restringe (alarme exato e ignorar otimização de bateria) e que o jogo não precisa:
## os recados usam alarmes inexatos. O "tools:node=remove" tira essas permissões no merge
## do manifesto (só tem efeito no build Gradle, que é o único que inclui o plugin).

var _export: Exporter


func _enter_tree() -> void:
	_export = Exporter.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class Exporter extends EditorExportPlugin:
	const REMOVE := ["android.permission.SCHEDULE_EXACT_ALARM", "android.permission.USE_EXACT_ALARM",
		"android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS", "android.permission.WAKE_LOCK"]

	func _get_name() -> String:
		return "GuardiPatasAndroid"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		var out := ""
		for p in REMOVE:
			out += '\n\t<uses-permission android:name="%s" tools:node="remove" />' % p
		return out + "\n"
