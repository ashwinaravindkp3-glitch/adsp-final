# Currency Detector GUI - User Guide
## ADSP Final Project

---

## 🚀 QUICK START (30 seconds)

### Method 1: Simple GUI (RECOMMENDED)

```matlab
% 1. Navigate to project folder
cd 'Fake Currency Detection'

% 2. Launch GUI
SimpleCurrencyGUI

% 3. Click "Upload Image" → Select test image
% 4. Click "RUN DETECTION" → Wait 10-30 seconds
% 5. View results in tabs!
```

---

## 📁 File Overview

### **Main Files to Use:**

| File | Purpose |
|------|---------|
| `SimpleCurrencyGUI.m` | **Main GUI** - Use this! |
| `detect_with_all_visualizations.m` | Detection engine with all outputs |
| `warpImageAfterHomography_withVis.m` | Preprocessing with visualizations |
| `run_channel_A_withVis.m` | Channel A with visualizations |
| `run_channel_B_withVis.m` | Channel B with visualizations |
| `run_channel_D_withVis.m` | Channel D with visualizations |

### **Test Images Available:**

**Genuine Notes:**
- `test_note_100_1.jpg` ✓
- `test_note_100_2.jpg` ✓
- `test_note_100_3.jpg` ✓

**Counterfeit Notes:**
- `test_note_fake_1.jpg` ✗
- `test_note_fake_2.jpg` ✗
- `test_note_fake_3.jpg` ✗
- `test_note_fake_colour.jpg` ✗

---

## 🎯 GUI Features

### Tab 1: PREPROCESSING
Shows the complete preprocessing pipeline:

1. **Original Image** - Input as loaded
2. **Rotated** - After orientation correction (if needed)
3. **Resized** - Scaled to match reference height
4. **Grayscale** - Converted for feature detection
5. **Features** - ORB feature points matched (green crosses)
6. **Aligned** - Final warped and aligned image

**What to Look For:**
- Green feature points should be distributed across the note
- Aligned image should match reference dimensions
- More feature matches = better alignment (typically 500-2000 matches)

### Tab 2: CHANNEL A - Template Matching
Graphical integrity using Normalized Cross-Correlation:

1. **Illumination Normalized** - After homomorphic filtering
2. **Histogram Equalized** - Enhanced contrast
3. **Templates** - Reference templates being matched
4. **Correlation Maps** - NCC response (brighter = better match)

**What to Look For:**
- Bright spots in correlation maps indicate detection
- Score shows ratio of templates found (e.g., 2/3 = 0.67)
- Genuine notes: 0.67-1.00
- Fake notes: 0.00-0.50

### Tab 3: CHANNEL B - Color & Structure
Security thread and bleed lines analysis:

1. **Security Thread ROI** - Extracted green thread region
2. **a* Channel** - L*a*b* color space (negative = green)
3. **Left Bleed Lines** - ROI showing left side lines
4. **Right Bleed Lines** - Projection with detected peaks

**What to Look For:**
- Security thread should be green (negative a* values)
- Bleed lines should show exactly 4 peaks on each side
- Genuine notes: Thread score ~0.6-0.9, Lines score = 1.0
- Fake notes: Thread score ~0.0-0.4, Lines score = 0.0

### Tab 4: CHANNEL D - Gabor Texture
Paper texture analysis using Gabor filters:

1. **Grayscale** - Input for texture analysis
2. **Gabor Response** - Filter output (texture "landscape")
3. **All Peaks** - All local maxima detected
4. **Significant Peaks** - Peaks above threshold (0.1)

**What to Look For:**
- Gabor response shows texture patterns
- Significant peaks count indicates paper quality
- Genuine notes: >500 peaks (Score = 1.0)
- Fake notes: <500 peaks (Score = 0.0)

### Tab 5: FINAL RESULTS
Decision fusion and verdict:

1. **Scores Bar Chart** - Individual channel scores
2. **Fusion Pie Chart** - Weighted contributions

**Final Score Calculation:**
```
Final Score = 0.40 × Channel_A + 0.40 × Channel_B + 0.20 × Channel_D
```

**Verdict:**
- Score ≥ 0.65 → **GENUINE** ✓
- Score < 0.65 → **COUNTERFEIT** ✗

---

## 📊 Expected Results

### Genuine Notes

