function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis Channel C: Paper & Texture Integrity (Gabor Analysis)
%
%   Compares Gabor texture response with ref_camera.png

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % Load reference image
    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
    ref_image = imread(ref_image_path);

    % Make sure they're the same size
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % --- STEP 1: Convert to Grayscale ---
    if size(aligned_image, 3) == 3
        test_gray = rgb2gray(aligned_image);
    else
        test_gray = aligned_image;
    end

    if size(ref_image, 3) == 3
        ref_gray = rgb2gray(ref_image);
    else
        ref_gray = ref_image;
    end

    vis_data.step1_test_grayscale = test_gray;
    vis_data.step1_ref_grayscale = ref_gray;

    % --- STEP 2: Define Gabor Filter ---
    wavelength = 4;
    orientation = 90;  % Vertical
    g_vert = gabor(wavelength, orientation);

    vis_data.gabor_wavelength = wavelength;
    vis_data.gabor_orientation = orientation;
    vis_data.gabor_kernel = g_vert.SpatialKernel;

    % --- STEP 3: Apply Gabor Filter to BOTH images ---
    test_gabor_mag = abs(imfilter(im2double(test_gray), g_vert.SpatialKernel, 'conv'));
    ref_gabor_mag = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));

    vis_data.step3_test_gabor = test_gabor_mag;
    vis_data.step3_ref_gabor = ref_gabor_mag;

    % --- STEP 4: Count Peaks in BOTH ---
    test_peaks_mask = imregionalmax(test_gabor_mag);
    ref_peaks_mask = imregionalmax(ref_gabor_mag);

    vis_data.step4_test_peaks_mask = test_peaks_mask;
    vis_data.step4_ref_peaks_mask = ref_peaks_mask;
    vis_data.step4_test_total_peaks = sum(test_peaks_mask(:));
    vis_data.step4_ref_total_peaks = sum(ref_peaks_mask(:));

    % --- STEP 5: Compare Peak Counts ---
    % Use reference peak count as baseline
    ref_peak_count = sum(ref_peaks_mask(:));
    test_peak_count = sum(test_peaks_mask(:));

    % Calculate ratio (how close to reference)
    peak_ratio = test_peak_count / ref_peak_count;

    % Score based on how close to reference (1.0 = same as ref)
    % Allow 20-120% of reference peaks
    if peak_ratio >= 0.8 && peak_ratio <= 1.2
        score = 1.0;
    elseif peak_ratio >= 0.6 && peak_ratio <= 1.4
        score = 0.7;
    elseif peak_ratio >= 0.4 && peak_ratio <= 1.6
        score = 0.4;
    else
        score = 0.0;
    end

    vis_data.step5_test_peak_count = test_peak_count;
    vis_data.step5_ref_peak_count = ref_peak_count;
    vis_data.step5_peak_ratio = peak_ratio;
    vis_data.final_score = score;

    fprintf('  Channel C: Test peaks=%d, Ref peaks=%d, Ratio=%.2f → Score=%.1f\n', ...
            test_peak_count, ref_peak_count, peak_ratio, score);

end
