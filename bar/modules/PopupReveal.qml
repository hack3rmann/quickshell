import QtQuick
import qs.bar

// Open/close chrome for bar PopupWindows (matches notification-center motion).
Item {
    id: root

    default property alias content: body.data

    signal finishedClosing

    implicitWidth: body.childrenRect.width
    implicitHeight: body.childrenRect.height
    width: implicitWidth
    height: implicitHeight

    opacity: 0
    scale: Theme.popupScaleFrom
    transformOrigin: Item.Top

    transform: Translate {
        id: slide
        y: -Theme.popupSlide
    }

    Item {
        id: body
        width: childrenRect.width
        height: childrenRect.height
    }

    function resetClosed() {
        openAnim.stop();
        closeAnim.stop();
        showDelay.stop();
        opacity = 0;
        scale = Theme.popupScaleFrom;
        slide.y = -Theme.popupSlide;
    }

    function show() {
        // Always start from the closed pose so re-opens animate every time.
        resetClosed();
        // Defer one frame so PopupWindow can map before the anim runs —
        // otherwise open looks like a snap / skipped reveal.
        showDelay.restart();
    }

    function hide() {
        showDelay.stop();
        openAnim.stop();
        closeAnim.restart();
    }

    Timer {
        id: showDelay
        interval: 16
        repeat: false
        onTriggered: openAnim.start()
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide
            property: "y"
            to: 0
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "scale"
            to: Theme.popupScaleFrom
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide
            property: "y"
            to: -Theme.popupSlide
            duration: Theme.animPopup
            easing.type: Easing.OutCubic
        }
        onFinished: root.finishedClosing()
    }
}
