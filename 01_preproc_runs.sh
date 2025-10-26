set -euo pipefail
source ./00_config.sh
source ./lib.sh
setup_fsl


norm_runs=()
outidx_files=()


echo "=== PART A/B: Pre-stats per run → unit-variance rescale ==="
for run in "${RUNS[@]}"; do
[[ -f "$run" ]] || { echo "ERROR: Run not found: $run" >&2; exit 1; }


base=$(base_from_path "$run")
rdir="${OUTDIR}/${base}.pre"; mkdir -p "$rdir"
echo "-> Processing ${base}"


# Mean functional
fslmaths "$run" -Tmean "${rdir}/${base}_mean"


# Brain extraction on mean to mask
bet "${rdir}/${base}_mean" "${rdir}/${base}_mean_brain" -f 0.30 -m
mask="${rdir}/${base}_mean_brain_mask.nii.gz"


# Motion correction
mcflirt -in "$run" -out "${rdir}/${base}_mcf" -plots -mats -refvol 0 -report


# FD outliers et plots
fsl_motion_outliers -i "${rdir}/${base}_mcf.nii.gz" \
--fd --thresh="${THRESH_FD}" \
-p "${rdir}/${base}_fd_plot.png" \
-s "${rdir}/${base}_fd.txt" \
-o "${rdir}/${base}_fd_confounds.tsv"


# Collect outlier indices
out_idx="${rdir}/${base}_fd_outlier_idx.txt"
if [[ -s "${rdir}/${base}_fd_confounds.tsv" ]]; then
awk '{s=0; for(i=1;i<=NF;i++) if ($i==1) {s=1; break} if (s==1) print NR-1}' \
"${rdir}/${base}_fd_confounds.tsv" > "${out_idx}"
else
: > "${out_idx}"
fi
outidx_files+=("${out_idx}")



fslval "${rdir}/${base}_mcf.nii.gz" dim4 > "${rdir}/${base}_nvols.txt"



export LC_ALL=C
sigma=$(fslstats "${rdir}/${base}_mcf.nii.gz" -k "$mask" -S | awk '{printf("%.10f",$1)}')
is_number "$sigma" || { echo "ERROR: Invalid global std: '$sigma'" >&2; exit 1; }


# Normalize to unit variance
out_norm="${rdir}/${base}_mcf_std1.nii.gz"
fslmaths "${rdir}/${base}_mcf.nii.gz" -div "$sigma" "$out_norm" -odt float
norm_runs+=("${out_norm}")


# Mean FD log
awk '{s+=$1;n++}END{if(n>0) printf(" mean FD = %.4f (n=%d)\n",s/n,n); else print " mean FD = NA"}' \
"${rdir}/${base}_fd.txt" || true


done


# save list of normalized files for the next step
printf "%s\n" "${norm_runs[@]}" > "${OUTDIR}/_norm_runs.list"
printf "%s\n" "${outidx_files[@]}" > "${OUTDIR}/_outidx_files.list"