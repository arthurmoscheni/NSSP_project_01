set -euo pipefail
source ./00_config.sh
source ./lib.sh
setup_fsl

echo "=== Running FAST on T1 brain image ==="

[[ -f "${T1_BRAIN}" ]] || { echo "ERROR: T1 brain image not found: ${T1_BRAIN}" >&2; exit 1; }
T1_DIR=$(dirname "${T1_BRAIN}")
# Derive non-brain T1 path if  exists
T1_HEAD="${T1_BRAIN/_brain.nii.gz/.nii.gz}"
[[ -f "${T1_HEAD}" ]] || { echo "WARN: Could not find T1 head at ${T1_HEAD}. Using brain-only for FAST."; T1_HEAD=""; }

echo "T1 brain: ${T1_BRAIN}"
# Run FAST on brain-extracted T1
fast -v -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o "${T1_DIR}/T1w_fast" "${T1_BRAIN}"
echo "FAST finished."

# White matter segmentation
fslmaths "${T1_DIR}/T1w_fast_pve_2.nii.gz" -thr 0.5 -bin "${T1_DIR}/T1w_wmseg.nii.gz"
echo "WM seg: ${T1_DIR}/T1w_wmseg.nii.gz"


fslmaths "${T1_BRAIN}" -bin "${T1_DIR}/T1w_brain_mask.nii.gz"

brainvol_mm3=$(fslstats "${T1_DIR}/T1w_brain_mask.nii.gz" -V | awk '{print $2}')
wm_mean=$(fslstats "${T1_DIR}/T1w_fast_pve_2.nii.gz" -k "${T1_DIR}/T1w_brain_mask.nii.gz" -M)
gm_mean=$(fslstats "${T1_DIR}/T1w_fast_pve_1.nii.gz" -k "${T1_DIR}/T1w_brain_mask.nii.gz" -M)
csf_mean=$(fslstats "${T1_DIR}/T1w_fast_pve_0.nii.gz" -k "${T1_DIR}/T1w_brain_mask.nii.gz" -M)

echo "WM volume (mL):" $(awk -v m="$wm_mean" -v V="$brainvol_mm3" 'BEGIN{print m*V/1000}')
echo "GM volume (mL):" $(awk -v m="$gm_mean" -v V="$brainvol_mm3" 'BEGIN{print m*V/1000}')
echo "CSF volume (mL):" $(awk -v m="$csf_mean" -v V="$brainvol_mm3" 'BEGIN{print m*V/1000}')
