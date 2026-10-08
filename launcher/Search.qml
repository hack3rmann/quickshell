pragma Singleton
import QtQuick
import Quickshell
import "Fuzzy.js" as Fuzzy
import "Math.js" as MathEval

Item {
    id: root

    readonly property int maxResults: 12

    function search(query) {
        const q = (query || "").trim();
        const results = [];

        const mathValue = MathEval.evaluate(q);
        if (mathValue !== null) {
            const formatted = MathEval.formatResult(mathValue);
            results.push({
                type: "math",
                name: formatted,
                subtitle: q + " = " + formatted,
                value: formatted,
                score: 1e9,
                app: null,
            });
        }

        const apps = DesktopEntries.applications.values || [];
        if (!q) {
            const alphabetical = apps.slice().sort(function (a, b) {
                return (a.name || "").localeCompare(b.name || "");
            });
            for (let i = 0; i < alphabetical.length && results.length < root.maxResults; i++) {
                results.push({
                    type: "app",
                    name: alphabetical[i].name || alphabetical[i].id || "",
                    subtitle: alphabetical[i].genericName || "",
                    value: "",
                    score: 0,
                    app: alphabetical[i],
                });
            }
            return results;
        }

        const scored = [];
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            const score = Fuzzy.scoreApp(app, q);
            if (score <= 0)
                continue;
            scored.push({
                type: "app",
                name: app.name || app.id || "",
                subtitle: app.genericName || "",
                value: "",
                score: score,
                app: app,
            });
        }

        scored.sort(function (a, b) {
            if (b.score !== a.score)
                return b.score - a.score;
            return (a.name || "").localeCompare(b.name || "");
        });

        for (let j = 0; j < scored.length && results.length < root.maxResults; j++)
            results.push(scored[j]);

        return results;
    }
}
