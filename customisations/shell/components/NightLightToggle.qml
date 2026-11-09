import Caelestia.I18n
import qs.modules.nexus.common

ToggleRow {
    id: root

    required property var service

    text: Tr.tr("Night light")
    subtext: Tr.tr("Warm screen colours · 5200K · automatic 19:00–07:00")
    checked: service.enabled
    disabled: !service.available || service.busy
    onToggled: root.service.toggle()
}
