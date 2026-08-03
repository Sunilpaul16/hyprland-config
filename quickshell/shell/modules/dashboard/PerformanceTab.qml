import "performance"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../services"

// Performance tab: CPU/GPU hero cards over Storage/Network/Memory, plus a battery tank where present
// Card visibility uses each Loader's `active`, never `visible` — binding to a descendant's effective visibility latches false forever
Item {
    id: root

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Motion.spacing.large

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Motion.spacing.large

            // Hero row
            RowLayout {
                spacing: Motion.spacing.large

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
                spacing: Motion.spacing.large

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
