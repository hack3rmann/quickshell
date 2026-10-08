.pragma library

// Physical EN↔RU key positions (lowercase + uppercase + common punctuation).
const _en = "`qwertyuiop[]asdfghjkl;'zxcvbnm,./";
const _ru = "ёйцукенгшщзхъфывапролджэячсмитьбю.";
const _enU = "~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?";
const _ruU = "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,";

const _map = (function () {
    const m = Object.create(null);
    function pair(a, b) {
        for (let i = 0; i < a.length && i < b.length; i++) {
            m[a[i]] = b[i];
            m[b[i]] = a[i];
        }
    }
    pair(_en, _ru);
    pair(_enU, _ruU);
    return m;
})();

function layoutAlt(text) {
    if (!text)
        return "";
    let out = "";
    for (let i = 0; i < text.length; i++) {
        const ch = text[i];
        out += _map[ch] !== undefined ? _map[ch] : ch;
    }
    return out;
}

function queryVariants(query) {
    const q = (query || "").trim();
    if (!q)
        return [""];
    const alt = layoutAlt(q);
    if (alt === q)
        return [q];
    return [q, alt];
}

function fuzzyScore(haystack, needle) {
    if (!needle)
        return 1;
    if (!haystack)
        return 0;

    const h = haystack.toLowerCase();
    const n = needle.toLowerCase();

    if (h === n)
        return 1000;
    if (h.startsWith(n))
        return 800 - Math.min(h.length, 200);
    const idx = h.indexOf(n);
    if (idx >= 0)
        return 600 - Math.min(idx, 200);

    let qi = 0;
    let score = 0;
    let prev = -2;
    for (let ti = 0; ti < h.length && qi < n.length; ti++) {
        if (h[ti] !== n[qi])
            continue;
        score += (ti === prev + 1) ? 18 : 10;
        if (ti === 0 || /[\s\-_.]/.test(h[ti - 1]))
            score += 25;
        prev = ti;
        qi++;
    }
    return qi === n.length ? Math.max(score, 1) : 0;
}

function scoreApp(app, query) {
    const variants = queryVariants(query);
    const fields = [];
    if (app.name)
        fields.push(app.name);
    if (app.genericName)
        fields.push(app.genericName);
    if (app.comment)
        fields.push(app.comment);
    if (app.id)
        fields.push(app.id);

    let best = 0;
    for (let vi = 0; vi < variants.length; vi++) {
        const q = variants[vi];
        for (let fi = 0; fi < fields.length; fi++)
            best = Math.max(best, fuzzyScore(fields[fi], q));
    }
    return best;
}
