import fs from "node:fs";
import path from "node:path";

function listJsonFiles(dir) {
  const out = [];
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...listJsonFiles(full));
    else if (ent.isFile() && ent.name.endsWith(".json")) out.push(full);
  }
  return out;
}

function loadJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function flattenKeys(obj, prefix = "") {
  const keys = [];
  if (!obj || typeof obj !== "object") return keys;
  for (const [k, v] of Object.entries(obj)) {
    const next = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === "object" && !Array.isArray(v)) keys.push(...flattenKeys(v, next));
    else keys.push(next);
  }
  return keys;
}

function toRel(p, root) {
  return path.relative(root, p).replaceAll("\\", "/");
}

const webRoot = path.resolve(process.cwd());
const localesRoot = path.join(webRoot, "locales");
const enRoot = path.join(localesRoot, "en");

if (!fs.existsSync(enRoot)) {
  console.error(`[i18n:parity] Missing base locale: ${enRoot}`);
  process.exit(2);
}

// Discover all non-English locale directories automatically
const otherLangs = fs.readdirSync(localesRoot, { withFileTypes: true })
  .filter((d) => d.isDirectory() && d.name !== "en")
  .map((d) => d.name);

if (!otherLangs.length) {
  console.error("[i18n:parity] No translation locales found besides en");
  process.exit(2);
}

const enFiles = listJsonFiles(enRoot).map((p) => toRel(p, enRoot)).sort();

let ok = true;

for (const lang of otherLangs) {
  const langRoot = path.join(localesRoot, lang);
  const langFiles = listJsonFiles(langRoot).map((p) => toRel(p, langRoot)).sort();

  const missingFiles = enFiles.filter((f) => !langFiles.includes(f));
  const extraFiles = langFiles.filter((f) => !enFiles.includes(f));

  if (missingFiles.length) {
    ok = false;
    console.error(`[i18n:parity] Missing ${lang} files:`);
    for (const f of missingFiles) console.error(`- ${f}`);
  }
  if (extraFiles.length) {
    ok = false;
    console.error(`[i18n:parity] Extra ${lang} files:`);
    for (const f of extraFiles) console.error(`- ${f}`);
  }

  for (const rel of enFiles) {
    if (!langFiles.includes(rel)) continue;
    const enJson = loadJson(path.join(enRoot, rel));
    const langJson = loadJson(path.join(langRoot, rel));
    const enKeys = new Set(flattenKeys(enJson));
    const langKeys = new Set(flattenKeys(langJson));

    const missingKeys = [...enKeys].filter((k) => !langKeys.has(k)).sort();
    const extraKeys = [...langKeys].filter((k) => !enKeys.has(k)).sort();

    if (missingKeys.length || extraKeys.length) {
      ok = false;
      console.error(`[i18n:parity] Key mismatch in ${lang}/${rel}`);
      if (missingKeys.length) {
        console.error(`  Missing ${lang} keys:`);
        for (const k of missingKeys) console.error(`  - ${k}`);
      }
      if (extraKeys.length) {
        console.error(`  Extra ${lang} keys:`);
        for (const k of extraKeys) console.error(`  - ${k}`);
      }
    }
  }
}

if (!ok) process.exit(1);
console.log(`[i18n:parity] OK (checked: en vs ${otherLangs.join(", ")})`);
