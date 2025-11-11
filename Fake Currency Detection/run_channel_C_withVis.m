function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis Channel C: Print Quality & Halftone Detection
%
%   Detects printer artifacts and compares texture quality with reference.
%   Photocopies have: halftone dots, periodic patterns, different texture.

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    % Load and resize reference
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % Convert to grayscale
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

    %% METHOD 1: Frequency Domain Analysis - Halftone Detection
    % Photocopies often have periodic halftone patterns
    % These show up as peaks in frequency domain

    % FFT of test image
    test_fft = fft2(double(test_gray));
    test_fft_shifted = fftshift(test_fft);
    test_magnitude = abs(test_fft_shifted);

    % FFT of reference
    ref_fft = fft2(double(ref_gray));
    ref_fft_shifted = fftshift(ref_fft);
    ref_magnitude = abs(ref_fft_shifted);

    vis_data.method1_entropy_map = log(1 + test_magnitude);  % For visualization

    % Remove DC component and analyze mid-frequency range
    % (where halftone patterns appear)
    [M, N] = size(test_magnitude);
    center_y = round(M/2);
    center_x = round(N/2);

    % Create annular mask for mid-frequencies
    [X, Y] = meshgrid(1:N, 1:M);
    dist = sqrt((X - center_x).^2 + (Y - center_y).^2);

    inner_radius = min(M, N) * 0.05;
    outer_radius = min(M, N) * 0.25;
    mid_freq_mask = (dist >= inner_radius) & (dist <= outer_radius);

    % Energy in mid-frequency range
    test_mid_energy = sum(test_magnitude(mid_freq_mask).^2);
    ref_mid_energy = sum(ref_magnitude(mid_freq_mask).^2);

    test_total_energy = sum(test_magnitude(:).^2);
    ref_total_energy = sum(ref_magnitude(:).^2);

    test_mid_ratio = test_mid_energy / test_total_energy;
    ref_mid_ratio = ref_mid_energy / ref_total_energy;

    % Photocopies often have HIGHER mid-frequency energy (halftone dots)
    % So penalize if test has much more than reference
    if test_mid_ratio > ref_mid_ratio * 1.5
        score_halftone = 0.3;  % Likely photocopy
    elseif test_mid_ratio > ref_mid_ratio * 1.2
        score_halftone = 0.6;
    else
        score_halftone = 1.0;  % Good - similar to reference
    end

    vis_data.test_mid_ratio = test_mid_ratio;
    vis_data.ref_mid_ratio = ref_mid_ratio;
    vis_data.score_halftone = score_halftone;

    %% METHOD 2: Texture Similarity using Gabor Filters
    % Compare texture patterns with reference

    wavelength = 4;
    orientation = 90;

    % Apply Gabor filter
    test_gabor = imgaborfilt(test_gray, wavelength, orientation);
    ref_gabor = imgaborfilt(ref_gray, wavelength, orientation);

    vis_data.step3_test_gabor = test_gabor;

    % Compute correlation between Gabor responses
    test_gabor_vec = test_gabor(:);
    ref_gabor_vec = ref_gabor(:);

    gabor_corr = corr(test_gabor_vec, ref_gabor_vec);
    score_texture = max(0, gabor_corr);

    vis_data.gabor_correlation = gabor_corr;
    vis_data.score_texture = score_texture;

    %% METHOD 3: Detail Preservation Check
    % Measure how much fine detail is preserved compared to reference

    % Use Sobel edge detection
    test_edges = edge(test_gray, 'Sobel');
    ref_edges = edge(ref_gray, 'Sobel');

    test_edge_density = sum(test_edges(:)) / numel(test_edges);
    ref_edge_density = sum(ref_edges(:)) / numel(ref_edges);

    vis_data.step4_test_peaks_mask = test_edges;  % For visualization
    vis_data.step5_test_peak_count = sum(test_edges(:));

    % Edge density should be similar to reference
    edge_ratio = min(test_edge_density, ref_edge_density) / max(test_edge_density, ref_edge_density);

    % But also check if it's not too low (photocopies lose edges)
    if test_edge_density < ref_edge_density * 0.7
        score_detail = edge_ratio * 0.6;  % Penalize loss of detail
    else
        score_detail = edge_ratio;
    end

    vis_data.test_edge_density = test_edge_density;
    vis_data.ref_edge_density = ref_edge_density;
    vis_data.score_detail = score_detail;

    %% METHOD 4: Local Binary Pattern Similarity
    % Compare micro-texture patterns

    % Simple LBP-like feature: count sign changes in local neighborhoods
    test_lbp_score = computeLocalPatternScore(test_gray);
    ref_lbp_score = computeLocalPatternScore(ref_gray);

    lbp_ratio = min(test_lbp_score, ref_lbp_score) / max(test_lbp_score, ref_lbp_score);
    score_pattern = lbp_ratio;

    vis_data.test_lbp_score = test_lbp_score;
    vis_data.ref_lbp_score = ref_lbp_score;
    vis_data.score_pattern = score_pattern;

    %% FINAL SCORE
    score = (score_halftone * 0.30) + (score_texture * 0.30) + ...
            (score_detail * 0.25) + (score_pattern * 0.15);

    vis_data.final_score = score;

    fprintf('  Channel C: Halftone=%.3f, Texture=%.3f, Detail=%.3f, Pattern=%.3f → Final=%.3f\n', ...
        score_halftone, score_texture, score_detail, score_pattern, score);

end

function lbp_score = computeLocalPatternScore(gray_img)
    % Compute a simple texture complexity score
    % Higher values = more complex texture patterns

    % Use stdfilt to measure local variation
    std_map = stdfilt(gray_img, ones(5));
    lbp_score = mean(std_map(:));
end
