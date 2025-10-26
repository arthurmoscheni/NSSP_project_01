#!/usr/bin/env bash
# 06_fd_plots.sh (robust, no heredoc-in-if)
set -Eeuo pipefail
source ./00_config.sh

sed -i 's/\r$//' "$0" 00_config.sh 2>/dev/null || true

pytool="$(mktemp -t make_fd_plot.XXXXXX.py)"
cat > "$pytool" <<'PY'
import sys, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
fd_xy, thr, meanfd, out_png = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
dat = np.loadtxt(fd_xy)
if dat.ndim == 1:
    x = np.arange(dat.size)
    y = dat
else:
    x, y = dat[:,0], dat[:,1]
plt.figure(figsize=(11,3))
plt.plot(x, y, linewidth=1)
plt.axhline(thr, linewidth=2, color='red')
plt.axhline(meanfd, linewidth=1, color='red', linestyle='--')
plt.xlabel("TR"); plt.ylabel("FD (mm)"); plt.title("Framewise Displacement")
plt.grid(axis='y'); plt.tight_layout(); plt.savefig(out_png, dpi=150)
PY

have_matplotlib=0
if python3 -c "import matplotlib" >/dev/null 2>&1; then
  have_matplotlib=1
fi

make_fd_plot() {
  local fd_txt="$1" thr="$2"
  local out_png="${fd_txt%_fd.txt}_fd_plot_nice.png"
  local tmpdat meanfd

  tmpdat="$(mktemp)"
  awk '{print NR-1, $1}' "$fd_txt" > "$tmpdat"
  meanfd=$(awk '{s+=$1;n++}END{if(n>0) printf("%.6f", s/n); else print "0"}' "$fd_txt")

  if command -v gnuplot >/dev/null 2>&1; then
    gnuplot > /dev/null <<GNUPLOT
      set terminal pngcairo size 1100,300
      set output "${out_png}"
      set xlabel "TR"
      set ylabel "FD (mm)"
      set title "Framewise Displacement"
      set key off
      set grid ytics
      thr=${thr}
      mfd=${meanfd}
      set arrow from graph 0,first thr to graph 1,first thr nohead lc rgb "red" lw 2
      set arrow from graph 0,first mfd to graph 1,first mfd nohead lc rgb "red" lw 1 dt 2
      plot "${tmpdat}" using 1:2 with lines lw 1
GNUPLOT
  elif [[ $have_matplotlib -eq 1 ]]; then
    python3 "$pytool" "$tmpdat" "$thr" "$meanfd" "$out_png"
  else
    echo "WARN: Neither gnuplot nor matplotlib found; skipping ${fd_txt}." >&2
    rm -f "$tmpdat"
    return
  fi

  rm -f "$tmpdat"
  echo "FD plot → ${out_png}   (thr=${thr} mm, mean=${meanfd} mm)"
}

shopt -s nullglob
found=0
for fd in "${OUTDIR}"/*/*_fd.txt; do
  found=1
  make_fd_plot "$fd" "$THRESH_FD"
done
rm -f "$pytool"

if (( found == 0 )); then
  echo "No *_fd.txt files found under ${OUTDIR}/**"
fi
