.pragma library

function couldBeMath(text) {
    const t = (text || "").trim();
    if (!t)
        return false;
    if (!/^[\d\s.+\-*/^()]+$/.test(t))
        return false;
    if (!/\d/.test(t))
        return false;
    // Require an operator so bare numbers don't become calc rows.
    return /[+\-*/^]/.test(t);
}

function evaluate(text) {
    const t = (text || "").trim();
    if (!couldBeMath(t))
        return null;
    try {
        const expr = t.replace(/\^/g, "**");
        const result = Function(`"use strict"; return (${expr});`)();
        if (typeof result !== "number" || !isFinite(result))
            return null;
        return result;
    } catch (e) {
        return null;
    }
}

function formatResult(value) {
    if (typeof value !== "number")
        return "";
    if (Number.isInteger(value))
        return String(value);
    // Trim floating noise without forcing fixed precision.
    return String(parseFloat(value.toPrecision(12)));
}
