#!/usr/bin/env bash
# Publish the learnings page to BOTH GitHub and learnings.feedos.si.
# Usage: ./publish.sh "commit message"
#   1. commits + pushes index.html to github.com/liyue2055/clover-learnings
#   2. uploads index.html to Vercel and creates a production deployment
#      (the custom domain learnings.feedos.si follows the production deployment)
set -euo pipefail

REPO="$HOME/workspace/clover-learnings"
cd "$REPO"

MSG="${1:-Update learnings page}"

if git diff --quiet && git diff --cached --quiet; then
    echo "No content changes to publish."
else
    git add -A
    git commit -m "$MSG"
    git push origin HEAD
    echo "Pushed to GitHub."
fi

python3 - <<'EOF'
import base64, hashlib, json, subprocess, sys

raw = open('/home/hatch/workspace/clover-learnings/index.html', 'rb').read()
sha1 = hashlib.sha1(raw).hexdigest()
size = len(raw)
b64 = base64.b64encode(raw).decode()

def call(name, args):
    p = subprocess.run(
        ["/opt/hatch/bin/vercel", "call-tool", "--name", name,
         "--arguments-json", json.dumps(args)],
        capture_output=True, text=True, timeout=180)
    return json.loads(p.stdout)

up = call("upload_file", {
    "requestBody": b64, "xVercelDigest": sha1, "contentLength": size})
if not up.get("ok"):
    sys.exit(f"upload failed: {json.dumps(up)[:300]}")

dep = call("create_deployment", {
    "forceNew": "1",
    "requestBody": {
        "name": "clover-learnings",
        "project": "clover-learnings",
        "target": "production",
        "projectSettings": {"framework": None},
        "files": [{"file": "index.html", "sha": sha1, "size": size}],
    }})
res = dep.get("result", {})
text = res.get("content", [{}])[0].get("text", "") if isinstance(res, dict) else ""
try:
    info = json.loads(text)["result"]["deployment"]
    print("Deployed:", info["state"], "|", "https://learnings.feedos.si")
except Exception:
    sys.exit(f"deploy failed: {text[:400]}")
EOF
