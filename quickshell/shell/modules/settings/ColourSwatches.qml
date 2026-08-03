import QtQuick
import "../../services"
import "../../components"

// The generated palette, shown rather than described. Reads Colors directly,
// so it re-tints the moment switchwall rewrites the theme
Flow {
    id: root

    // [{ color, name }] — the roles worth eyeballing, not every M3 token
    readonly property var roles: [
        { color: Colors.primary, name: "primary" },
        { color: Colors.secondary, name: "secondary" },
        { color: Colors.tertiary, name: "tertiary" },
        { color: Colors.secondaryContainer, name: "secondaryContainer" },
        { color: Colors.background, name: "background" },
        { color: Colors.surface, name: "surface" },
        { color: Colors.text, name: "text" },
        { color: Colors.textMuted, name: "textMuted" },
        { color: Colors.outline, name: "outline" },
        { color: Colors.outlineVariant, name: "outlineVariant" },
        { color: Colors.error, name: "error" },
        { color: Colors.errorContainer, name: "errorContainer" }
    ]

    spacing: Motion.spacing.normal

    Repeater {
        model: root.roles

        Rectangle {
            required property var modelData

            implicitWidth: 46
            implicitHeight: 46
            radius: Motion.rounding.normal
            color: modelData.color
            // Dark roles would vanish against the page, so outline everything
            border.width: 1
            border.color: Colors.outlineVariant

            Behavior on color { ColorAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }

            PopupToolTip {
                hoverTarget: parent
                text: modelData.name
                shown: swatchHover.containsMouse
            }

            MouseArea {
                id: swatchHover

                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
}
