import QtQuick
import qs.bar

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    // Fractional point size (like Waybar's font-size: 99%) — integer pixelSize
    // grid-fits underscore/bar glyphs and leaves visible gaps between them.
    font.pointSize: Theme.fontPointSize
    font.hintingPreference: Font.PreferNoHinting
    font.kerning: false
    font.bold: true
    renderType: Text.QtRendering
    verticalAlignment: Text.AlignVCenter
}
