# Functional runs (4D NIfTI paths)
RUNS=(
"tfMRI_MOTOR_LR/tfMRI_MOTOR_LR.nii"
"tfMRI_MOTOR_RL/tfMRI_MOTOR_RL.nii"
)


# Output
OUTDIR="output_FEAT"
mkdir -p "${OUTDIR}"


# Motion
THRESH_FD=0.2 # mm

SCRUB_AFTER=2 # 0=none, 1=before, 2=after


# Structural (T1)
T1_BRAIN="../T1w/T1w_brain.nii.gz"


# Which run to use for coreg figure
COREG_RUN_INDEX=0


# Smoothing kernel
SMOOTH_FWHM= 6 # mm

