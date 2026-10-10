---
name: reconcile-tb
description: >
  This skill should be used when the user asks to "reconcile the trial balance",
  "run reconcile-tb", or "run the determinism probe script". It totals a trial
  balance CSV with a bundled script so the numbers come from code, not the model.
---

# Reconcile trial balance

1. Run the bundled script with Python 3. It sits at `scripts/reconcile.py` in this skill's base directory:
   `python3 <skill-dir>/scripts/reconcile.py [csv-path] [output-dir]` (on Windows, if `python3` is missing, use `py` in its place)
   - With no arguments it reads the bundled test fixture `assets/trial_balance.csv` and writes to the current working directory.
   - If the user names a CSV, pass its path. It needs the columns `account,type,debit,credit`.
2. Do NOT compute, round or restate any total yourself. Paste the script's stdout to the user verbatim, inside a code block.
3. If the script fails or Python is unavailable, report the exact error text and stop. Do not fall back to calculating the totals yourself.
