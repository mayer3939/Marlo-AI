#!/usr/bin/env bash
# Validate Claude Code skill/agent YAML frontmatter.
# Usage: check-frontmatter.sh <path-to-md-file>
set -euo pipefail
python3 -c "
import sys, re, yaml
p = sys.argv[1]
t = open(p).read()
m = re.match(r'^---\n(.*?)\n---', t, re.DOTALL)
assert m, f'{p}: no frontmatter block'
fm = yaml.safe_load(m.group(1))
assert isinstance(fm, dict), f'{p}: frontmatter is not a mapping'
assert 'name' in fm, f'{p}: missing name'
assert 'description' in fm, f'{p}: missing description'
print(f'OK {p} — name={fm[\"name\"]}')
" "$1"
