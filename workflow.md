# Grading Workflow

This tool analyzes student GitHub Classroom repositories and produces a triage
spreadsheet to guide grading. It is 100% triage — no student is penalized without human review.

---

## Prerequisites

- [`gh`](https://cli.github.com/) CLI installed and authenticated (`repo`, `admin:org`, `read:org` scopes required)
- GitHub Classroom extension for `gh` (one-time install):
  ```sh
  gh extension install github/gh-classroom
  ```
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
| `roster.csv` | No | Maps GitHub usernames to real names for the output spreadsheet |

---

## Step 1 — Create the run directory and config

```sh
mkdir runs/cecs-326-sp26-01-lab-02
cp templates/short-project.toml runs/cecs-326-sp26-01-lab-02/project.toml
```

Edit `project.toml` and fill in the assignment details:

```toml
[assignment]
assignment_id = 943146
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

To find the assignment ID:
```sh
gh classroom list                                       # shows classroom IDs
gh classroom assignments --classroom-id <classroom_id>  # shows assignment IDs
```

`assigned_date` and `due_date` anchor the temporal analysis. `expected_commits` is
a rough baseline for the assignment's scope — adjust per project. Scores above
`pass` triage as PASS; scores below `flag` triage as FLAG; everything in between
is REVIEW.

---

## Step 2 — (Optional) Prepare the roster

`roster.csv` maps GitHub usernames to real names in the output. If omitted,
GitHub usernames appear in the `name` column instead.

```csv
github_username,display_name
student-github-id,Jane Doe
jsmith42,Jamie Smith
tnguyen,Tran Nguyen
```

---

## Step 3 — Run

```sh
./triage.sh runs/cecs-326-sp26-01-lab-02
```

This clones all student repos, generates `repos.txt`, and runs the grader in one step.
Re-running the same command pulls the latest commits instead of re-cloning.

---

## Step 4 — Review the output

Open `results.xlsx` in LibreOffice Calc. Rows are sorted by triage bucket:

| Bucket | Meaning | Action |
|--------|---------|--------|
| `FLAG` | Low authenticity score — likely not genuine work | Human review required before any grade decision |
| `REVIEW` | Mixed or inconclusive signals | Grade manually using the reasoning column as context |
| `PASS` | Strong authenticity signals | Confirm and assign grade |

The `reasoning` column contains plain-English evidence for each triage decision,
citing concrete measurements (e.g., *"94% of insertions in one commit; zero
deletions across history; all commits within 73 minutes"*). Use this to inform
review, not to replace it.

`results.csv` and `results.md` are also written alongside the spreadsheet.

---

## Repeat runs

Edit `project.toml` to adjust thresholds or weights, then re-run `triage.sh`.
Repos are pulled (not re-cloned), and all result files are overwritten.
