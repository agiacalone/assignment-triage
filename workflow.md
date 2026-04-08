# Grading Workflow

This tool analyzes student GitHub Classroom repositories and produces a triage
spreadsheet to guide grading. It is 100% triage — no student is penalized without human review.

---

## Prerequisites

- [`gh`](https://cli.github.com/) CLI installed and authenticated (`repo`, `admin:org`, `read:org` scopes required)
- Git access to the course GitHub org
- Python 3.11+

```sh
pip install -r requirements.txt
```

---

## Files

| File | Required | Description |
|------|----------|-------------|
| `project.toml` | Yes | Assignment config and triage thresholds — one per grading run |
| `repos.txt` | Yes | One GitHub repo URL per line — generated externally |
| `roster.csv` | No | Maps GitHub usernames to real names for the output spreadsheet |

---

## Step 1 — Create the project config

Copy and edit `project.toml` for the current assignment:

```toml
[assignment]
name = "Lab 02 - Threads"
org = "csulb-cecs326"
repo_prefix = "cecs-326-sp26-01-lab-02-threads-"
assigned_date = "2026-03-24"
due_date = "2026-04-07"
expected_commits = 8

[thresholds]
pass = 65
flag = 25
```

`assigned_date` and `due_date` anchor the temporal analysis. `expected_commits` is
a rough baseline for the assignment's scope — adjust per project. Scores above
`pass` triage as PASS; scores below `flag` triage as FLAG; everything in between
is REVIEW.

---

## Step 2 — Clone repos and generate the repo list

```sh
# Clone all student repos into ./<assignment-slug>-submissions/
gh classroom clone student-repos -a <assignment_id> --per-page 100

# Generate repos.txt from the cloned repos
find <assignment-slug>-submissions -maxdepth 1 -mindepth 1 -type d \
  -exec git -C {} remote get-url origin \; > repos.txt
```

The `--per-page 100` flag matters — the default of 15 silently misses students in
larger sections. The assignment ID is visible in the GitHub Classroom web UI or via:

```sh
gh classroom assignments --classroom-id <classroom_id>
```

Since repos are already on disk after this step, pass `--skip-clone` to the grader
in Step 4.

---

## Step 3 — (Optional) Prepare the roster

`roster.csv` maps GitHub usernames to real names in the output. If omitted,
GitHub usernames appear in the `name` column instead.

```csv
github_username,display_name
student-github-id,Jane Doe
jsmith42,Jamie Smith
tnguyen,Tran Nguyen
```

---

## Step 4 — Run the tool

```sh
grader --config project.toml --repos repos.txt [--roster roster.csv] --skip-clone
```

The tool will:

1. With `--skip-clone`, use the repos already cloned in Step 2 as-is. Without it,
   the tool clones each URL from `repos.txt` into a `repos/` subdirectory (or pulls
   if already present).
2. Analyze each repo's git history for authenticity signals.
3. Score each repo (0–100) and assign a triage bucket.
4. Write `results.csv` to the current directory.

---

## Step 5 — Review the output

Open `results.csv` in LibreOffice Calc. Rows are sorted by triage bucket:

| Bucket | Meaning | Action |
|--------|---------|--------|
| `FLAG` | Low authenticity score — likely not genuine work | Human review required before any grade decision |
| `REVIEW` | Mixed or inconclusive signals | Grade manually using the reasoning column as context |
| `PASS` | Strong authenticity signals | Confirm and assign grade |

The `reasoning` column contains plain-English evidence for each triage decision,
citing concrete measurements (e.g., *"94% of insertions in one commit; zero
deletions across history; all commits within 73 minutes"*). Use this to inform
review, not to replace it.

The `grade` column is pre-populated with a suggested value based on triage and
score. The instructor owns the final grade.

---

## Repeat runs

Re-running the tool on the same directory pulls the latest commits for any already-
cloned repos before re-analyzing. Useful if students push late amendments or if
thresholds need adjustment — edit `project.toml` and re-run; `results.csv` is
overwritten.
