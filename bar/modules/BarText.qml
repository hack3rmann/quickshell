import QtQuick
import qs.bar

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    // Fractional size (via scale) renders repeating bar/underscore glyphs more evenly.
    font.pixelSize: Math.ceil(Theme.fontSize)
    scale: Theme.fontSize / Math.ceil(Theme.fontSize)
    // Keep the visual left/right edge stable when eliding/growing (Center would drift).
    transformOrigin: {
        switch (horizontalAlignment) {
        case Text.AlignLeft:
            return Item.Left;
        case Text.AlignRight:
            return Item.Right;
        default:
            return Item.Center;
        }
    }
    font.bold: true
    verticalAlignment: Text.AlignVCenter
}
