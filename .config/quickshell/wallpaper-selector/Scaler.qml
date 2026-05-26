import QtQuick

Item {
    visible: false

    property real currentWidth: 1920.0
    property real currentHeight: 1080.0
    property real uiScale: 1.0
    property real baseScale: {
        if (currentWidth <= 0 || currentHeight <= 0) return 1.0;
        const rw = currentWidth / 1920.0;
        const rh = currentHeight / 1080.0;
        const r = Math.min(rw, rh);
        const scale = r <= 1.0 ? Math.max(0.35, Math.pow(r, 0.85)) : Math.pow(r, 0.5);
        return scale * uiScale;
    }

    function s(val) {
        return Math.round(val * baseScale);
    }
}
