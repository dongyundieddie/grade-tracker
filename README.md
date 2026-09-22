# Grade Tracker

A small macOS app for tracking grades across courses — homework, exams, quizzes,
attendance, whatever a syllabus's grading policy needs — and for figuring out
what score you still need on the remaining work to land an A, B, C, or D.

It's a single-window native app (Swift + WKWebView) that stores everything
locally in `~/Library/Application Support/GradeTracker/data.json`. Nothing is
sent over the network.

## Features

- Multiple courses, each with its own grading categories, weights, and letter
  cutoffs (e.g. A ≥ 90%, B ≥ 80%, ...).
- Per-category options: average-of-scores vs. points-based, dropping the
  lowest N items, and doubling the highest score (for syllabi like "your
  highest exam score counts twice").
- Live current grade, the mathematically lowest/highest grade still possible,
  and a simple table of the average score still needed on ungraded work to
  reach each letter grade.
- Local autosave, plus manual export/import of a JSON backup.

## Building

Requires Xcode command line tools (`swiftc`, `iconutil`, `sips`, `codesign`)
on macOS.

```bash
./build.sh
```

This builds `Grade Tracker.app` and installs it to `~/Applications`.

## Project layout

- `index.html` — the entire UI and grade-calculation logic (vanilla HTML/CSS/JS).
- `main.swift` — a thin native AppKit/WKWebView shell: window, menu bar, and a
  JS↔Swift bridge for reading/writing the local data file and file-picker
  based export/import.
- `make_icon.swift` — generates the app icon.
- `build.sh` — builds and installs the `.app` bundle.

## Data & privacy

All grade data stays on your Mac in `~/Library/Application Support/GradeTracker/data.json` (not included in this repo). A dated snapshot is kept under `.../GradeTracker/backups/` the first time you save each day.
