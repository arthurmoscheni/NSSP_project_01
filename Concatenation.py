"""
Concatenate fMRI runs with variance normalization.
Normalizes each run to unit variance before concatenation.
"""
import os
import numpy as np
import nibabel as nib
from config import RUN1_PATH, RUN2_PATH, OUTPUT_ROOT, BRAIN_MASK_THRESHOLD


def load_image_data(path):
    """Load NIfTI image and return image object and data array."""
    if not os.path.isfile(path):
        raise FileNotFoundError(f"File not found: {path}")
    
    img = nib.load(path)
    data = img.get_fdata(dtype=np.float32)
    return img, data


def create_brain_mask(data, threshold=BRAIN_MASK_THRESHOLD):
    """
    Create brain mask from 4D fMRI data.
    
    Parameters:
    -----------
    data : np.ndarray
        4D array of shape (x, y, z, t)
    threshold : float
        Threshold for mean absolute intensity
    
    Returns:
    --------
    mask : np.ndarray
        3D boolean mask
    """
    mean_signal = np.mean(np.abs(data), axis=3)
    mask = mean_signal > threshold
    return mask


def compute_global_variance(data, mask):
    """
    Compute global variance across all brain voxels and timepoints.
    
    Parameters:
    -----------
    data : np.ndarray
        4D array of shape (x, y, z, t)
    mask : np.ndarray
        3D boolean mask
    
    Returns:
    --------
    variance : float
        Global variance
    """
    brain_data = data[mask]
    return np.var(brain_data)


def normalize_variance(data, mask):
    """
    Normalize data to unit variance using brain mask.
    
    Parameters:
    -----------
    data : np.ndarray
        4D array of shape (x, y, z, t)
    mask : np.ndarray
        3D boolean mask
    
    Returns:
    --------
    normalized_data : np.ndarray
        Variance-normalized data
    actual_variance : float
        Actual variance after normalization (for verification)
    """
    variance = compute_global_variance(data, mask)
    
    if variance == 0:
        raise ValueError("Cannot normalize: variance is zero")
    
    # Normalize to variance = 1 (divide by sqrt(variance) gives std = 1, so variance = 1)
    scaling_factor = 1.0 / np.sqrt(variance)
    normalized_data = data * scaling_factor
    
    # Verify normalization
    actual_variance = compute_global_variance(normalized_data, mask)
    
    return normalized_data, actual_variance


def concatenate_runs(run1_path, run2_path, output_path):
    """
    Concatenate two fMRI runs after variance normalization.
    
    Parameters:
    -----------
    run1_path : str
        Path to first run
    run2_path : str
        Path to second run
    output_path : str
        Path for concatenated output
    
    Returns:
    --------
    output_path : str
        Path to concatenated file
    """
    print("Loading runs...")
    img1, data1 = load_image_data(run1_path)
    img2, data2 = load_image_data(run2_path)
    
    print(f"Run 1 shape: {data1.shape}")
    print(f"Run 2 shape: {data2.shape}")
    
    # Create brain masks
    print("Creating brain masks...")
    mask1 = create_brain_mask(data1)
    mask2 = create_brain_mask(data2)
    
    # Compute and normalize variance
    print("Normalizing variance...")
    data1_norm, var1_actual = normalize_variance(data1, mask1)
    data2_norm, var2_actual = normalize_variance(data2, mask2)
    
    print(f"Run 1 variance after normalization: {var1_actual:.6f}")
    print(f"Run 2 variance after normalization: {var2_actual:.6f}")
    
    # Concatenate along time dimension (axis 3)
    print("Concatenating runs...")
    concatenated = np.concatenate((data1_norm, data2_norm), axis=3)
    print(f"Concatenated shape: {concatenated.shape}")
    
    # Save concatenated data
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    out_img = nib.Nifti1Image(concatenated, img1.affine, img1.header)
    nib.save(out_img, output_path)
    
    print(f"\nConcatenated data saved to: {output_path}")
    
    return output_path


if __name__ == "__main__":
    print("=" * 60)
    print("Concatenate fMRI Runs with Variance Normalization")
    print("=" * 60)
    
    output_path = os.path.join(OUTPUT_ROOT, "fMRI_motor_concat_var1.nii.gz")
    
    concatenate_runs(RUN1_PATH, RUN2_PATH, output_path)
    
    print("\nConcatenation completed successfully!")

