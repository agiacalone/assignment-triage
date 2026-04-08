#!/usr/bin/env bash
# triage.sh — full assignment triage workflow
#
# Usage:
#   ./triage.sh <run-directory>
#
# <run-directory> must contain a project.toml with assignment_id set.
# All output (repos/, repos.txt, results.*) is written there.
#
# Example:
#   ./triage.sh runs/cecs-326-sp26-01-lab-02

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Args -------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "usage: $(basename "$0") <run-directory>" >&2
    exit 1
fi

RUN_DIR="$(cd "$1" && pwd)"
CONFIG="$RUN_DIR/project.toml"

if [[ ! -f "$CONFIG" ]]; then
    echo "error: no project.toml found in $RUN_DIR" >&2
    exit 1
fi

# --- Parse config -----------------------------------------------------------

toml_get() {
    # Extract value from [assignment] section only
    awk -F'=' "/^\[/{section=\$0} section==\"[assignment]\" && /^$1\s*=/{gsub(/^\s*\"|\"\\s*$/,\"\",\$2); gsub(/^\s+|\s+$/,\"\",\$2); print \$2; exit}" "$CONFIG"
}

assignment_id=$(toml_get assignment_id)
assignment_name=$(toml_get name)

if [[ -z "$assignment_id" || "$assignment_id" == "0" ]]; then
    echo "error: assignment_id not set in $CONFIG" >&2
    exit 1
fi

# --- Clone ------------------------------------------------------------------

echo "==> $assignment_name (id: $assignment_id)"
echo ""

cd "$RUN_DIR"

if compgen -G "*-submissions" > /dev/null 2>&1; then
    echo "--- Updating existing clones ---"
    for repo in *-submissions/*/; do
        [[ -d "$repo/.git" ]] || continue
        printf "  pulling %-50s" "$(basename "$repo")..."
        git -C "$repo" pull --quiet && echo "ok" || echo "FAILED"
    done
else
    echo "--- Cloning student repos ---"
    gh classroom clone student-repos -a "$assignment_id" --per-page 100
fi

# --- Generate repos.txt -----------------------------------------------------

echo ""
echo "--- Generating repos.txt ---"
find *-submissions -maxdepth 1 -mindepth 1 -type d \
    -exec git -C {} remote get-url origin \; > repos.txt
echo "  $(wc -l < repos.txt) repos found"

# --- Run grader -------------------------------------------------------------

echo ""
echo "--- Running grader ---"
python3 "$SCRIPT_DIR/grader.py" \
    --config "$CONFIG" \
    --repos  "$RUN_DIR/repos.txt" \
    --skip-clone \
    --output "$RUN_DIR/results.csv"