| Channel | Expected Score | Key Indicators |
|---------|---------------|----------------|
| **A** | 0.67 - 1.00 | 2-3 templates detected |
| **B** | 0.60 - 0.90 | Green thread + 4 lines each side |
| **D** | 1.00 | >500 Gabor peaks |
| **Final** | 0.70 - 0.95 | **GENUINE** |

### Counterfeit Notes

| Channel | Expected Score | Key Indicators |
|---------|---------------|----------------|
| **A** | 0.00 - 0.50 | Missing/poor templates |
| **B** | 0.00 - 0.40 | Wrong colors, missing lines |
| **D** | 0.00 | <500 Gabor peaks |
| **Final** | 0.00 - 0.50 | **COUNTERFEIT** |

---

## 🛠️ Troubleshooting

### Error: "Not enough matched points for homography"
**Problem:** Feature matching failed
**Solution:**
- Use better quality image
- Ensure image is not too blurry
- Check that image shows full currency note

### Error: "Cannot find template file"
**Problem:** Template images missing
**Solution:**
- Ensure you're in the correct folder: `cd 'Fake Currency Detection'`
- Check that template files exist: `dir template_*.jpg`

### GUI doesn't show images
**Problem:** Visualization error
**Solution:**
- Check MATLAB version (R2019a or later recommended)
- Ensure Image Processing Toolbox is installed
- Try closing and reopening the GUI

### Detection takes very long (>2 minutes)
**Problem:** Large image size
**Solution:**
- Resize image before uploading (recommended: 2000x1000 pixels)
- Image is automatically resized during preprocessing

---

## 🎓 For Professor Evaluation

### Key Signal Processing Techniques Demonstrated:

1. **ORB Feature Detection** (STEP 1)
   - Binary feature descriptor
   - Scale and rotation invariant
   - 5000+ features detected

2. **Homography Estimation** (STEP 1)
   - RANSAC-based geometric transformation
   - Projective transformation
   - Handles perspective distortion

3. **Homomorphic Filtering** (STEP 2)
   - Log transform → Frequency filtering → Exp transform
   - Illumination correction
   - Butterworth high-pass filter

4. **Normalized Cross-Correlation** (STEP 2)
   - Template matching in frequency domain
   - Normalized to [-1, 1]
   - Threshold-based detection

5. **L*a*b* Color Space Analysis** (STEP 3)
   - Perceptually uniform color space
   - Green-red axis (a*) analysis
   - Saturation in HSV space

6. **1D Signal Processing** (STEP 3)
   - Horizontal projection of 2D image
   - Peak detection with findpeaks
   - Counting periodic structures

7. **Gabor Filtering** (STEP 4)
   - Oriented frequency-selective filter
   - Texture analysis
   - Multi-scale representation

8. **Local Maxima Detection** (STEP 4)
   - imregionalmax for peak finding
   - Threshold-based filtering
   - Spatial feature extraction

9. **Decision Fusion** (STEP 5)
   - Weighted average of independent channels
   - Threshold-based classification
   - Multi-modal sensor fusion

### NO Machine Learning Used ✓
- No neural networks
- No deep learning
- No supervised classifiers (SVM, RF, etc.)
- Pure classical signal processing

---

## 💡 Tips for Best Results

1. **Image Quality:**
   - Use well-lit images
   - Avoid shadows
   - Keep note flat (no folds)
   - Full note should be visible

2. **Running Detection:**
   - Wait patiently (10-30 seconds)
   - Don't click buttons multiple times
   - Check all tabs after detection

3. **Understanding Results:**
   - Look at intermediate visualizations
   - Check which channel failed (if any)
   - Compare genuine vs. fake patterns

---

## 📞 Support

For issues or questions:
1. Check `README.md` for algorithm details
2. Read error messages carefully
3. Verify all files are in correct folder
4. Check MATLAB version and toolboxes

---

## ⚡ Quick Reference Commands

```matlab
% Launch GUI
SimpleCurrencyGUI

% Test without GUI (command line)
[verdict, score, vis] = detect_with_all_visualizations('test_note_100_1.jpg');

% Display specific visualization
imagesc(vis.channel_D.step3_gabor_magnitude); colorbar;

% Check scores
disp(vis.scores);

% View final verdict
fprintf('Verdict: %s (Score: %.4f)\n', vis.fusion.verdict, vis.fusion.final_score);
```

---

## 📚 Additional Documentation

- `README.md` - Complete technical documentation
- `test_batch.m` - Batch testing script
- MATLAB help: `help SimpleCurrencyGUI`

---

**Good luck with your ADSP project demonstration!** 🎓
