# assignment-triage

Git-based authenticity triage for student GitHub Classroom submissions.

Analyzes commit history to distinguish genuine student work from LLM-generated
submissions. Outputs a color-coded spreadsheet, Markdown report, and machine-readable
CSV — sorted by triage bucket so you can work through the suspicious ones first.

**This tool is 100% triage.** No student is penalized without human review.

---

## How it works

Each repo is scored 0–100 based on behavioral signals that are hard to fake:
commit spread over time, irregular intervals, presence of deletions (code was
revised), file churn across sessions, and absence of paste-then-cleanup patterns.
Bot commits (GitHub Classroom setup) are excluded automatically.

Scores map to three buckets configured per assignment:

| Bucket | Meaning |
|--------|---------|
| `FLAG` | Low authenticity — review before grading |
| `REVIEW` | Inconclusive — grade manually using the reasoning |
| `PASS` | Strong authenticity signals — confirm and grade |

---

## Setup

```sh
pip install -r requirements.txt
```

Requires Python 3.11+ and the `gh` CLI with the GitHub Classroom extension.

Install `gh` if not already present (Fedora/RHEL):
```sh
sudo dnf install gh
```

Install the Classroom extension (once — it persists across sessions) and authenticate:
```sh
gh extension install github/gh-classroom
gh auth login --hostname github.com
gh auth refresh --hostname github.com -s repo,admin:org,read:org
```

The `admin:org` and `read:org` scopes are required — without them the Classroom
API returns empty results with no error.

---

## Quickstart

**1. Create a run directory for the assignment:**
```sh
mkdir runs/cecs-326-sp26-01-lab-02 && cd runs/cecs-326-sp26-01-lab-02
```

**2. Copy and edit the appropriate template:**
```sh
cp ../../templates/single-sitting.toml project.toml
# edit project.toml: set name, org, repo_prefix, assigned_date, due_date, total_points
```

**3. Clone student repos and generate `repos.txt`:**

First, find the assignment ID:
```sh
gh classroom list                                      # shows classroom IDs
gh classroom assignments --classroom-id <classroom_id> # shows assignment IDs
```

Then clone and generate the URL list:
```sh
# Clone all student repos — creates a <assignment-slug>-submissions/ directory
# Replace 943146 with your assignment ID from the step above
gh classroom clone student-repos -a 943146 --per-page 100

# Extract each repo's remote URL into repos.txt (one URL per line)
find *-submissions -maxdepth 1 -mindepth 1 -type d \
  -exec git -C {} remote get-url origin \; > repos.txt
```

**4. Run the grader:**
```sh
python3 ../../grader.py --config project.toml --repos repos.txt --skip-clone
```

**5. Open `results.xlsx`** in LibreOffice Calc. Rows are sorted FLAG → REVIEW → PASS.
The `reasoning` column explains every score in plain English.

---

## Templates

Pick the template that matches the assignment type:

| Template | Use case |
|----------|---------|
| `single-sitting.toml` | Short assignment available over days but done in one session |
| `short-project.toml` | 3–4 week project; weekend burst work is normal |
| `term-project.toml` | Full-semester project; expects commits spread over months |

Key config values to set per assignment:

```toml
[assignment]
assignment_id = 0
name          = "Lab 02 - Semaphores"
org           = "your-github-org"
repo_prefix   = "cecs-326-sp26-01-lab-02-semaphores-"
assigned_date = "2026-03-24"
due_date      = "2026-04-07"
expected_commits = 6
total_points  = 100

[thresholds]
pass = 45   # score >= pass → PASS
flag = 15   # score <= flag → FLAG
```

Weights can be tuned in `[weights]` — see the template for defaults and the
`scoring-design.md` for the rationale behind each signal.

---

## Outputs

All three are written to the run directory on every run:

| File | Purpose |
|------|---------|
| `results.csv` | Machine-readable, one row per student |
| `results.xlsx` | Color-coded spreadsheet with pie chart (open in LibreOffice Calc) |
| `results.md` | Markdown report for terminal viewing |

Students with no commits are automatically graded `0/total_points`.
All other grade cells are left blank for manual entry.

---

## Roster (optional)

To show real names instead of GitHub usernames, create `roster.csv`:

```csv
github_username,display_name
student-github-id,Jane Doe
jsmith42,Jamie Smith
```

Pass it with `--roster roster.csv`.

---

## Directory layout

```
assignment-triage/
├── grader.py              # main script
├── requirements.txt
├── templates/
│   ├── single-sitting.toml
│   ├── short-project.toml
│   └── term-project.toml
├── scoring-design.md      # signal design and rationale
├── workflow.md            # full step-by-step workflow
├── student-repo-analysis.md  # manual per-repo git commands
└── runs/                  # gitignored — one subdir per grading run
    └── cecs-326-sp26-01-lab-01/
        ├── project.toml
        ├── repos.txt
        ├── results.csv
        ├── results.xlsx
        └── results.md
```
