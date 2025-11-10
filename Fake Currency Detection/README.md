# Counterfeit Currency Detector - Indian ₹100 Note

## Overview
A classical signal processing-based counterfeit currency detector for Indian ₹100 notes. **No machine learning, neural networks, or supervised classifiers** - purely algorithmic and analytical approach.

## Architecture

### Multi-Channel Pipeline
The system processes test images through three independent detection channels after preprocessing:

```
Input Image → Preprocessing → Channel A (Templates)
                           → Channel B (Color/Structure)
                           → Channel D (Texture)
                           → Decision Fusion → VERDICT
```

## Core Components

### 1. Preprocessing Pipeline (`warpImageAfterHomography.m`)

**Purpose**: Align test image with reference image

**Steps**:
1. **Orientation Detection**: Automatically rotate portrait images to landscape
2. **Scale Standardization**: Resize to match reference height (preserving aspect ratio)
3. **ORB Feature Detection**: Detect 5000+ ORB features in both images
4. **Feature Matching**: Match features between test and reference
5. **Homography Estimation**: Use `estimateGeometricTransform2D` with RANSAC
6. **Image Warping**: Apply `imwarp` to align test image to reference

**Key Parameters**:
- ORB Features: 5000+ (NumLevels=8-10, ScaleFactor=1.1-1.2)
- Feature Matching: MaxRatio=0.7, Unique=true
- Homography: Confidence=99.9%, MaxNumTrials=2000

### 2. Channel A: Graphical Integrity (`run_channel_A.m`)

**Method**: Template Matching using Normalized Cross-Correlation (NCC)

**Steps**:
1. Apply homomorphic filter (`normalizeIllumination`) for even lighting
2. Apply histogram equalization (`histeq`) to both image and templates
3. Perform NCC (`normxcorr2`) for each template
4. Count templates with correlation > 0.60

**Templates** (at least 3):
- `template_ashoka.jpg` - Ashoka Pillar emblem
- `template_devanagiri.jpg` - Devanagari text
- `template_rbi_seal.jpg` - RBI seal

**Output**: Score = (templates found) / (total templates) ∈ [0, 1]

### 3. Channel B: Ink & Fine Pattern Integrity (`run_channel_B.m`)

**Method 1: Security Thread Color Analysis**
- Extract ROI of security thread: `[900, 1, 45, height-1]`
- Convert to L\*a\*b\* color space
- Analyze a\* channel (green-red axis): genuine threads have a\* ≈ -15 to -25
- Analyze saturation in HSV: genuine threads have S > 0.3
- Score = f(greenness) × f(saturation) using sigmoid functions

**Method 2: Bleed Lines Detection**
- Extract ROIs for left and right bleed lines
- Convert to L\*a\*b\* and use L\* (Lightness) channel
- Create 1D horizontal projection
- Invert signal and use `findpeaks` to count lines
- Score = 1.0 if exactly 4 lines on BOTH sides, else 0.0

**Output**: Score = average of Method 1 and Method 2

### 4. Channel D: Paper & Micro-Texture Integrity (`run_channel_D.m`)

**Method**: Gabor Filter Peak Analysis

**Steps**:
1. Convert to grayscale
2. Apply vertical Gabor filter:
   - Wavelength: 4 pixels
   - Orientation: 90° (vertical)
3. Find local maxima using `imregionalmax`
4. Count peaks above fixed absolute threshold (0.1)
5. Binary verdict: 1.0 if peak_count > 500, else 0.0

**Rationale**: Genuine currency paper has unique micro-texture that creates more Gabor peaks than counterfeit paper

**Output**: Binary score ∈ {0.0, 1.0}

### 5. Decision Fusion (`run_final_detector.m`)

**Weighted Average**:
```
Final Score = 0.40 × Score_A + 0.40 × Score_B + 0.20 × Score_D
```

**Weights**:
- Channel A (Templates): 40%
- Channel B (Color/Structure): 40%
- Channel D (Texture): 20%

