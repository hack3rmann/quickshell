import QtQuick
import qs.bar

Text {
    required property string mark
    text: mark
    color: Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter
    leftPadding: 2
    rightPadding: 2
}
