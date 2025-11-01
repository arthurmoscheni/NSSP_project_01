"""
Gaussian Smoothing using FSL's fslmaths.
Applies spatial smoothing to fMRI data.
"""
import os
import subprocess
from config import OUTPUT_ROOT, MOCO_DIR, SMOOTH_DIR, SMOOTH_FWHM


def gaussian_smooth(input_path, output_path, fwhm=SMOOTH_FWHM):
    """
    Apply Gaussian smoothing to fMRI data.
    
    Parameters:
    -----------
    input_path : str
        Path to input fMRI data
    output_path : str
        Path for smoothed output
    fwhm : float
        Full-width at half-maximum of Gaussian kernel in mm (default: 5.0)
    
    Returns:
    --------
    output_path : str
        Path to smoothed data
    """
    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Convert FWHM to sigma (sigma = FWHM / 2.355)
    sigma = fwhm / 2.355
    
    print(f"Applying Gaussian smoothing (FWHM = {fwhm} mm, sigma = {sigma:.3f} mm)...")
    
    # Use fslmaths with -s option for smoothing
    cmd = ['fslmaths', input_path, '-s', str(sigma), output_path]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise RuntimeError(f"fslmaths smoothing failed:\n{result.stderr}")
    
    print(f"\nSmoothing complete!")
    print(f"  Smoothed data: {output_path}")
    
    return output_path


if __name__ == "__main__":
    print("=" * 60)
    print("Gaussian Smoothing")
    print("=" * 60)
    
    input_path = os.path.join(MOCO_DIR, "moco.nii.gz")
    output_path = os.path.join(SMOOTH_DIR, "moco_smooth.nii.gz")
    
    gaussian_smooth(
        input_path,
        output_path,
        fwhm=SMOOTH_FWHM
    )
    
    print("\nGaussian smoothing completed successfully!")

