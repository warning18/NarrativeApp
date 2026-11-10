#!/usr/bin/env python3
"""A tiny client for the PixelLab MCP server (https://api.pixellab.ai/mcp), for
sessions that cannot (or should not) run `claude mcp add`.

The key never lives in the repo or in this file. In a cloud session the network
proxy injects the user's saved credential for api.pixellab.ai (saved once with
request_credential), so the default header value below is a placeholder. Locally
set PIXELLAB_API_KEY.

  python3 tool/pixellab_client.py tools                      # list tool names
  python3 tool/pixellab_client.py help <tool>                # a tool's reference (free)
  python3 tool/pixellab_client.py call <tool> '<json args>' [--save DIR]
  python3 tool/pixellab_client.py wait [N]                   # wait for N running jobs

`call` prints the tool's text and, with --save DIR, writes every inline image
(DIR/<tool>_<n>.png). Image files hosted on backblaze.pixellab.ai are not
reachable from a locked-down network; the tools return images inline instead, and
character zips come from https://api.pixellab.ai/mcp/characters/<id>/download.
Costs: each generation tool states its cost in generations; read it first
(`help <tool>`), check `call get_balance '{}'`, and ask the user before big batches.
"""
import base64, json, os, subprocess, sys

URL = "https://api.pixellab.ai/mcp"
KEY = os.environ.get("PIXELLAB_API_KEY", "placeholder")


def _post(body, sid=None):
    cmd = ["curl", "-sS", "-i", "-m", "120", "-X", "POST", URL,
           "-H", "Authorization: Bearer " + KEY,
           "-H", "Content-Type: application/json",
           "-H", "Accept: application/json, text/event-stream"]
    if sid:
        cmd += ["-H", "mcp-session-id: " + sid]
    cmd += ["-d", json.dumps(body)]
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def _messages(raw):
    out = []
    for line in raw.splitlines():
        line = line.strip()
        if line.startswith("data: "):
            line = line[6:]
        if line.startswith("{"):
            try:
                out.append(json.loads(line))
            except ValueError:
                pass
    return out


def call(name, args=None):
    raw = _post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
        "protocolVersion": "2025-03-26", "capabilities": {},
        "clientInfo": {"name": "pixellab_client", "version": "1"}}})
    sid = next((l.split(":", 1)[1].strip() for l in raw.splitlines()
                if l.lower().startswith("mcp-session-id")), None)
    _post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
    raw = _post({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
                 "params": {"name": name, "arguments": args or {}}}, sid)
    for m in _messages(raw):
        if m.get("id") == 2:
            return m.get("result") or {"error": m.get("error")}
    return {"error": "no answer: " + raw[:300]}


def list_tools():
    raw = _post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
        "protocolVersion": "2025-03-26", "capabilities": {},
        "clientInfo": {"name": "pixellab_client", "version": "1"}}})
    sid = next((l.split(":", 1)[1].strip() for l in raw.splitlines()
                if l.lower().startswith("mcp-session-id")), None)
    _post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
    raw = _post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid)
    for m in _messages(raw):
        if m.get("id") == 2:
            return m["result"]["tools"]
    return []


def text_of(res):
    return "".join(c.get("text", "") for c in res.get("content", []) if c.get("type") == "text")


def save_images(res, folder, stem):
    os.makedirs(folder, exist_ok=True)
    paths = []
    for n, c in enumerate(x for x in res.get("content", []) if x.get("type") == "image"):
        p = os.path.join(folder, "%s_%d.png" % (stem, n))
        with open(p, "wb") as f:
            f.write(base64.b64decode(c["data"]))
        paths.append(p)
    return paths


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "tools":
        for t in list_tools():
            print("-", t["name"], ":", (t.get("description") or "")[:100].replace("\n", " "))
    elif cmd == "help":
        print(text_of(call("search_help", {"tool": argv[2]})))
    elif cmd == "wait":
        print(text_of(call("wait_for_jobs", {"min_finished": int(argv[2]) if len(argv) > 2 else 1,
                                             "timeout_seconds": 120})))
    elif cmd == "call":
        args = json.loads(argv[3]) if len(argv) > 3 and not argv[3].startswith("--") else {}
        res = call(argv[2], args)
        print(text_of(res) or res)
        if "--save" in argv:
            folder = argv[argv.index("--save") + 1]
            for p in save_images(res, folder, argv[2]):
                print("saved", p)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
