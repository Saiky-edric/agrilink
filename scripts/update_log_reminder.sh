#!/usr/bin/env bash
# Simple reminder script to keep logs updated.
# Usage: run manually, or wire as a git pre-commit hook.
# Example hook (~/.git/hooks/pre-commit or .git/hooks/pre-commit):
#   bash scripts/update_log_reminder.sh || true

set -euo pipefail

# Determine diff against last commit or staged changes
base_ref="${1:-HEAD}"

changed=$(git diff --name-only "$base_ref") || changed=""

need_log=false
updated_log=false

if echo "$changed" | grep -Eq '^(lib/|supabase_setup/|.*\.sql)'; then
  need_log=true
fi

if echo "$changed" | grep -Eq '^UNIVERSAL_PROJECT_STATUS.md|^CHANGELOG.md'; then
  updated_log=true
fi

if [ "$need_log" = true ] && [ "$updated_log" = false ]; then
  echo "[Reminder] You changed app/schema files but didn't update logs."
  echo "  - Please add an entry to UNIVERSAL_PROJECT_STATUS.md (Latest Updates Log)"
  echo "  - And summarize in CHANGELOG.md under [Unreleased]"
  echo "Files changed:" 
  echo "$changed" | sed 's/^/    - /'
  exit 0
fi

# Optional positive feedback
if [ "$need_log" = true ] && [ "$updated_log" = true ]; then
  echo "[OK] Changes detected and logs updated."
fi

exit 0
