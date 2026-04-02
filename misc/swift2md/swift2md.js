#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';

const [,, input, output] = process.argv;

if (!input) {
  console.error('Usage: swift2md <input.swift> [output.md]');
  process.exit(1);
}

const raw = readFileSync(resolve(input), 'utf-8');
const markdown = toMarkdown(raw);

if (output) {
  writeFileSync(resolve(output), markdown, 'utf-8');
  console.error(`✓ ${input} → ${output}`);
} else {
  process.stdout.write(markdown);
}

function toMarkdown(raw) {
  let result = [];
  let currentBuffer = "";
  let i = 0;
  let state = "CODE";

  while (i < raw.length) {
    if (state === "CODE" && raw.startsWith("/*:", i)) {
      if (currentBuffer.trim()) {
        result.push("```swift\n" + currentBuffer.trim() + "\n```");
      }
      currentBuffer = "";
      state = "PROSE";
      i += 3;
      continue;
    }

    if (state === "PROSE" && raw.startsWith("*/", i)) {
      if (currentBuffer.trim()) {
        result.push(currentBuffer.trim());
      }
      currentBuffer = "";
      state = "CODE";
      i += 2;
      continue;
    }

    currentBuffer += raw[i];
    i++;
  }

  if (state === "CODE" && currentBuffer.trim()) {
    result.push("```swift\n" + currentBuffer.trim() + "\n```");
  }

  return result.join("\n\n");
}
