function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis Channel C: Print Pattern Analysis
%
%   Looks for printer artifacts and abnormal frequency patterns.
%   Photocopies have periodic patterns from halftone printing.

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % Convert to grayscale
    test_gray = rgb2gray(aligned_image);
    ref_gray = rgb2gray(ref_image);

    vis_data.step1_test_grayscale = test_gray;

    %% METHOD 1: FFT Peak Detection (Halftone Pattern)
    % Photocopies have strong periodic patterns (printer dots)
    % These show as bright spots in FFT

    test_fft = fft2(double(test_gray));
    test_fft_shifted = fftshift(test_fft);
    test_magnitude = abs(test_fft_shifted);

    % Normalize and log scale
    test_magnitude_log = log(1 + test_magnitude);

    vis_data.method1_entropy_map = test_magnitude_log;

    % Count strong peaks in mid-frequency range
    [M, N] = size(test_magnitude);
    center_y = round(M/2);
    center_x = round(N/2);

    % Create mask for mid-frequencies (where halftone appears)
    [X, Y] = meshgrid(1:N, 1:M);
    dist = sqrt((X - center_x).^2 + (Y - center_y).^2);

    mid_freq_mask = (dist >= min(M,N)*0.1) & (dist <= min(M,N)*0.3);

    % Threshold to find peaks
    mid_freq_vals = test_magnitude(mid_freq_mask);
    threshold = mean(mid_freq_vals) + 2 * std(mid_freq_vals);

    num_peaks = sum(test_magnitude(mid_freq_mask) > threshold);
    peak_density = num_peaks / sum(mid_freq_mask(:));

    % More peaks = more periodic pattern = likely photocopy
    if peak_density < 0.01
        score_halftone = 1.0;  % Few peaks - genuine
    elseif peak_density < 0.02
        score_halftone = 0.7;
    elseif peak_density < 0.04
        score_halftone = 0.4;
    else
        score_halftone = 0.1;  % Many peaks - photocopy pattern
    end

    vis_data.num_peaks = num_peaks;
    vis_data.peak_density = peak_density;
    vis_data.score_halftone = score_halftone;

    %% METHOD 2: Gabor Filter Response Comparison
    wavelength = 4;
    orientation = 90;

    test_gabor = imgaborfilt(test_gray, wavelength, orientation);
    ref_gabor = imgaborfilt(ref_gray, wavelength, orientation);

    vis_data.step3_test_gabor = test_gabor;

    % Correlation
    gabor_corr = corr(test_gabor(:), ref_gabor(:));
    score_gabor = max(0, min(1, gabor_corr));

    vis_data.gabor_correlation = gabor_corr;
    vis_data.score_gabor = score_gabor;

    %% METHOD 3: Local Statistics Similarity
    % Compare local std maps
    test_std_map = stdfilt(test_gray, ones(11));
    ref_std_map = stdfilt(ref_gray, ones(11));

    std_corr = corr(test_std_map(:), ref_std_map(:));
    score_local_stats = max(0, std_corr);

    vis_data.step4_test_peaks_mask = test_std_map > median(test_std_map(:));
    vis_data.step5_test_peak_count = sum(vis_data.step4_test_peaks_mask(:));

    vis_data.std_correlation = std_corr;
    vis_data.score_local_stats = score_local_stats;

    %% FINAL SCORE
    score = (score_halftone * 0.40) + (score_gabor * 0.35) + (score_local_stats * 0.25);

    vis_data.final_score = score;

    fprintf('  Channel C: Halftone=%.3f (peaks=%.4f), Gabor=%.3f, LocalStat=%.3f → Final=%.3f\n', ...
        score_halftone, peak_density, score_gabor, score_local_stats, score);

end
