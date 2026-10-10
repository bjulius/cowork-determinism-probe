"""Total a trial balance by account type with exact decimal arithmetic, write a summary CSV and print its SHA-256.

Same input -> byte-identical output -> same hash, on every run and every machine. Standard library only.
"""
import csv
import hashlib
import io
import logging
import sys
from collections import defaultdict
from decimal import Decimal
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s", stream=sys.stderr)
HERE = Path(__file__).resolve().parent.parent

src = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "assets" / "trial_balance.csv"
out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()
logging.info("Reading %s", src)

totals = defaultdict(lambda: [Decimal("0"), Decimal("0")])
with open(src, newline="", encoding="utf-8") as f:
    rows = [r for r in csv.DictReader(f) if not r["account"].startswith("#")]
for r in rows:
    totals[r["type"]][0] += Decimal(r["debit"] or "0")
    totals[r["type"]][1] += Decimal(r["credit"] or "0")

buf = io.StringIO()
w = csv.writer(buf, lineterminator="\n")
w.writerow(["type", "debit", "credit", "net"])
for t in sorted(totals):
    d, c = totals[t]
    w.writerow([t, f"{d:.2f}", f"{c:.2f}", f"{d - c:.2f}"])
total_d = sum(v[0] for v in totals.values())
total_c = sum(v[1] for v in totals.values())
w.writerow(["TOTAL", f"{total_d:.2f}", f"{total_c:.2f}", f"{total_d - total_c:.2f}"])
data = buf.getvalue().encode("utf-8")

out = out_dir / "tb_summary.csv"
out.write_bytes(data)
logging.info("Wrote %s", out)

print(buf.getvalue(), end="")
print(f"rows read: {len(rows)}")
print(f"balanced: {total_d == total_c}")
print(f"sha256(tb_summary.csv): {hashlib.sha256(data).hexdigest()}")
