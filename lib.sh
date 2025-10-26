set -euo pipefail


setup_fsl() {
if ! command -v mcflirt >/dev/null 2>&1; then
if [[ -n "${FSLDIR:-}" && -f "${FSLDIR}/etc/fslconf/fsl.sh" ]]; then
source "${FSLDIR}/etc/fslconf/fsl.sh"
fi
fi
command -v mcflirt >/dev/null 2>&1 || { echo "ERROR: FSL not found in PATH" >&2; exit 1; }
}


# Strip .nii or .nii.gz
base_from_path() {
local p=$1; p=$(basename "$p")
p="${p%.nii.gz}"; p="${p%.nii}"
printf "%s" "$p"
}


# Robust check for numeric
is_number() { [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]]; }