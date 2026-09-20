#!/usr/bin/env node

"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(
    path.resolve(__dirname, "..", "qml", "FutoInputHandler.qml"), "utf8");
const start = source.indexOf("    function wordStartBeforeReplacement(");
const end = source.indexOf("    function lastWord(", start);
if (start < 0 || end < 0)
    throw new Error("the committed-word position helper was not found");

const context = {};
vm.createContext(context);
vm.runInContext(source.substring(start, end), context,
                { filename: "FutoInputHandler.qml" });

function check(description, cursor, length, committed, expected) {
    const actual = context.wordStartBeforeReplacement(cursor, length, committed);
    if (actual !== expected) {
        throw new Error(description + ": got " + actual + ", expected " + expected);
    }
    console.log("ok    " + description.padEnd(38) + actual);
}

// With immediate commits the cursor is already after the word. Replacements
// must begin at the word's start, not append another word length to the cursor.
check("first committed word", 3, 3, true, 0);
check("committed word after context", 9, 3, true, 6);
check("longer committed correction source", 12, 5, true, 7);

// Keep the helper correct if a genuine Maliit pre-edit is ever passed through:
// its text is outside surroundingText, so the cursor itself is the start.
check("genuine pre-edit compatibility", 6, 3, false, 6);
check("invalid cursor", -1, 3, true, -1);

console.log("\nCommitted-word transition checks passed");
