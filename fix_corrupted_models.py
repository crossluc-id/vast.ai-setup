#!/usr/bin/env python3
"""
Fix corrupted model files by re-downloading them
Use this script if you get "HeaderTooSmall" or other safetensors errors
"""

import os
import sys
from pathlib import Path

# Use WORKSPACE environment variable if available (vast.ai standard)
WORKSPACE = os.environ.get("WORKSPACE", "/workspace")
COMFYUI_ROOT = os.path.join(WORKSPACE, "ComfyUI")

# Try to import safetensors for validation
try:
    import safetensors
    SAFETENSORS_AVAILABLE = True
except ImportError:
    SAFETENSORS_AVAILABLE = False

def verify_safetensors_file(file_path):
    """
    Verify that a safetensors file is valid and not corrupted
    Returns True if valid, False if corrupted
    """
    if not SAFETENSORS_AVAILABLE:
        # Without safetensors library, just check file size > 0
        return file_path.exists() and file_path.stat().st_size > 1024  # At least 1KB
    
    try:
        # Try to open and read the safetensors file header
        with safetensors.safe_open(str(file_path), framework="pt") as f:
            # If we can open it, it's valid
            _ = list(f.keys())[:1]  # Try to read at least one key
        return True
    except Exception as e:
        return False

def find_corrupted_safetensors():
    """Find all corrupted safetensors files in ComfyUI models directory"""
    corrupted_files = []
    models_dir = Path(COMFYUI_ROOT) / "models"
    
    if not models_dir.exists():
        print(f"Error: Models directory not found at {models_dir}")
        return corrupted_files
    
    print("Scanning for corrupted safetensors files...")
    
    # Recursively search for safetensors files
    for safetensors_file in models_dir.rglob("*.safetensors"):
        if safetensors_file.is_file():
            if not verify_safetensors_file(safetensors_file):
                corrupted_files.append(safetensors_file)
                size_mb = safetensors_file.stat().st_size / 1024 / 1024
                print(f"  ✗ Corrupted: {safetensors_file.relative_to(models_dir)} ({size_mb:.1f} MB)")
    
    return corrupted_files

def main():
    print("=" * 60)
    print("  ComfyUI Model File Corruption Fixer")
    print("=" * 60)
    print()
    
    if not SAFETENSORS_AVAILABLE:
        print("Warning: safetensors library not available.")
        print("Install it with: pip install safetensors")
        print("Continuing with basic file size checks...")
        print()
    
    # Find corrupted files
    corrupted = find_corrupted_safetensors()
    
    if not corrupted:
        print("✓ No corrupted files found!")
        return
    
    print(f"\nFound {len(corrupted)} corrupted file(s).")
    print("\nTo fix these files, you need to:")
    print("1. Delete the corrupted files")
    print("2. Re-run: python3 auto_download_models_mire.py")
    print()
    print("Or delete them manually and re-download:")
    for file in corrupted:
        print(f"  rm {file}")
    
    # Ask if user wants to delete and re-download
    response = input("\nDelete corrupted files and re-download? (y/n): ").strip().lower()
    if response == 'y':
        print("\nDeleting corrupted files...")
        for file in corrupted:
            try:
                file.unlink()
                print(f"  ✓ Deleted: {file.name}")
            except Exception as e:
                print(f"  ✗ Failed to delete {file.name}: {e}")
        
        print("\nRe-downloading models...")
        print("Run: python3 auto_download_models_mire.py")
    else:
        print("Cancelled. Files not deleted.")

if __name__ == "__main__":
    main()

