
#!/usr/bin/env bash
set -euo pipefail
source ./00_config.sh
source ./lib.sh
setup_fsl

# Build expected normalized paths from RUNS (in config.sh)
norm_runs=()
outidx_files=()
while IFS= read -r p; do [[ -n "$p" ]] && norm_runs+=("$p"); done < <(cat "${OUTDIR}/_norm_runs.list")
while IFS= read -r p; do [[ -n "$p" ]] && outidx_files+=("$p"); done < <(cat "${OUTDIR}/_outidx_files.list")

[[ ${#norm_runs[@]} -gt 0 ]] || { echo "ERROR: No normalized runs found" >&2; exit 1; }

merged="${OUTDIR}/sub-101410_allruns_mc_std1.nii.gz"
echo "=== Concatenating normalized runs (time axis) → ${merged} ==="
fslmerge -t "$merged" "${norm_runs[@]}"


# Build global outlier indices (0-based) after concatenation
echo "=== Building global outlier index list ==="
global_idx_file="${OUTDIR}/concat_outlier_idx_global.txt"
: > "$global_idx_file"

offset=0
for i in "${!RUNS[@]}"; do
  base=$(base_from_path "${RUNS[$i]}")
  nvols=$(cat "${OUTDIR}/${base}.pre/${base}_nvols.txt")
  idxfile="${outidx_files[$i]}"
  if [[ -s "$idxfile" ]]; then
    while IFS= read -r idx; do
      echo $((idx + offset)) >> "$global_idx_file"
    done < "$idxfile"
  fi
  offset=$((offset + nvols))
done

if [[ -s "$global_idx_file" ]]; then
  sort -n -u "$global_idx_file" -o "$global_idx_file"
  totalTR=$(fslval "$merged" dim4)
  excl=$(wc -l < "$global_idx_file" | tr -d ' ')
  echo "   Total TRs: ${totalTR}; flagged ${excl} outlier volumes (FD > ${THRESH_FD} mm)"
else
  echo "   No outliers detected across runs."
fi



# Branch by SCRUB_AFTER mode
# 0 = do nothing (pas top)
# 1 = DELETE volumes (violent)
# 2 = CENSOR (write one-hot regressors; keep data intact --> meilleur?)

if [[ "${SCRUB_AFTER}" == "1" ]]; then
  echo "=== Mode: DELETE outliers (hard scrub) ==="
  if [[ -s "$global_idx_file" ]]; then
    tmpdir="${OUTDIR}/_scrub_tmp"; mkdir -p "$tmpdir"
    fslsplit "$merged" "${tmpdir}/vol_" -t
    while IFS= read -r gidx; do
      rm -f "${tmpdir}/$(printf 'vol_%04d.nii.gz' "$gidx")" \
            "${tmpdir}/$(printf 'vol_%04d.nii'    "$gidx")" || true
    done < "$global_idx_file"

    shopt -s nullglob
    files=( "${tmpdir}"/vol_*.nii* )
    (( ${#files[@]} > 0 )) || { echo "ERROR: All volumes excluded; lower THRESH_FD." >&2; exit 1; }

    fslmerge -t "${OUTDIR}/sub-101410_allruns_mc_std1_scrubbed.nii.gz" "${files[@]}"
    echo "   Wrote scrubbed: ${OUTDIR}/sub-101410_allruns_mc_std1_scrubbed.nii.gz"
  else
    echo "   Nothing to scrub."
  fi

elif [[ "${SCRUB_AFTER}" == "2" ]]; then
  echo "=== Mode: CENSOR outliers (write one-hot regressors; keep data) ==="
  if [[ -s "$global_idx_file" ]]; then
    totalTR=$(fslval "$merged" dim4)
    censor_mat="${OUTDIR}/concat_outlier_regressors.tsv"
    # Build one-hot columns: rows = totalTR, cols = #outliers
    awk -v nTR="$totalTR" '
      { idx[NR-1]=$1; n=NR }                    # store outlier indices (0-based)
      END {
        for (t=0; t<nTR; t++) {
          line="";
          for (c=0; c<n; c++) {
            v = (t==idx[c] ? 1 : 0);
            line = line (c? "\t" : "") v;
          }
          print line;
        }
      }
    ' "$global_idx_file" > "$censor_mat"

    echo "   Wrote censor matrix: ${censor_mat}"
    echo "   (shape: $(wc -l < "$censor_mat") rows × $( (wc -l < "$global_idx_file") ) cols)"
    echo "   Tip: add these columns as EVs with no convolution/derivative in your GLM."
  else
    echo "   No outliers → no censor regressors written."
  fi

else
  echo "=== Mode: No scrubbing/censoring (SCRUB_AFTER=${SCRUB_AFTER}) ==="
fi
