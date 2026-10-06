#!/bin/sh
# Regenerate every game's sources from the ROMs in the parent folder (AA).
cd "$(dirname "$0")"
for g in carm casperu caspere chicken gng dukes xgb cmr pinball; do
  d=$(python3 -c "import sys; sys.path.insert(0,'tools'); from qtgen import NAMES; print(NAMES['$g'])")
  python3 tools/qtgen.py $g $d >/dev/null
  if [ $g = cmr ]; then python3 tools/cmrpcm.py $d; python3 tools/cmrirq.py $d; fi
done
