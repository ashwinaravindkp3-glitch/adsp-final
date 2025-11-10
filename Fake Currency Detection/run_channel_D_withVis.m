function [score, vis_data] = run_channel_D_withVis(aligned_image)
%run_channel_D_withVis Channel D with visualization outputs

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % --- STEP 1: Convert to Grayscale ---
    if size(aligned_image, 3) == 3
        gray_img = rgb2gray(aligned_image);
    else
        gray_img = aligned_image;
    end

    vis_data.step1_grayscale = gray_img;

    % --- STEP 2: Define Gabor Filter ---
    wavelength = 4;
    orientation = 90;
    g_vert = gabor(wavelength, orientation);

    vis_data.gabor_wavelength = wavelength;
    vis_data.gabor_orientation = orientation;
    vis_data.gabor_kernel = g_vert.SpatialKernel;

    % --- STEP 3: Apply Gabor Filter ---
    gabor_magnitude = abs(imfilter(im2double(gray_img), g_vert.SpatialKernel, 'conv'));

    vis_data.step3_gabor_magnitude = gabor_magnitude;

    % --- STEP 4: Find Local Maxima ---
    peaks_mask = imregionalmax(gabor_magnitude);

    vis_data.step4_peaks_mask = peaks_mask;
    vis_data.step4_total_peaks = sum(peaks_mask(:));

    % --- STEP 5: Count Significant Peaks ---
    fixed_threshold = 0.1;
    significant_peaks = gabor_magnitude(peaks_mask) > fixed_threshold;
    peak_count = sum(significant_peaks);

    vis_data.step5_threshold = fixed_threshold;
    vis_data.step5_peak_count = peak_count;

    % Create visualization of significant peaks
    sig_peaks_mask = zeros(size(peaks_mask));
    peak_values = gabor_magnitude(peaks_mask);
    peak_indices = find(peaks_mask);
    sig_indices = peak_indices(peak_values > fixed_threshold);
    sig_peaks_mask(sig_indices) = 1;

    vis_data.step5_significant_peaks_mask = sig_peaks_mask;

    % --- STEP 6: Binary Verdict ---
    peak_threshold = 500;
    if peak_count > peak_threshold
        score = 1.0;
        verdict = 'REAL';
    else
        score = 0.0;
        verdict = 'FAKE';
    end

    vis_data.step6_peak_threshold = peak_threshold;
    vis_data.step6_verdict = verdict;
    vis_data.final_score = score;

end
