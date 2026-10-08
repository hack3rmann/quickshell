import QtQuick
import qs.bar

Text {
    required property string mark
    text: mark
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Math.ceil(Theme.fontSize)
    scale: Theme.fontSize / Math.ceil(Theme.fontSize)
    transformOrigin: Item.Center
    font.bold: true
    verticalAlignment: Text.AlignVCenter
    leftPadding: Theme.sepPadH
    rightPadding: Theme.sepPadH
}
