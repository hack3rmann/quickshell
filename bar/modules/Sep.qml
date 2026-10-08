import QtQuick
import qs.bar

Text {
    required property string mark
    text: mark
    color: Theme.text
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontPointSize
    font.hintingPreference: Font.PreferNoHinting
    font.kerning: false
    font.bold: true
    renderType: Text.QtRendering
    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.sepPadH
    rightPadding: Theme.sepPadH
}
