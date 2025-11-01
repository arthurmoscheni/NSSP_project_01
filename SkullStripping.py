"""
Skull Stripping using BET (Brain Extraction Tool).
Performs skull stripping on T1w structural image.
"""
import os
import sys
from fsl.wrappers import bet
from config import T1W_PATH, DERIVATIVES_ROOT, BET_FRAC, BET_GRAD


def skull_strip(input_path, output_dir, frac=BET_FRAC, grad=BET_GRAD, robust=True):
    """
    Perform skull stripping using BET.
    
    Parameters:
    -----------
    input_path : str
        Path to input T1w image
    output_dir : str
        Output directory for brain-extracted images
    frac : float
        Fractional intensity threshold (default: 0.2)
    grad : float
        Vertical gradient in fractional intensity threshold (default: -0.1)
    robust : bool
        Use robust brain center estimation (default: True)
    
    Returns:
    --------
    brain_path : str
        Path to skull-stripped brain image
    mask_path : str
        Path to brain mask
    """
    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    os.makedirs(output_dir, exist_ok=True)
    output_stem = os.path.join(output_dir, "T1w_brain")
    
    # Run BET
    bet(input_path, output_stem, 
        f=frac, g=grad, m=True, R=robust)
    
    brain_path = output_stem + ".nii.gz"
    mask_path = os.path.join(output_dir, "T1w_brain_mask.nii.gz")
    
    print(f"Skull stripping complete!")
    print(f"  Brain: {brain_path}")
    print(f"  Mask: {mask_path}")
    
    return brain_path, mask_path


if __name__ == "__main__":
    print("=" * 60)
    print("Skull Stripping")
    print("=" * 60)
    
    brain_path, mask_path = skull_strip(
        T1W_PATH, 
        DERIVATIVES_ROOT,
        frac=BET_FRAC,
        grad=BET_GRAD,
        robust=True
    )
    
    print("\nSkull stripping completed successfully!")

