import QtQuick
import qs.bar

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    // Fractional size (via scale) renders repeating bar/underscore glyphs more evenly.
    font.pixelSize: Math.ceil(Theme.fontSize)
    scale: Theme.fontSize / Math.ceil(Theme.fontSize)
    transformOrigin: Item.Center
    font.bold: true
    verticalAlignment: Text.AlignVCenter
}
