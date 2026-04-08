# Student Repository Analysis Commands

Git commands for evaluating student commit habits and work quality.
Run these inside a cloned student submission repo.

See the [Batch Analysis](#batch-analysis) section at the bottom for running these
across an entire assignment's worth of GitHub Classroom repos at once.

---

## Commit Count

Total number of commits — a basic effort signal.
```sh
git rev-list --count HEAD
```

---

## Work Timeline

Shows each commit's date and message. Reveals whether the student worked
incrementally or crammed everything at the end.
```sh
git log --format='%ad  %s' --date=format:'%Y-%m-%d %H:%M'
```

---

## Daily Commit Distribution

Commit counts per calendar day — spot steady progress vs. last-minute surges.
```sh
git log --format='%ad' --date=format:'%Y-%m-%d' | sort | uniq -c | sort -k2
```

---

## Hour-of-Day Pattern

Shows what hours of the day the student commits. Useful for spotting all-nighters
or suspiciously uniform timestamps.
```sh
git log --format='%ad' --date=format:'%H' | sort | uniq -c | sort -k2 -n
```

---

## Commit Message Quality

Lists all commit messages sorted by character length (shortest first).
Low-quality messages like "fix", "wip", "done", "update", "asdf" appear at the top.
```sh
git log --format='%s' | awk '{ print length, $0 }' | sort -n
```

Grep for low-effort message patterns specifically:
```sh
git log --format='%s' | grep -iE '^(wip|fix|update|changes|stuff|asdf|test|commit|done|final|more|misc|stuff|lol|idk|a+|\.+)$'
```

---

## Commit Size (Files and Lines Changed)

Prints each commit with its stats — large single-commit line counts may indicate
a code dump rather than incremental development.
```sh
git log --stat --format='%ncommit %h  %ad  %s' --date=format:'%Y-%m-%d %H:%M'
```

Average files changed per commit:
```sh
git log --shortstat --format='' | grep 'files\? changed' \
  | awk '{ f+=$1; i+=$4; d+=$6; n++ } END { printf "commits: %d\navg files/commit: %.1f\navg insertions: %.1f\navg deletions: %.1f\n", n, f/n, i/n, d/n }'
```

---

## First and Last Commit

Useful for checking whether work started promptly after the assignment was issued
and when the final push came in relative to the deadline.
```sh
echo "First commit:"; git log --format='%ad  %s' --date=format:'%Y-%m-%d %H:%M' | tail -1
echo "Last commit: "; git log --format='%ad  %s' --date=format:'%Y-%m-%d %H:%M' | head -1
```

---

## Suspiciously Large Additions

Lists commits that inserted an unusually high number of lines — may indicate
copy-paste or code added all at once rather than written incrementally.
```sh
git log --shortstat --format='%h %ad %s' --date=format:'%Y-%m-%d' \
  | paste - - - \
  | awk -F'\t' '{ split($2,s," "); if (s[4]+0 > 100) print $1 "\t" $2 }'
```

---

## Merge / Revert Patterns

Checks for signs of merge conflicts, reverts, or desperation commits.
```sh
git log --oneline | grep -iE 'merge conflict|revert|undo|oops|mistake|wrong|broken|fix fix'
```

---

## Branch History

Shows all branches, including deleted remote-tracking ones — reveals whether the
student used feature branches or committed everything straight to main.
```sh
git log --oneline --graph --decorate --all
```

---

## Co-author / Collaboration Check

For group assignments — confirms each contributor's commit share.
```sh
git shortlog -sn --no-merges
```

---

## Batch Analysis

Run a summary across all repos for a given assignment. Repos are assumed to be
already cloned into a common directory (one subdirectory per student).

GitHub Classroom repos follow the convention:
`cecs-[course]-[semester]-[section]-[type]-[number]-[name]-[github_id]`

### Clone All Repos for an Assignment

Requires the `gh` CLI. Replace the pattern with the actual assignment prefix.

```sh
# List all matching repos in your org, then clone each one
ASSIGNMENT="cecs-326-sp26-01-lab-01-threads"
ORG="your-github-org"

gh repo list "$ORG" --limit 200 --json name --jq '.[].name' \
  | grep "^${ASSIGNMENT}-" \
  | xargs -I{} gh repo clone "$ORG/{}" -- --quiet
```

### Summary Table

Prints a one-line summary per student: commit count, first commit date, last commit
date, and whether any low-effort commit messages were found.

```sh
for repo in */; do
  [ -d "$repo/.git" ] || continue
  name=$(basename "$repo")
  count=$(git -C "$repo" rev-list --count HEAD 2>/dev/null)
  first=$(git -C "$repo" log --format='%ad' --date=format:'%Y-%m-%d' | tail -1)
  last=$(git -C "$repo"  log --format='%ad' --date=format:'%Y-%m-%d' | head -1)
  lazy=$(git -C "$repo" log --format='%s' \
    | grep -icE '^(wip|fix|update|changes|stuff|asdf|test|commit|done|final|more|misc|lol|idk|a+|\.*)')
  printf "%-60s  commits=%-4s  first=%-10s  last=%-10s  lazy_msgs=%s\n" \
    "$name" "$count" "$first" "$last" "$lazy"
done
```

### Flag Last-Minute Submitters

Prints repos where the last commit falls on or after a given deadline date.
Set `DEADLINE` to the assignment due date.

```sh
DEADLINE="2026-04-10"
for repo in */; do
  [ -d "$repo/.git" ] || continue
  last=$(git -C "$repo" log -1 --format='%ad' --date=format:'%Y-%m-%d' 2>/dev/null)
  [[ "$last" > "$DEADLINE" || "$last" == "$DEADLINE" ]] \
    && echo "$(basename $repo)  last_commit=$last"
done
```

### Flag Large Single-Commit Repos

Prints repos where more than 80% of total insertions landed in a single commit —
a strong indicator of a code dump.

```sh
for repo in */; do
  [ -d "$repo/.git" ] || continue
  total=$(git -C "$repo" log --shortstat --format='' \
    | awk '/insertion/ { sum += $4 } END { print sum+0 }')
  max=$(git -C "$repo" log --shortstat --format='' \
    | awk '/insertion/ { print $4+0 }' | sort -n | tail -1)
  [ "${total:-0}" -eq 0 ] && continue
  pct=$(( max * 100 / total ))
  [ "$pct" -ge 80 ] \
    && printf "%-60s  max_commit=%d%%  (%d of %d insertions)\n" \
       "$(basename $repo)" "$pct" "$max" "$total"
done
```
