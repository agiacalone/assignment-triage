# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a reference repository containing curated `git` commands for codebase reconnaissance — useful when onboarding to an unfamiliar repo. The canonical content lives in `git-recon-commands.md`.

There is no build system, test suite, or source code — the repo is documentation only.

## Content Structure

`git-recon-commands.md` is organized into five analysis categories:

| Section | Purpose |
|---------|---------|
| Churn Hotspots | Files changed most frequently (past year) |
| Contributor Analysis | Ranked commit counts by author |
| Bug Clustering | Files associated with fix/bug commits |
| Project Velocity | Monthly commit counts across history |
| Firefighting Frequency | Revert/hotfix/emergency patterns |

Each section provides a shell command snippet intended to be run inside any git repository under analysis.
