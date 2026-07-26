import "performance"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../services"

// Performance tab: CPU/GPU hero cards over Storage/Network/Memory, with the
// battery tank alongside on hardware that has one. Layout ported from
// caelestia's Performance.qml.
//
// Card visibility is driven by each Loader's own `active` flag, never by the
// loaded item's `visible`: a parent whose `visible` binds to a descendant's
// `visible` latches false forever, because `visible` reads *effective*
// visibility, so the descendant just reports the parent's own state back.
// That latched on every dashboard reopen, since the panes are created while
// the window is still hidden (offsetScale is 1 at the instant they load).
Item {
    id: root

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Hero row
            RowLayout {
                spacing: 12

                CardLoader {
                    active: true
                    sourceComponent: HeroCard {
                        iconName: "memory"
                        label: "CPU"
                        subLabel: SystemUsage.cpuName.length > 0 ? SystemUsage.cpuName : "Unknown CPU"
                        usage: SystemUsage.cpuPercentage
                        temperature: SystemUsage.cpuTemperature
                        accent: Colors.primary

                        Component.onCompleted: SystemUsage.ref()
                        Component.onDestruction: SystemUsage.unref()
                    }
                }

                CardLoader {
                    active: Gpu.available
                    sourceComponent: HeroCard {
                        iconName: "desktop_windows"
                        label: "GPU"
                        subLabel: Gpu.name.length > 0 ? Gpu.name : "Unknown GPU"
                        usage: Gpu.percentage
                        temperature: Gpu.temperature
                        accent: Colors.secondary
                    }
                }
            }

            // Detail row
            RowLayout {
                spacing: 12

                CardLoader {
                    active: Storage.disks.length > 0
                    sourceComponent: StorageCard {}
                }

                CardLoader {
                    active: true
                    sourceComponent: NetworkCard {}
                }

                CardLoader {
                    active: true
                    sourceComponent: MemoryCard {}
                }
            }
        }

        CardLoader {
            Layout.fillWidth: false
            active: UPower.displayDevice?.isLaptopBattery ?? false
            sourceComponent: BatteryCard {}
        }
    }

    // Keeps the GPU service polling only while this tab is alive, so
    // `Gpu.available` is populated before its card is gated on it
    Component.onCompleted: {
        Gpu.ref();
        Storage.ref();
    }
    Component.onDestruction: {
        Gpu.unref();
        Storage.unref();
    }

    component CardLoader: Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: active
    }
}
