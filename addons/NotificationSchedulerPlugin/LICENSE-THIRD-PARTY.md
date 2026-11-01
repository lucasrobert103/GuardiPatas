# Notification Scheduler Plugin (terceiros)

- Origem: https://github.com/godot-mobile-plugins/godot-notification-scheduler (versão 6.0, para Godot 4.7)
- Autor: Cengiz (https://github.com/cengiz-pz) / Godot Mobile Plugins
- Licença: MIT

Copiado sem alterações: a parte Android e os utilitários `GMPShared/GmpLogger.gd` e
`GMPShared/SpmDependency.gd`. O menu "GMP" do editor (que baixa arquivos da internet) não foi incluído.
O plugin só agenda notificações LOCAIS no aparelho: não usa internet nem coleta dados.
As permissões SCHEDULE_EXACT_ALARM, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS e WAKE_LOCK que ele
declara são removidas do APK por `addons/guardipatas_android` (sem a permissão de alarme exato,
o plugin usa alarmes inexatos).
