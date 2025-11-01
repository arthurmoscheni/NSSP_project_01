"""
Configuration file for preprocessing pipeline.
Defines all paths in one place for consistency.
"""
import os

# Base paths
BIDS_ROOT = "./"
SUBJECT_ID = "101410"
SUBJECT_DIR = f"subject{SUBJECT_ID}"  # Original format used in dataset

# Raw data paths
RAW_DIR = os.path.join(BIDS_ROOT, SUBJECT_DIR)
T1W_DIR = os.path.join(RAW_DIR, "T1w")
T1W_PATH = os.path.join(T1W_DIR, "T1w.nii.gz")

# fMRI runs
FMRI_DIR = os.path.join(RAW_DIR, "fMRI")
RUN1_PATH = os.path.join(FMRI_DIR, "tfMRI_MOTOR_LR", "tfMRI_MOTOR_LR.nii")
RUN2_PATH = os.path.join(FMRI_DIR, "tfMRI_MOTOR_RL", "tfMRI_MOTOR_RL.nii")

# Derivatives paths
DERIVATIVES_ROOT = os.path.join(BIDS_ROOT, "derivatives", "preprocessed_data", SUBJECT_DIR)
OUTPUT_ROOT = os.path.join(os.getcwd(), "output")

# Output subdirectories
MOCO_DIR = os.path.join(OUTPUT_ROOT, "moco_mot_corr")
COREG_DIR = os.path.join(OUTPUT_ROOT, "coreg")
SMOOTH_DIR = os.path.join(OUTPUT_ROOT, "smoothed")

# Preprocessing parameters
BET_FRAC = 0.2
BET_GRAD = -0.1
BRAIN_MASK_THRESHOLD = 1e-6
FD_RADIUS_MM = 50  # Radius for framewise displacement calculation
SMOOTH_FWHM = 6.0  # FWHM for Gaussian smoothing (mm)

