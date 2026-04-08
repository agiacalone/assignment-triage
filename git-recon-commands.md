# Git Commands Before Reading Code

Source: https://piechowski.io/post/git-commands-before-reading-code/

## Churn Hotspots
Identifies the 20 most frequently modified files over the past year.
```sh
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

## Contributor Analysis
Ranks contributors by commit count. Add `--since="6 months ago"` to check recent activity.
```sh
git shortlog -sn --no-merges
git shortlog -sn --no-merges --since="6 months ago"
```

## Bug Clustering
Maps defect density by filtering commits for bug-related keywords.
```sh
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

## Project Velocity
Shows monthly commit counts across the repo's entire history.
```sh
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

## Firefighting Frequency
Detects revert and emergency fix patterns over the past year.
```sh
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```
