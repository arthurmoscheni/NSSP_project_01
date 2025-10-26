# save as: make_motor_confounds.sh
#!/usr/bin/env bash
set -euo pipefail

# Load FSL if needed
command -v mcflirt >/dev/null || source "${FSLDIR}/etc/fslconf/fsl.sh"

# ---- EDIT THESE to your actual MOTOR runs ----
RUNS=(
  "tfMRI_MOTOR_LR/tfMRI_MOTOR_LR.nii"
  "tfMRI_MOTOR_RL/tfMRI_MOTOR_RL.nii"
)
# If you don't know exact names, you can try this auto-detect instead:
# mapfile -t RUNS < <(find . -iname "*task-*MOTOR*_*bold.nii.gz" | sort)

OUTROOT="output_FEAT/confounds"
THRESH_FD=0.2
mkdir -p "${OUTROOT}"

echo "== Making motion (.par) + FD outliers for ${#RUNS[@]} run(s) =="
for run in "${RUNS[@]}"; do
  [[ -f "$run" ]] || { echo "ERROR: missing $run"; exit 1; }
  base=$(basename "$run" .nii.gz)
  pre="${OUTROOT}/${base}"
  echo "--> ${base}"

  # Motion params (.par) via MCFLIRT (-plots writes the .par file)
  mcflirt -in "$run" -out "${pre}" -plots -refvol 0 -report

  # FD outliers design + plot
  fsl_motion_outliers -i "${pre}.nii.gz" --fd --thresh "${THRESH_FD}" \
      -p "${pre}_fd_plot.png" -s "${pre}_fd.txt" -o "${pre}_fd_confounds.tsv"
done

echo
echo "Paste these into your Python GLM script:"
echo "MOTION_PARS = ["
for run in "${RUNS[@]}"; do
  base=$(basename "$run" .nii.gz); pre="${OUTROOT}/${base}"
  echo "    \"${pre}.par\","
done
echo "]"
echo "OUTLIERS_TSV = ["
for run in "${RUNS[@]}"; do
  base=$(basename "$run" .nii.gz); pre="${OUTROOT}/${base}"
  echo "    \"${pre}_fd_confounds.tsv\","
done
echo "]"
