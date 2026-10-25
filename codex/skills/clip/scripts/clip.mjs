#!/usr/bin/env node
// Dump web articles into an Obsidian vault's Clippings/ via mdhq, normalized to Web Clipper frontmatter.
import { spawn } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

const MDHQ_PACKAGE = "@songmu/mdhq@0.0.7";
const MAX_NAME_BYTES = 240;
const X_HOSTS = new Set(["x.com", "twitter.com", "www.x.com", "www.twitter.com", "mobile.twitter.com"]);

function usage() {
  console.error(
    "usage: clip.mjs [--dest DIR] [--vault-root DIR] [--update] <url> [<url>...]\n" +
      "  --dest DIR        destination (relative to vault root, or absolute); default Clippings\n" +
      "  --vault-root DIR  vault root; default: nearest ancestor of cwd containing .obsidian\n" +
      "  --update          overwrite an existing note with the same source (default: skip)",
  );
  process.exit(2);
}

function parseArgs(argv) {
  const opts = { dest: "Clippings", vaultRoot: null, update: false, urls: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--dest") opts.dest = argv[++i] ?? usage();
    else if (a === "--vault-root") opts.vaultRoot = argv[++i] ?? usage();
    else if (a === "--update") opts.update = true;
    else if (a === "-h" || a === "--help") usage();
    else if (a.startsWith("--")) usage();
    else opts.urls.push(a);
  }
  if (opts.urls.length === 0) usage();
  return opts;
}

function findVaultRoot(start) {
  for (let dir = resolve(start); ; dir = dirname(dir)) {
    if (existsSync(join(dir, ".obsidian"))) return dir;
    if (dirname(dir) === dir) return null;
  }
}

function resolveDest(opts) {
  if (isAbsolute(opts.dest)) return { dest: opts.dest, root: opts.vaultRoot ? resolve(opts.vaultRoot) : null };
  const root = opts.vaultRoot ? resolve(opts.vaultRoot) : findVaultRoot(process.cwd());
  if (!root) {
    console.error("clip: vault root not found (no .obsidian in cwd ancestors); pass --vault-root or an absolute --dest");
    process.exit(2);
  }
  return { dest: resolve(root, opts.dest), root };
}

function normalizeUrl(url) {
  try {
    const u = new URL(url);
    u.hash = "";
    return u.href.replace(/\/$/, "");
  } catch {
    return url;
  }
}

function unquote(raw) {
  const v = raw.trim();
  if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
    try {
      return JSON.parse(v);
    } catch {
      return v.slice(1, -1);
    }
  }
  if (v.startsWith("'") && v.endsWith("'") && v.length >= 2) return v.slice(1, -1).replace(/''/g, "'");
  return v;
}

function splitFrontmatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/);
  if (!m) return { fm: {}, body: text };
  const fm = {};
  let listKey = null;
  for (const line of m[1].split(/\r?\n/)) {
    const item = line.match(/^\s+-\s+(.*)$/);
    if (item && listKey) {
      fm[listKey].push(unquote(item[1]));
      continue;
    }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    if (kv[2] === "") {
      fm[kv[1]] = [];
      listKey = kv[1];
    } else {
      fm[kv[1]] = unquote(kv[2]);
      listKey = null;
    }
  }
  return { fm, body: text.slice(m[0].length) };
}

function scalar(v) {
  return Array.isArray(v) ? v.filter(Boolean).join(", ") : (v ?? "");
}

function indexExisting(dest) {
  const bySource = new Map();
  if (!existsSync(dest)) return bySource;
  for (const name of readdirSync(dest)) {
    if (!name.endsWith(".md")) continue;
    const path = join(dest, name);
    const head = readFileSync(path, "utf8").slice(0, 4096);
    const source = scalar(splitFrontmatter(head).fm.source);
    if (source) bySource.set(normalizeUrl(source), path);
  }
  return bySource;
}

