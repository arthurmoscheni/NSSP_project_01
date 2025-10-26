

#!/usr/bin/env bash
set -euo pipefail
source ./00_config.sh

for f in 00_config.sh 03_struct_fast.sh 04_coreg_bbr.sh; do
  [[ -f "$f" ]] && sed -i 's/\r$//' "$f" || true
done

# Find epi_reg explicitly
if ! command -v epi_reg >/dev/null 2>&1; then
  if [[ -n "${FSLDIR:-}" && -x "${FSLDIR}/bin/epi_reg" ]]; then
    PATH="${FSLDIR}/bin:$PATH"
  else
    echo "ERROR: epi_reg not found" >&2; exit 1
  fi
fi


idx="${COREG_RUN_INDEX//$'\r'/}"
[[ "$idx" =~ ^[0-9]+$ ]] || idx=0
(( idx < ${#RUNS[@]} )) || idx=0
coreg_run="${RUNS[$idx]}"


base="${coreg_run##*/}"; base="${base%.nii.gz}"; base="${base%.nii}"
coreg_dir="${OUTDIR}/${base}.pre"
func_mean="${coreg_dir}/${base}_mean.nii.gz"

# Sanity checks
[[ -f "$func_mean" ]] || { echo "ERROR: missing mean EPI: $func_mean (run 01_preproc_runs.sh)"; exit 1; }
[[ -f "$T1_BRAIN"  ]] || { echo "ERROR: missing T1 brain: $T1_BRAIN"; exit 1; }
T1_DIR="$(dirname "$T1_BRAIN")"
T1_HEAD_CAND="${T1_BRAIN/_brain.nii.gz/.nii.gz}"
T1_HEAD="$T1_HEAD_CAND"; [[ -f "$T1_HEAD" ]] || T1_HEAD="$T1_BRAIN"
WMSEG="${T1_DIR}/T1w_wmseg.nii.gz"
[[ -f "$WMSEG" ]] || { echo "ERROR: WM seg missing: $WMSEG (run 03_struct_fast.sh)"; exit 1; }


abs() { readlink -f "$1"; }
EPI="$(abs "$func_mean")"
T1="$(abs "$T1_HEAD")"
T1B="$(abs "$T1_BRAIN")"
WM="$(abs "$WMSEG")"
OUTBASE="$(abs "$coreg_dir")/func2t1_bbr"

echo "epi_reg inputs:"
printf "  --epi=%s\n  --t1=%s\n  --t1brain=%s\n  --wmseg=%s\n  --out=%s\n" "$EPI" "$T1" "$T1B" "$WM" "$OUTBASE"

cmd=(epi_reg --epi="$EPI" --t1="$T1" --t1brain="$T1B" --wmseg="$WM" --out="$OUTBASE")
printf "RUN: "; printf '%q ' "${cmd[@]}"; echo
if ! "${cmd[@]}"; then
  echo "WARN: epi_reg failed — falling back to FLIRT+BBR directly."

  # FLIRT
  [[ -n "${FSLDIR:-}" && -f "${FSLDIR}/etc/flirtsch/bbr.sch" ]] || { echo "ERROR: bbr.sch not found"; exit 1; }
  flirt -in "$EPI" -ref "$T1B" -dof 6 -cost bbr -wmseg "$WM" \
        -schedule "${FSLDIR}/etc/flirtsch/bbr.sch" \
        -omat "${OUTBASE}.mat" -out "${OUTBASE}.nii.gz"
fi

fslmaths "${OUTBASE}.nii.gz" -edge -bin "${OUTBASE/_bbr/_edges_bbr}.nii.gz"

echo "Done:"
echo "  ${OUTBASE}.nii.gz"
echo "  ${OUTBASE}.mat"
echo "  ${OUTBASE/_bbr/_edges_bbr}.nii.gz"
