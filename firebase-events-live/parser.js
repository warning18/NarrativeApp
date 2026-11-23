'use strict';
// Parses Firebase Analytics debug lines from logcat (tags FA / FA-SVC).
const PARAM_SPLIT = /, (?=[A-Za-z_]\w*(?:\(\w+\))?=)/;

function parseBundle(text) {
  const m = text.match(/Bundle\[\{([\s\S]*)\}\]/);
  const params = {};
  if (!m || !m[1].trim()) return params;
  for (const part of m[1].split(PARAM_SPLIT)) {
    const i = part.indexOf('=');
    if (i < 0) continue;
    const key = part.slice(0, i).replace(/\(\w+\)$/, '');
    params[key] = part.slice(i + 1);
  }
  return params;
}

function stripShort(name) { return name.replace(/\(\w+\)$/, '').trim(); }

// Returns {time, name, params, kind} or null.
function parseLine(line) {
  const t = line.match(/^(\d\d-\d\d \d\d:\d\d:\d\d\.\d+)/);
  const time = t ? t[1] : '';
  let m = line.match(/Logging event(?: \(FE\))?: (?:origin=\w+,)?(?:name=)?([^,\s]+?(?:\(\w+\))?)(?:,\s*(?:params=)?)(Bundle\[.*)$/);
  if (m) return { time, kind: 'event', name: stripShort(m[1]), params: parseBundle(m[2]) };
  m = line.match(/Setting user property(?: \(FE\))?: ([^,]+), (.*)$/);
  if (m) return { time, kind: 'user_property', name: stripShort(m[1]), params: { value: m[2].trim() } };
  return null;
}

module.exports = { parseLine, parseBundle };
