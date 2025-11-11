function [score, vis_data] = run_channel_B_withVis(aligned_image, ref_image_path)
%run_channel_B_withVis Channel B: Color Quality Analysis
%
%   Compares color richness and gradient smoothness against reference.
%   Photocopies have: flattened colors, banding, reduced saturation range.

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    % Load and resize reference
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    %% METHOD 1: Color Histogram Similarity
    % Genuine notes should have similar color distribution to reference
    % Photocopies will have different (often reduced) color range

    % Convert to HSV for better color analysis
    test_hsv = rgb2hsv(aligned_image);
    ref_hsv = rgb2hsv(ref_image);

    % Extract channels
    test_h = test_hsv(:,:,1);
    test_s = test_hsv(:,:,2);
    test_v = test_hsv(:,:,3);

    ref_h = ref_hsv(:,:,1);
    ref_s = ref_hsv(:,:,2);
    ref_v = ref_hsv(:,:,3);

    vis_data.method1_color = test_s;  % For GUI

    % Saturation statistics
    test_sat_mean = mean(test_s(:));
    ref_sat_mean = mean(ref_s(:));
    test_sat_std = std(test_s(:));
    ref_sat_std = std(ref_s(:));

    % Score based on saturation similarity
    sat_mean_ratio = min(test_sat_mean, ref_sat_mean) / max(test_sat_mean, ref_sat_mean);
    sat_std_ratio = min(test_sat_std, ref_sat_std) / max(test_sat_std, ref_sat_std);

    score_saturation = (sat_mean_ratio + sat_std_ratio) / 2;

    % Penalize if saturation is too low (photocopies often lose saturation)
    % But be lenient to account for lighting variations
    if test_sat_mean < 0.10
        score_saturation = score_saturation * 0.7;
    elseif test_sat_mean < 0.05
        score_saturation = score_saturation * 0.4;
    end

    vis_data.test_sat_mean = test_sat_mean;
    vis_data.ref_sat_mean = ref_sat_mean;
    vis_data.score_saturation = score_saturation;

    %% METHOD 2: Gradient Smoothness
    % Genuine notes have smooth color gradients
    % Photocopies show banding (posterization)

    % Convert to L*a*b* for perceptual analysis
    test_lab = rgb2lab(aligned_image);
    ref_lab = rgb2lab(ref_image);

    test_L = test_lab(:,:,1);
    ref_L = ref_lab(:,:,1);

    % Calculate gradients
    [test_gx, test_gy] = gradient(test_L);
    test_grad_mag = sqrt(test_gx.^2 + test_gy.^2);

    [ref_gx, ref_gy] = gradient(ref_L);
    ref_grad_mag = sqrt(ref_gx.^2 + ref_gy.^2);

    vis_data.method2_gradient = test_grad_mag;  % For GUI

    % Histogram of gradients (should be similar to reference)
    [test_hist, ~] = histcounts(test_grad_mag(:), 50);
    [ref_hist, ~] = histcounts(ref_grad_mag(:), 50);

    % Normalize histograms
    test_hist = test_hist / sum(test_hist);
    ref_hist = ref_hist / sum(ref_hist);

    % Correlation between gradient histograms
    grad_corr = corr(test_hist', ref_hist');

    score_gradient = max(0, grad_corr);  % Clamp to [0,1]

    vis_data.gradient_correlation = grad_corr;
    vis_data.score_gradient = score_gradient;

    %% METHOD 3: Color Variance in Local Regions
    % Genuine notes have rich local color variation
    % Photocopies have reduced local variation

    % Divide image into blocks and measure color variance
    block_size = 32;
    [h, w, ~] = size(aligned_image);

    test_variances = [];
    ref_variances = [];

    for y = 1:block_size:h-block_size
        for x = 1:block_size:w-block_size
            test_block = aligned_image(y:y+block_size-1, x:x+block_size-1, :);
            ref_block = ref_image(y:y+block_size-1, x:x+block_size-1, :);

            % Variance across color channels
            test_var = std(double(test_block(:)));
            ref_var = std(double(ref_block(:)));

            test_variances(end+1) = test_var;
            ref_variances(end+1) = ref_var;
        end
    end

    % Compare variance distributions
    test_var_mean = mean(test_variances);
    ref_var_mean = mean(ref_variances);

    var_ratio = min(test_var_mean, ref_var_mean) / max(test_var_mean, ref_var_mean);
    score_variance = var_ratio;

    % Boost if variance is reasonably high (not too flat)
    if test_var_mean >= 20
        score_variance = min(1.0, score_variance * 1.2);
    end

    vis_data.test_var_mean = test_var_mean;
    vis_data.ref_var_mean = ref_var_mean;
    vis_data.score_variance = score_variance;

    %% FINAL SCORE
    score = (score_saturation * 0.35) + (score_gradient * 0.40) + (score_variance * 0.25);

    vis_data.score_color = score_saturation;  % For GUI compatibility
    vis_data.final_score = score;

    fprintf('  Channel B: Sat=%.3f, Grad=%.3f, Var=%.3f → Final=%.3f\n', ...
        score_saturation, score_gradient, score_variance, score);

end