**Final Verdict**:
- Final Score ≥ 0.65 → **GENUINE**
- Final Score < 0.65 → **COUNTERFEIT**

## Usage

### Basic Usage
```matlab
% Test a single image
run_final_detector('test_note_100_1.jpg')
```

### Batch Testing
```matlab
% Test multiple images
test_images = {
    'test_note_100_1.jpg',
    'test_note_100_2.jpg',
    'test_note_fake_1.jpg',
    'test_note_fake_colour.jpg'
};

for i = 1:length(test_images)
    run_final_detector(test_images{i});
end
```

## File Structure

### Core Detection Files (Created from Scratch)
```
warpImageAfterHomography.m  - Preprocessing pipeline
run_channel_A.m             - Template matching channel
run_channel_B.m             - Color/structure channel
run_channel_D.m             - Gabor texture channel
run_final_detector.m        - Main detector script
```

### Required Resources
```
ref_scanner.png             - Reference ₹100 note (scanner quality)
template_ashoka.jpg         - Ashoka Pillar template
template_devanagiri.jpg     - Devanagari text template
template_rbi_seal.jpg       - RBI seal template
```

### Test Images
```
test_note_100_1.jpg         - Genuine note (camera)
test_note_100_2.jpg         - Genuine note (camera)
test_note_100_3.jpg         - Genuine note (camera)
test_note_fake_1.jpg        - Counterfeit note
test_note_fake_2.jpg        - Counterfeit note
test_note_fake_3.jpg        - Counterfeit note
test_note_fake_colour.jpg   - Counterfeit note (color photocopy)
```

## Technical Specifications

### Strict No-ML Rule ✓
- **NO** Neural Networks
- **NO** Deep Learning
- **NO** Supervised ML Classifiers (SVM, Random Forest, etc.)
- **ONLY** Classical Signal Processing & Computer Vision

### Dependencies
- MATLAB Image Processing Toolbox
- Functions used:
  - `rgb2gray`, `rgb2lab`, `rgb2hsv`
  - `imrotate`, `imresize`, `imwarp`
  - `detectORBFeatures`, `extractFeatures`, `matchFeatures`
  - `estimateGeometricTransform2D`
  - `normxcorr2`, `histeq`
  - `gabor`, `imfilter`, `imregionalmax`
  - `findpeaks`, `imcrop`

## Expected Results

### Genuine Notes
- **Channel A**: 0.67 - 1.00 (most templates found)
- **Channel B**: 0.60 - 0.90 (correct thread color + bleed lines)
- **Channel D**: 1.00 (high Gabor peaks)
- **Final Score**: 0.70 - 0.95 → **GENUINE**

### Counterfeit Notes
- **Channel A**: 0.00 - 0.50 (missing/poor templates)
- **Channel B**: 0.00 - 0.40 (wrong colors, missing lines)
- **Channel D**: 0.00 (low Gabor peaks)
- **Final Score**: 0.00 - 0.50 → **COUNTERFEIT**

## Algorithm Details

### Homomorphic Filtering
- **Purpose**: Correct uneven illumination
- **Method**: Log transform → High-pass filter → Exp transform
- **Filter**: Butterworth high-pass (D0=15, order=2)

### Normalized Cross-Correlation (NCC)
- **Function**: `normxcorr2(template, image)`
- **Output**: Correlation map ∈ [-1, 1]
- **Threshold**: 0.60 for detection

### L\*a\*b\* Color Space
- **L\***: Lightness (0=black, 100=white)
- **a\***: Green-Red axis (negative=green, positive=red)
- **b\***: Blue-Yellow axis (negative=blue, positive=yellow)

### Gabor Filters
- **Purpose**: Detect oriented texture patterns
- **Parameters**: Wavelength (frequency), Orientation (angle)
- **Output**: Magnitude response (texture "landscape")

## Author
Created for ADSP Final Project - Classical Signal Processing Approach

## License
Educational Project - Indian ₹100 Note Detection System
