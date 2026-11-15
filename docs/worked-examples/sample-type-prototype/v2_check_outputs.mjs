import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const demoPath = path.resolve("outputs/sample-type-prototype/v2/demo.html");
const html = fs.readFileSync(demoPath, "utf8");

const m = html.match(/<script>([\s\S]*)<\/script>/);
assert.ok(m, "Expected inline <script> block in demo.html");
const scriptSrc = m[1];

// 1. Verify full inline script parses with zero JS syntax errors
new vm.Script(scriptSrc, { filename: "demo.html" });
console.log("[node-check] new vm.Script(scriptSrc) compiled cleanly.");

// 2. Execute PAYLOAD + Logic in sandboxed VM without DOM IIFE
const domMarker = "/* === DOM SHELL === */";
const markerIdx = scriptSrc.indexOf(domMarker);
assert.ok(markerIdx > 0, "Expected DOM SHELL marker");
const logicSrc = scriptSrc.slice(0, markerIdx) + "\nglobalThis.__EXPORTS = { PAYLOAD, Logic };";

const ctx = vm.createContext({ globalThis: {} });
ctx.globalThis = ctx;
new vm.Script(logicSrc, { filename: "demo_logic.js" }).runInContext(ctx);

const { PAYLOAD, Logic } = ctx.__EXPORTS;
assert.ok(PAYLOAD && PAYLOAD.metadata, "PAYLOAD.metadata must be populated");
assert.equal(PAYLOAD.labels.length, 8462, "Expected 8,462 labels in PAYLOAD");

const initState = Logic.initial(PAYLOAD);
assert.equal(initState.view, "labels");
assert.equal(initState.selectedId, "LBL_0001");

const allFiltered = Logic.filterLabels(initState, PAYLOAD);
assert.equal(allFiltered.length, 8462, "Unfiltered filterLabels must return all 8,462 labels");

const fullSummary = Logic.computeSummary(allFiltered, PAYLOAD.metadata);
assert.equal(fullSummary.nLabels, 8462);
assert.equal(fullSummary.nSamples, 51351);
assert.equal(fullSummary.nIsolates, 61423);
assert.equal(
  fullSummary.confirmed + fullSummary.reclassified + fullSummary.flagged,
  8462,
  "v1_status counts must partition all 8,462 labels"
);

const diffRows = Logic.filterDiff(initState, PAYLOAD);
const expectedDiffCount = PAYLOAD.labels.filter((l) => l.chg || l.st !== "confirmed").length;
assert.equal(diffRows.length, expectedDiffCount, "filterDiff count mismatch");

const qRows = Logic.filterQuestions(initState, PAYLOAD);
const expectedQCount = PAYLOAD.labels.filter((l) => l.lev !== "text_sufficient").length;
assert.equal(qRows.length, expectedQCount, "filterQuestions count mismatch");

const mycoState = Logic.transition(initState, { myco: "pure_myco" }, PAYLOAD);
const pureMyco = Logic.filterLabels(mycoState, PAYLOAD);
assert.equal(pureMyco.length, 137, "Expected 137 pure mycology-only *_MY labels");

const sparesState = Logic.transition(initState, { cat: "__spares_targets__" }, PAYLOAD);
const sparesRows = Logic.filterLabels(sparesState, PAYLOAD);
assert.ok(sparesRows.length > 0 && sparesRows.every((l) => l.cat === "hemoculture" || l.cat === "urines"));

const wsState = Logic.transition(initState, { query: "__WS_NL__" }, PAYLOAD);
const wsRows = Logic.filterLabels(wsState, PAYLOAD);
assert.ok(wsRows.length >= 857, "Expected >=857 labels with double spaces or newlines");

const sortedAsc = Logic.sortRows(sparesRows.slice(0, 50), "n_samples", "asc");
assert.ok(sortedAsc[0].ns <= sortedAsc[sortedAsc.length - 1].ns, "Ascending sort failed");

console.log(
  `[node-check] ALL PASSED: labels=${fullSummary.nLabels}, samples=${fullSummary.nSamples}, ` +
  `confirmed=${fullSummary.confirmed}, reclassified=${fullSummary.reclassified}, flagged=${fullSummary.flagged}, ` +
  `diff=${diffRows.length}, questions=${qRows.length}, pure_myco=${pureMyco.length}`
);
