function [score, vis_data] = run_channel_B_withVis(aligned_image, ref_image_path)
%run_channel_B_withVis Channel B: Difference Pattern Analysis
%
%   Analyzes HOW the test image differs from reference.
%   Genuine: Random differences (lighting, wear)
%   Photocopy: Systematic differences (color shift, detail loss)

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    % Load reference
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    %% METHOD 1: Color Difference Analysis
    % Convert both to L*a*b* (perceptual color space)
    test_lab = rgb2lab(aligned_image);
    ref_lab = rgb2lab(ref_image);

    test_L = test_lab(:,:,1);
    test_a = test_lab(:,:,2);
    test_b = test_lab(:,:,3);

    ref_L = ref_lab(:,:,1);
    ref_a = ref_lab(:,:,2);
    ref_b = ref_lab(:,:,3);

    % Color difference map
    delta_E = sqrt((test_L - ref_L).^2 + (test_a - ref_a).^2 + (test_b - ref_b).^2);

    vis_data.method1_color = delta_E;  % Difference map

    % Statistics of color differences
    mean_delta_E = mean(delta_E(:));
    std_delta_E = std(delta_E(:));

    % Genuine notes: Moderate mean (lighting), high std (random)
    % Photocopies: High mean (color shift), low std (systematic)

    % Score based on whether differences look random or systematic
    if mean_delta_E < 15
        score_color_mean = 1.0;  % Small differences - good
    elseif mean_delta_E < 25
        score_color_mean = 0.7;  % Moderate differences
    elseif mean_delta_E < 35
        score_color_mean = 0.4;  % Large differences - likely photocopy
    else
        score_color_mean = 0.1;  % Very different - definitely photocopy
    end

    % Higher std = more random = genuine
    if std_delta_E >= 12
        score_color_std = 1.0;
    elseif std_delta_E >= 8
        score_color_std = 0.7;
    else
        score_color_std = 0.3;  % Too uniform - systematic shift
    end

    score_color = (score_color_mean + score_color_std) / 2;

    vis_data.mean_delta_E = mean_delta_E;
    vis_data.std_delta_E = std_delta_E;
    vis_data.score_color = score_color;

    %% METHOD 2: Detail Preservation
    % Compare high-frequency content
    test_gray = rgb2gray(aligned_image);
    ref_gray = rgb2gray(ref_image);

    % High-pass filter to get details
    h = fspecial('gaussian', 15, 3);
    test_lowpass = imfilter(test_gray, h);
    ref_lowpass = imfilter(ref_gray, h);

    test_detail = double(test_gray) - double(test_lowpass);
    ref_detail = double(ref_gray) - double(ref_lowpass);

    vis_data.method2_gradient = abs(test_detail);  % For visualization

    % Measure detail energy
    test_detail_energy = std(test_detail(:));
    ref_detail_energy = std(ref_detail(:));

    detail_ratio = test_detail_energy / ref_detail_energy;

    % Photocopies lose detail (ratio < 0.7)
    if detail_ratio >= 0.85
        score_detail = 1.0;
    elseif detail_ratio >= 0.7
        score_detail = 0.7;
    elseif detail_ratio >= 0.5
        score_detail = 0.4;
    else
        score_detail = 0.1;  % Major detail loss - photocopy
    end

    vis_data.test_detail_energy = test_detail_energy;
    vis_data.ref_detail_energy = ref_detail_energy;
    vis_data.detail_ratio = detail_ratio;
    vis_data.score_detail = score_detail;

    %% METHOD 3: Texture Correlation
    % Measure how well textures match
    test_texture = stdfilt(test_gray, ones(9));
    ref_texture = stdfilt(ref_gray, ones(9));

    texture_corr = corr(test_texture(:), ref_texture(:));
    score_texture = max(0, texture_corr);

    vis_data.texture_correlation = texture_corr;
    vis_data.score_texture = score_texture;

    %% FINAL SCORE
    score = (score_color * 0.40) + (score_detail * 0.35) + (score_texture * 0.25);

    vis_data.final_score = score;

    fprintf('  Channel B: Color=%.3f (ΔE=%.1f±%.1f), Detail=%.3f (%.2f), Texture=%.3f → Final=%.3f\n', ...
        score_color, mean_delta_E, std_delta_E, score_detail, detail_ratio, score_texture, score);

end
