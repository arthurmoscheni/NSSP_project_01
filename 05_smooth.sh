#!/usr/bin/env bash
set -euo pipefail
source ./00_config.sh
source ./lib.sh
setup_fsl

echo "=== Smoothing concatenated fMRI data ==="

merged="${OUTDIR}/sub-101410_allruns_mc_std1.nii.gz"
scrubbed="${OUTDIR}/sub-101410_allruns_mc_std1_scrubbed.nii.gz"

case "${SCRUB_AFTER}" in
  1)  # deletion
      in4d="$scrubbed"
      ;;
  2)  # censoring -> keep original timeline
      in4d="$merged"
      ;;
  *)  # none
      in4d="$merged"
      ;;
esac

if [[ ! -f "$in4d" ]]; then
  if [[ "${SCRUB_AFTER}" == "1" && -f "$merged" ]]; then
    echo "WARN: scrubbed file missing; falling back to merged."
    in4d="$merged"
  else
    echo "ERROR: expected input not found: $in4d" >&2; exit 1
  fi
fi

echo "Input 4D: ${in4d} using SCRUB_AFTER=${SCRUB_AFTER}"
echo "Smoothing FWHM: ${SMOOTH_FWHM} mm"
SIGMA=$(awk -v f="${SMOOTH_FWHM}" 'BEGIN{printf("%.3f", f/2.3548)}')
out="${in4d%.nii.gz}_s${SMOOTH_FWHM}mm.nii.gz"
fslmaths "$in4d" -s "$SIGMA" "$out" -odt float
echo "Used sigma=${SIGMA} mm (~${SMOOTH_FWHM} mm FWHM)"
echo "Wrote: ${out}"
