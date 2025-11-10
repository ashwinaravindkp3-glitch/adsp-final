function score = run_channel_D(aligned_image)
%run_channel_D Channel C/D: Paper & Micro-Texture Integrity (Gabor Peaks)
%
%   Applies vertically-oriented Gabor filter to detect paper texture.
%   Counts significant local peaks above a fixed threshold.
%
%   Method:
%   1. Convert to grayscale
%   2. Apply vertical Gabor filter (wavelength=4, orientation=90°)
%   3. Find local maxima (imregionalmax)
%   4. Count peaks above fixed threshold (0.1)
%   5. Return 1.0 if peak_count > 500, else 0.0 (binary verdict)
%
%   Inputs:
%       aligned_image - Preprocessed, aligned color image
%
%   Outputs:
%       score - Binary score: 1.0 (REAL) or 0.0 (FAKE)

    fprintf('\n--- Channel D: Gabor Texture Analysis ---\n');

    % --- STEP 1: Convert to Grayscale ---
    if size(aligned_image, 3) == 3
        gray_img = rgb2gray(aligned_image);
    else
        gray_img = aligned_image;
    end

    % --- STEP 2: Define Vertically-Oriented Gabor Filter ---
    wavelength = 4;        % Wavelength in pixels
    orientation = 90;      % Vertical orientation (degrees)
    g_vert = gabor(wavelength, orientation);

    fprintf('  Gabor Filter: wavelength=%d, orientation=%d°\n', wavelength, orientation);

    % --- STEP 3: Apply Gabor Filter ---
    gabor_magnitude = abs(imfilter(im2double(gray_img), g_vert.SpatialKernel, 'conv'));

    % --- STEP 4: Find Local Maxima (Regional Max) ---
    peaks_mask = imregionalmax(gabor_magnitude);

    % --- STEP 5: Count Peaks Above Fixed Threshold ---
    fixed_threshold = 0.1;  % Absolute threshold
    significant_peaks = gabor_magnitude(peaks_mask) > fixed_threshold;
    peak_count = sum(significant_peaks);

    fprintf('  Peaks detected: %d\n', peak_count);
    fprintf('  Threshold: %.2f\n', fixed_threshold);

    % --- STEP 6: Binary Verdict ---
    peak_threshold = 500;  % Minimum peaks for genuine note
    if peak_count > peak_threshold
        score = 1.0;
        verdict = 'REAL';
    else
        score = 0.0;
        verdict = 'FAKE';
    end

    fprintf('  Verdict: %s (Score: %.1f)\n', verdict, score);
end
