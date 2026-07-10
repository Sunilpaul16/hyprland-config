import QtQuick
import QtQuick.Layouts
import "../"

// One category's worth of bind rows -- title + a KeyCombo/label pair per
// row, sourced from Binds.rowsFor (see Binds.qml for how rows get grouped).
Column {
    id: root

    required property string categoryName
    readonly property var rows: Binds.rowsFor(categoryName)

    property int columnWidth: 280
    spacing: 8

    Text {
        text: root.categoryName
        color: Colors.text
        font.pixelSize: 14
        font.bold: true
    }

    Column {
        spacing: 6

        Repeater {
            model: root.rows

            RowLayout {
                required property var modelData
                spacing: 12

                KeyCombo { rowData: modelData; Layout.alignment: Qt.AlignVCenter }

                Text {
                    text: modelData.label
                    color: Colors.textMuted
                    font.pixelSize: 12
                    Layout.preferredWidth: root.columnWidth - 130
                    wrapMode: Text.Wrap
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
