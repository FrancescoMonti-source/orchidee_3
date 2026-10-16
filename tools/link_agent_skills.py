#!/usr/bin/env python3
"""Verify vendored skill files and create repository-local discovery links."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify without creating links")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    root = repo / "skills"
    manifest = json.loads((root / "source.json").read_text(encoding="utf-8"))
    names = manifest["selected"] + manifest["helpers"]
    if len(set(names)) != len(names):
        parser.error("duplicate skill names in source.json")

    for item in manifest["files"]:
        source = (root / item["local_path"]).resolve()
        if not source.is_relative_to(root):
            parser.error("skill file points outside skills/: " + item["local_path"])
        data = source.read_bytes()
        digest = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if digest != item["git_blob_sha"]:
            parser.error("upstream file changed: " + item["local_path"])

    links = []
    for name in names:
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
            parser.error("invalid skill name: " + name)
        target = root / name
        text = (target / "SKILL.md").read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            parser.error("missing skill frontmatter: " + name)
        frontmatter = text.split("---\n", 2)[1]
        if not re.search(r"^name: " + re.escape(name) + r"$", frontmatter, re.M):
            parser.error("skill name disagrees with directory: " + name)
        if not re.search(r"^description: .+", frontmatter, re.M):
            parser.error("missing description: " + name)
        if re.search(r"^disable-model-invocation: true$", frontmatter, re.M):
            policy = (target / "agents/openai.yaml").read_text(encoding="utf-8")
            if "allow_implicit_invocation: false" not in policy:
                parser.error("missing explicit-invocation policy: " + name)
        link = repo / ".agents/skills" / name
        if link.is_symlink():
            if link.resolve() != target:
                parser.error("conflicting discovery link: " + str(link))
        elif link.exists():
            parser.error("conflicting discovery directory: " + str(link))
        elif args.check:
            parser.error("missing discovery link: " + str(link))
        else:
            links.append((link, target))

    for link, target in links:
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(os.path.relpath(target, link.parent), target_is_directory=True)
    print(f"Verified {len(names)} skills; " + ("discovery links checked." if args.check else f"created {len(links)} discovery links."))


if __name__ == "__main__":
    main()
