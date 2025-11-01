"""
Co-registration of EPI to T1w using epi_reg (BBR - Boundary-Based Registration).
Note: This is for visualization only and results are not used in the rest of the pipeline.
"""
import os
import subprocess
from fsl.wrappers.misc import fslroi
from config import (
    BIDS_ROOT, SUBJECT_DIR, DERIVATIVES_ROOT,
    OUTPUT_ROOT, MOCO_DIR, COREG_DIR
)


def extract_middle_volume(input_path, output_path, sequence_length=568):
    """
    Extract middle volume from 4D fMRI data.
    
    Parameters:
    -----------
    input_path : str
        Path to 4D fMRI data
    output_path : str
        Path for output single volume
    sequence_length : int
        Total number of volumes in sequence
    """
    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    mid_vol_index = sequence_length // 2
    
    print(f"Extracting middle volume (index {mid_vol_index})...")
    fslroi(input_path, output_path, str(mid_vol_index), str(1))
    
    return output_path


def coregister_epi_to_t1w(epi_path, t1w_path, t1w_brain_path, wm_seg_path, output_path):
    """
    Co-register EPI to T1w using epi_reg (BBR method).
    
    Parameters:
    -----------
    epi_path : str
        Path to EPI volume (source)
    t1w_path : str
        Path to whole-head T1w (target)
    t1w_brain_path : str
        Path to skull-stripped T1w
    wm_seg_path : str
        Path to white matter segmentation
    output_path : str
        Path for registered output
    
    Returns:
    --------
    output_path : str
        Path to registered EPI
    """
    if not all(os.path.isfile(p) for p in [epi_path, t1w_path, t1w_brain_path, wm_seg_path]):
        missing = [p for p in [epi_path, t1w_path, t1w_brain_path, wm_seg_path] if not os.path.isfile(p)]
        raise FileNotFoundError(f"Missing files: {missing}")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    print("Running co-registration (epi_reg with BBR)...")
    cmd = [
        'epi_reg',
        f'--epi={epi_path}',
        f'--t1={t1w_path}',
        f'--t1brain={t1w_brain_path}',
        f'--out={output_path}',
        f'--wmseg={wm_seg_path}'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise RuntimeError(f"epi_reg failed:\n{result.stderr}")
    
    print(f"\nCo-registration complete!")
    print(f"  Registered EPI: {output_path}")
    
    return output_path


if __name__ == "__main__":
    print("=" * 60)
    print("Co-registration (EPI to T1w)")
    print("=" * 60)
    print("Note: This step is for visualization only.")
    print("=" * 60)
    
    # Input paths
    moco_path = os.path.join(MOCO_DIR, "moco.nii.gz")
    t1w_path = os.path.join(BIDS_ROOT, SUBJECT_DIR, "T1w", "T1w.nii.gz")
    t1w_brain_path = os.path.join(DERIVATIVES_ROOT, "T1w_brain.nii.gz")
    wm_seg_path = os.path.join(DERIVATIVES_ROOT, "T1w_fast_pve_2.nii.gz")
    
    # Extract middle volume from motion-corrected data
    os.makedirs(COREG_DIR, exist_ok=True)
    ref_vol_path = os.path.join(COREG_DIR, "moco_vol_middle.nii.gz")
    
    extract_middle_volume(moco_path, ref_vol_path, sequence_length=568)
    
    # Co-register
    output_path = os.path.join(COREG_DIR, "moco_vol_bbr.nii.gz")
    
    coregister_epi_to_t1w(
        ref_vol_path,
        t1w_path,
        t1w_brain_path,
        wm_seg_path,
        output_path
    )
    
    print("\nCo-registration completed successfully!")

