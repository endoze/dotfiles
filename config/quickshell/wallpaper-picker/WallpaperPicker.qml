import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import Quickshell
import "config"

// Minimal image-carousel wallpaper selector.
// Browses pre-generated thumbnails from settings.thumbDir, applies the chosen
// wallpaper via `awww`, then runs settings.extraReloadCommand "<wallpaper>"
// (our wallust hook). All matugen/color-filter/search/video machinery from the
// upstream project has been stripped.
Item {
    id: window

    Settings { id: settings }

    // --- Responsive scaling ---
    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val); }
    function anim(ms) {
        return settings.uiAnimationsEnabled ? Math.max(0, Math.round(ms * settings.uiAnimationScale)) : 0;
    }

    // --- Transitions ---
    readonly property var safeTransitions: ["fade", "wipe", "wave", "grow", "center", "outer", "any"]
    function normalizeTransition(name) {
        const t = String(name || "").trim().toLowerCase();
        if (t === "" || t === "random") return "random";
        return window.safeTransitions.indexOf(t) !== -1 ? t : "fade";
    }
    function pickTransition() {
        const chosen = normalizeTransition(settings.wallpaperTransitionType);
        if (chosen !== "random") return chosen;
        return window.safeTransitions[Math.floor(Math.random() * window.safeTransitions.length)];
    }

    // --- Dimensions ---
    readonly property string thumbDir: "file://" + settings.thumbDir
    readonly property string srcDir: settings.wallpaperDir
    readonly property real itemWidth: window.s(400)
    readonly property real itemHeight: window.s(420)
    readonly property real borderWidth: window.s(3)
    readonly property real spacing: window.s(10)
    readonly property real skewFactor: -0.35

    // --- State ---
    property bool initialFocusSet: false
    property bool isApplying: false
    property bool isReady: visible && localFolderModel.status === FolderListModel.Ready
    property int scrollAccum: 0
    property real scrollThreshold: window.s(300)

    Timer { id: scrollThrottle; interval: settings.scrollThrottleMs }

    function requestClose() { closeAfterApply.restart(); }
    Timer { id: closeAfterApply; interval: settings.closeDelayMs; repeat: false; onTriggered: Qt.quit() }

    onVisibleChanged: {
        if (!visible) {
            window.initialFocusSet = false;
            window.isApplying = false;
            Qt.quit();
        }
    }

    // --- Apply: awww img, then the reload hook with the wallpaper path ---
    function applyWallpaper(safeFileName) {
        if (!safeFileName || window.isApplying) return;
        window.isApplying = true;

        const escapeBash = (str) => String(str).replace(/(["\\$`])/g, '\\$1');
        const wall = window.srcDir + "/" + String(safeFileName);
        const transition = window.pickTransition();
        const duration = Number(settings.wallpaperTransitionDuration).toFixed(2);
        const fps = Math.max(1, Number(settings.wallpaperTransitionFps));
        const reload = String(settings.extraReloadCommand || "");
        const reloadLine = reload !== "" ? `${escapeBash(reload)} "$WALL" || true` : "";

        const script = `
            (
                WALL="${escapeBash(wall)}"
                if ! awww img --transition-type "${transition}" --transition-duration "${duration}" --transition-fps "${fps}" "$WALL" >/dev/null 2>&1; then
                    awww img --transition-type fade --transition-duration "${duration}" --transition-fps "${fps}" "$WALL"
                fi
                ${reloadLine}
            ) > /tmp/wallpaper-picker-apply.log 2>&1 & disown
        `;
        Quickshell.execDetached(["bash", "-c", script]);
        window.requestClose();
    }

    // --- Navigation (wrap-around) ---
    function step(direction) {
        let count = localProxyModel.count;
        if (count === 0) return;
        view.currentIndex = (view.currentIndex + direction + count) % count;
    }

    // --- Initial focus / centering ---
    function executeFocusRestore(targetIndex) {
        if (targetIndex >= 0 && targetIndex < localProxyModel.count) {
            view.forceLayout();
            view.positionViewAtIndex(targetIndex, ListView.Center);
            view.currentIndex = targetIndex;
            window.initialFocusSet = true;
        }
    }
    function tryFocus() {
        if (initialFocusSet) return;
        if (localProxyModel.count > 0) window.executeFocusRestore(0);
    }

    // --- Models: thumbnail dir -> proxy list the carousel renders ---
    ListModel { id: localProxyModel }

    FolderListModel {
        id: localFolderModel
        folder: window.thumbDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: window.syncLocalModel()
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() }
    }

    function syncLocalModel() {
        let startIdx = localProxyModel.count;
        let endIdx = localFolderModel.count;
        if (endIdx < startIdx) { localProxyModel.clear(); startIdx = 0; }
        for (let i = startIdx; i < endIdx; i++) {
            let fn = localFolderModel.get(i, "fileName");
            let fu = localFolderModel.get(i, "fileUrl");
            if (fn !== undefined) localProxyModel.append({ "fileName": fn, "fileUrl": String(fu) });
        }
        if (!window.initialFocusSet && localProxyModel.count > 0) window.tryFocus();
    }

    // --- Shortcuts ---
    Shortcut { sequences: ["Left", "h"]; enabled: !window.isApplying; onActivated: window.step(-1) }
    Shortcut { sequences: ["Right", "l"]; enabled: !window.isApplying; onActivated: window.step(1) }
    Shortcut {
        sequence: "Return"
        enabled: !window.isApplying
        onActivated: {
            if (view.currentIndex >= 0 && view.currentIndex < localProxyModel.count) {
                let fname = localProxyModel.get(view.currentIndex).fileName;
                if (fname) window.applyWallpaper(String(fname));
            }
        }
    }

    // --- Carousel ---
    ListView {
        id: view
        anchors.fill: parent

        opacity: window.isReady ? 1.0 : 0.0
        anchors.margins: window.isReady ? 0 : window.s(40)
        Behavior on opacity { NumberAnimation { duration: window.anim(600); easing.type: Easing.OutQuart } }
        Behavior on anchors.margins { NumberAnimation { duration: window.anim(700); easing.type: Easing.OutExpo } }

        spacing: 0
        orientation: ListView.Horizontal
        clip: false

        interactive: !window.isApplying
        cacheBuffer: 2000

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2)
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2)

        highlightMoveDuration: window.initialFocusSet ? window.anim(500) : 0
        focus: true

        add: Transition {
            enabled: window.initialFocusSet
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: window.anim(400); easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: window.anim(400); easing.type: Easing.OutBack }
            }
        }
        addDisplaced: Transition {
            enabled: window.initialFocusSet
            NumberAnimation { property: "x"; duration: window.anim(400); easing.type: Easing.OutCubic }
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }

        model: localProxyModel

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                if (window.isApplying || scrollThrottle.running) { wheel.accepted = true; return; }
                let dx = wheel.angleDelta.x;
                let dy = wheel.angleDelta.y;
                let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;
                window.scrollAccum += delta;
                if (Math.abs(window.scrollAccum) >= window.scrollThreshold) {
                    window.step(window.scrollAccum > 0 ? -1 : 1);
                    window.scrollAccum = 0;
                    scrollThrottle.start();
                }
                wheel.accepted = true;
            }
        }

        delegate: Item {
            id: delegateRoot

            readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
            readonly property bool isVisuallyEnlarged: ListView.isCurrentItem
            readonly property real targetWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5)
            readonly property real targetHeight: isVisuallyEnlarged ? (window.itemHeight + window.s(30)) : window.itemHeight

            width: targetWidth + window.spacing
            height: targetHeight
            opacity: isVisuallyEnlarged ? 1.0 : 0.6
            scale: 1.0
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            z: isVisuallyEnlarged ? 10 : 1

            Behavior on width   { enabled: window.initialFocusSet; NumberAnimation { duration: window.anim(500); easing.type: Easing.InOutQuad } }
            Behavior on height  { enabled: window.initialFocusSet; NumberAnimation { duration: window.anim(500); easing.type: Easing.InOutQuad } }
            Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: window.anim(500); easing.type: Easing.InOutQuad } }

            Item {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                width: parent.width > 0 ? parent.width * (delegateRoot.targetWidth / (delegateRoot.targetWidth + window.spacing)) : 0
                height: parent.height

                transform: Matrix4x4 {
                    property real sk: window.skewFactor
                    matrix: Qt.matrix4x4(1, sk, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !window.isApplying
                    onClicked: {
                        view.currentIndex = index;
                        window.applyWallpaper(delegateRoot.safeFileName);
                    }
                }

                // Outer stretched image: shows through the borderWidth inset as a frame.
                Image {
                    anchors.fill: parent
                    source: fileUrl !== undefined ? fileUrl : ""
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    asynchronous: true
                }

                // Inner crisp crop, inset by borderWidth (the per-card frame).
                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth
                    Rectangle { anchors.fill: parent; color: "black" }
                    clip: true

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: window.s(-50)
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
                        height: window.itemHeight + window.s(30)
                        fillMode: Image.PreserveAspectCrop
                        source: fileUrl !== undefined ? fileUrl : ""
                        asynchronous: true

                        transform: Matrix4x4 {
                            property real sk: -window.skewFactor
                            matrix: Qt.matrix4x4(1, sk, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: view.forceActiveFocus()
}