function sanitizeTitle(title) {
  let name = title.replace(/[\\/:*?"<>|#^[\]]/g, "").replace(/[\r\n\t]+/g, " ").trim().replace(/^\.+/, "");
  const enc = new TextEncoder();
  while (enc.encode(name).length > MAX_NAME_BYTES) name = Array.from(name).slice(0, -1).join("");
  return name.trim();
}

function fallbackName(source) {
  const u = new URL(source);
  return sanitizeTitle(`${u.hostname}${u.pathname}`.replace(/\/+/g, " ").trim());
}

function uniquePath(dest, name) {
  let path = join(dest, `${name}.md`);
  for (let n = 2; existsSync(path); n++) path = join(dest, `${name} (${n}).md`);
  return path;
}

const q = (s) => JSON.stringify(String(s));

function buildNote(fm, body, created) {
  const source = scalar(fm.source);
  const authors = (Array.isArray(fm.author) ? fm.author : fm.author ? [fm.author] : [])
    .map((a) => a.replace(/[[\]|#^]/g, "").trim())
    .filter(Boolean);
  const published = scalar(fm.published).match(/^\d{4}-\d{2}-\d{2}/)?.[0] ?? "";
  const tags = ["clippings"];
  if (X_HOSTS.has(new URL(source).hostname)) tags.push("x-post");
  const lines = [
    "---",
    `title: ${q(scalar(fm.title))}`,
    `source: ${q(source)}`,
    "author:",
    ...authors.map((a) => `  - ${q(`[[${a}]]`)}`),
    `published: ${published}`,
    `created: ${created}`,
    `description: ${q(scalar(fm.description))}`,
    "tags:",
    ...tags.map((t) => `  - ${q(t)}`),
    "---",
    "",
  ];
  return lines.join("\n") + body.replace(/^\s*\n/, "").replace(/\s*$/, "\n");
}

function today() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function runMdhq(urls, tmp) {
  return new Promise((resolveRun) => {
    const args = ["-y", MDHQ_PACKAGE, "get", "--root", join(tmp, "root"), "--no-assets", "--json", ...urls];
    const env = { ...process.env, XDG_CONFIG_HOME: join(tmp, "xdg") };
    delete env.MDHQ_ROOT;
    const child = spawn("npx", args, { env, stdio: ["ignore", "pipe", "pipe"] });
    let out = "";
    let err = "";
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (err += d));
    child.on("error", (e) => resolveRun({ results: [], stderr: `failed to launch npx: ${e.message}` }));
    child.on("close", () => {
      const results = [];
      for (const line of out.split("\n")) {
        if (!line.trim()) continue;
        try {
          results.push(JSON.parse(line));
        } catch {
          // ignore non-JSON noise
        }
      }
      resolveRun({ results, stderr: err.trim() });
    });
  });
}

function failureReason(url, stderr) {
  const lines = stderr.split("\n").filter((l) => l.includes(url));
  return (lines.length ? lines : stderr ? [stderr] : ["no result returned by mdhq"]).join(" / ");
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const { dest, root } = resolveDest(opts);
  const show = (p) => (root && p.startsWith(root + "/") ? relative(root, p) : p);
  const emit = (o) => console.log(JSON.stringify(o));
  const existing = indexExisting(dest);
  const created = today();

  const requested = [...new Set(opts.urls)];
  const pending = [];
  for (const url of requested) {
    const hit = existing.get(normalizeUrl(url));
    if (hit && !opts.update) emit({ url, status: "skipped", path: show(hit), reason: "already clipped (same source)" });
    else pending.push(url);
  }
  if (pending.length === 0) return 0;

  const tmp = await mkdtemp(join(tmpdir(), "clip-"));
  let failed = 0;
  try {
    await mkdir(join(tmp, "xdg"), { recursive: true });
    await mkdir(dest, { recursive: true });
    const { results, stderr } = await runMdhq(pending, tmp);
    const byRequested = new Map(results.map((r) => [r.requestedUrl, r]));

    for (const url of pending) {
      const r = byRequested.get(url) ?? results.find((x) => normalizeUrl(x.requestedUrl) === normalizeUrl(url));
      if (!r) {
        failed++;
        emit({ url, status: "failed", reason: failureReason(url, stderr) });
        continue;
      }
      try {
        const { fm, body } = splitFrontmatter(await readFile(join(tmp, "root", r.path), "utf8"));
        fm.source = fm.source || r.sourceUrl;
        const prior = existing.get(normalizeUrl(fm.source)) ?? existing.get(normalizeUrl(r.sourceUrl));
        if (prior && !opts.update) {
          emit({ url, status: "skipped", path: show(prior), reason: "already clipped (same source after redirect/canonical)" });
          continue;
        }
        const title = scalar(fm.title);
        const target = prior ?? uniquePath(dest, sanitizeTitle(title) || fallbackName(fm.source) || "untitled");
        const keptCreated = prior ? scalar(splitFrontmatter(readFileSync(prior, "utf8")).fm.created) : "";
        await writeFile(target, buildNote(fm, body, keptCreated || created), { flag: prior ? "w" : "wx" });
        existing.set(normalizeUrl(fm.source), target);
        emit({ url, status: prior ? "updated" : "saved", path: show(target), title });
      } catch (e) {
        failed++;
        emit({ url, status: "failed", reason: e.message });
      }
    }
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
  return failed ? 1 : 0;
}

process.exit(await main());
