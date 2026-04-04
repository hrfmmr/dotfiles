# Tight Loop Detection (Heuristics)

Goal: run at least one fast, relevant signal before committing. Prefer the smallest loop that still verifies the change.

## Selection Order
1. Project-provided task runner (Make)
2. Language-native test runner
3. Lint / typecheck / static analysis
4. Minimal runtime log or smoke check

## Task Runners (fastest wins)
- Makefile: look for `test`, `check`, and `lint`, then run `make <target>`.

## When in doubt
- Prefer the smallest signal that verifies the change.
- If the command is unclear or risky, ask the user for the preferred check.
