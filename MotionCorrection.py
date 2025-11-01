"""
Motion Correction using MCFLIRT.
Corrects for head motion in fMRI time series.
"""
import os
import pandas as pd
import numpy as np
from fsl.wrappers import mcflirt
from config import OUTPUT_ROOT, MOCO_DIR, FD_RADIUS_MM


def motion_correct(input_path, output_dir, dof=6, plots=True, report=True, mats=True):
    """
    Perform motion correction using MCFLIRT.
    
    Parameters:
    -----------
    input_path : str
        Path to input fMRI data
    output_dir : str
        Output directory for motion-corrected data
    dof : int
        Degrees of freedom for registration (default: 6)
    plots : bool
        Generate motion plots (default: True)
    report : bool
        Generate motion report (default: True)
    mats : bool
        Save transformation matrices (default: True)
    
    Returns:
    --------
    moco_path : str
        Path to motion-corrected data
    par_path : str
        Path to motion parameters file
    """
    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    os.makedirs(output_dir, exist_ok=True)
    output_stem = os.path.join(output_dir, "moco")
    
    print("Running motion correction (MCFLIRT)...")
    mcflirt(
        infile=input_path,
        o=output_stem,
        plots=plots,
        report=report,
        dof=dof,
        mats=mats
    )
    
    moco_path = output_stem + ".nii.gz"
    par_path = os.path.join(output_dir, "moco.par")
    
    print(f"\nMotion correction complete!")
    print(f"  Motion-corrected data: {moco_path}")
    print(f"  Motion parameters: {par_path}")
    
    return moco_path, par_path


def load_motion_parameters(par_path, dof=6):
    """
    Load motion parameters from MCFLIRT output.
    
    Parameters:
    -----------
    par_path : str
        Path to motion parameters file (.par)
    dof : int
        Degrees of freedom (6 for rigid body)
    
    Returns:
    --------
    mot_params : pd.DataFrame
        Motion parameters dataframe
    """
    if not os.path.isfile(par_path):
        raise FileNotFoundError(f"Motion parameters file not found: {par_path}")
    
    # MCFLIRT .par files use double space as separator
    mot_params = pd.read_csv(
        par_path,
        sep='  ',
        header=None,
        engine='python',
        names=['Rotation x', 'Rotation y', 'Rotation z',
               'Translation x', 'Translation y', 'Translation z']
    )
    
    return mot_params


def compute_framewise_displacement(mot_params, radius_mm=FD_RADIUS_MM):
    """
    Compute framewise displacement using Power's method.
    
    Parameters:
    -----------
    mot_params : pd.DataFrame
        Motion parameters dataframe
    radius_mm : float
        Radius for converting rotations to translations (default: 50mm)
    
    Returns:
    --------
    fd : np.ndarray
        Framewise displacement for each volume
    """
    # Compute frame-to-frame differences
    framewise_diff = mot_params.diff().iloc[1:]
    
    # Extract rotation and translation parameters
    rot_params = framewise_diff[['Rotation x', 'Rotation y', 'Rotation z']]
    trans_params = framewise_diff[['Translation x', 'Translation y', 'Translation z']]
    
    # Convert rotations to translations (arc length on sphere)
    converted_rots = rot_params * radius_mm
    
    # Compute FD: sum of absolute rotational and translational displacements
    fd = converted_rots.abs().sum(axis=1) + trans_params.abs().sum(axis=1)
    
    return fd.to_numpy()


def compute_fd_threshold(fd, method='iqr'):
    """
    Compute framewise displacement threshold.
    
    Parameters:
    -----------
    fd : np.ndarray
        Framewise displacement values
    method : str
        Method for threshold calculation ('iqr' or 'median')
    
    Returns:
    --------
    threshold : float
        FD threshold value
    """
    if method == 'iqr':
        # IQR method: Q3 + 1.5 * IQR
        q1 = np.quantile(fd, 0.25)
        q3 = np.quantile(fd, 0.75)
        threshold = q3 + 1.5 * (q3 - q1)
    elif method == 'median':
        # Median + 5 * MAD
        median = np.median(fd)
        mad = np.median(np.abs(fd - median))
        threshold = median + 5 * mad
    else:
        raise ValueError(f"Unknown method: {method}")
    
    return threshold


if __name__ == "__main__":
    print("=" * 60)
    print("Motion Correction")
    print("=" * 60)
    
    input_path = os.path.join(OUTPUT_ROOT, "fMRI_motor_concat_var1.nii.gz")
    
    moco_path, par_path = motion_correct(
        input_path,
        MOCO_DIR,
        dof=6,
        plots=True,
        report=True,
        mats=True
    )
    
    # Compute and display framewise displacement
    print("\nComputing framewise displacement...")
    mot_params = load_motion_parameters(par_path, dof=6)
    fd = compute_framewise_displacement(mot_params, radius_mm=FD_RADIUS_MM)
    threshold = compute_fd_threshold(fd, method='iqr')
    
    print(f"\nFramewise Displacement Statistics:")
    print(f"  Mean FD: {np.mean(fd):.3f} mm")
    print(f"  Median FD: {np.median(fd):.3f} mm")
    print(f"  Max FD: {np.max(fd):.3f} mm")
    print(f"  Threshold (IQR): {threshold:.3f} mm")
    print(f"  Volumes > threshold: {np.sum(fd > threshold)} ({100*np.sum(fd > threshold)/len(fd):.1f}%)")
    
    print("\nMotion correction completed successfully!")

