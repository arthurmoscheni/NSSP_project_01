"""
Tissue Segmentation using FAST (FMRIB's Automated Segmentation Tool).
Segments brain into CSF, Gray Matter, and White Matter.
"""
import os
from fsl.wrappers import fast
from config import DERIVATIVES_ROOT


def segment_tissues(brain_path, output_dir, n_classes=3):
    """
    Perform tissue segmentation using FAST.
    
    Parameters:
    -----------
    brain_path : str
        Path to skull-stripped brain image
    output_dir : str
        Output directory for segmentation files
    n_classes : int
        Number of tissue classes (default: 3 for CSF, GM, WM)
    
    Returns:
    --------
    fast_prefix : str
        Prefix for FAST output files
    """
    if not os.path.isfile(brain_path):
        raise FileNotFoundError(f"Brain image not found: {brain_path}")
    
    os.makedirs(output_dir, exist_ok=True)
    fast_prefix = os.path.join(output_dir, "T1w_fast")
    
    print("Starting tissue segmentation...")
    fast(imgs=[brain_path], out=fast_prefix, n_classes=n_classes)
    
    print(f"Segmentation complete!")
    print(f"  Output prefix: {fast_prefix}")
    print(f"  Files created:")
    print(f"    - {fast_prefix}_pve_0.nii.gz (CSF)")
    print(f"    - {fast_prefix}_pve_1.nii.gz (Gray Matter)")
    print(f"    - {fast_prefix}_pve_2.nii.gz (White Matter)")
    
    return fast_prefix


if __name__ == "__main__":
    print("=" * 60)
    print("Tissue Segmentation")
    print("=" * 60)
    
    brain_path = os.path.join(DERIVATIVES_ROOT, "T1w_brain.nii.gz")
    
    fast_prefix = segment_tissues(
        brain_path,
        DERIVATIVES_ROOT,
        n_classes=3
    )
    
    print("\nSegmentation completed successfully!")

