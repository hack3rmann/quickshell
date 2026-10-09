pragma Singleton
import QtQuick

QtObject {
    // Port of waybruh window-title.slint replace-title / replace-firefox / replace-obsidian.
    // Use regex/split — QML's JS engine has no String.replaceAll.
    function rewrite(appId, title) {
        const id = String(appId || "");
        const t = String(title || "");
        if (!t)
            return "";

        if (id === "kitty")
            return "  [" + t + "]";

        if (id === "org.mozilla.firefox" || id === "firefox")
            return replaceFirefox(t);

        if (id === "obsidian")
            return replaceObsidian(t);

        return t;
    }

    function replaceObsidian(title) {
        const cleaned = String(title).replace(/ - Obsidian Vault - Obsidian .*/, "");
        return "  " + cleaned;
    }

    function replaceFirefox(title) {
        let s = String(title);
        s = s.replace(/ — Mozilla Firefox/g, "");
        s = s.replace(/Mozilla Firefox/g, "");

        if (s.indexOf(" - YouTube") >= 0) {
            const youtubeRemoved = s.replace(/ - YouTube/g, "").trim();
            return "  " + youtubeRemoved;
        }

        if (s.trim() === "YouTube")
            return " ";

        if (s.indexOf(" at DuckDuckGo") >= 0) {
            const ddgRemoved = s.replace(/ at DuckDuckGo/g, "").trim();
            return "  " + ddgRemoved;
        }

        return "  " + s.trim();
    }
}
