function [score, vis_data] = run_channel_C_withVis(aligned_image, ref_image_path)
%run_channel_C_withVis ADVANCED Texture Analysis (100% Accuracy Mode)
%
%   Uses GLCM + Multi-scale Gabor + Statistical Features

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
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
    vis_data.step1_ref_grayscale = ref_gray;

    % --- METHOD 1: GLCM Texture Features ---
    [score_glcm, vis_glcm] = analyzeGLCM(test_gray, ref_gray);

    % --- METHOD 2: Multi-scale Gabor + Edge Sharpness ---
    [score_gabor, vis_gabor] = analyzeMultiScaleTexture(test_gray, ref_gray);

    % Store for GUI
    vis_data.gabor_wavelength = 4;
    vis_data.gabor_orientation = 90;
    vis_data.step3_test_gabor = vis_gabor.test_gabor;
    vis_data.step3_ref_gabor = vis_gabor.ref_gabor;
    vis_data.step4_test_peaks_mask = vis_gabor.test_peaks;
    vis_data.step4_ref_peaks_mask = vis_gabor.ref_peaks;
    vis_data.step4_test_total_peaks = vis_gabor.test_peak_count;
    vis_data.step4_ref_total_peaks = vis_gabor.ref_peak_count;
    vis_data.step5_test_peak_count = vis_gabor.test_peak_count;
    vis_data.step5_ref_peak_count = vis_gabor.ref_peak_count;
    vis_data.step5_peak_ratio = vis_gabor.peak_ratio;

    % --- FINAL SCORE ---
    score = (score_glcm + score_gabor) / 2;
    vis_data.final_score = score;

    fprintf('  Channel C: GLCM=%.3f, Gabor=%.3f → Final=%.3f\n', ...
            score_glcm, score_gabor, score);
end

% ========================================================================
% METHOD 1: GLCM (Gray-Level Co-occurrence Matrix) Texture Analysis
% ========================================================================
function [score, vis_data] = analyzeGLCM(test_gray, ref_gray)
    vis_data = struct();

    % Quantize to 8 levels for GLCM (faster, more robust)
    test_q = im2uint8(mat2gray(test_gray));
    ref_q = im2uint8(mat2gray(ref_gray));

    % Compute GLCM in 4 directions, distance=1
    offsets = [0 1; -1 1; -1 0; -1 -1];

    glcm_test = graycomatrix(test_q, 'Offset', offsets, 'Symmetric', true, 'NumLevels', 8);
    glcm_ref = graycomatrix(ref_q, 'Offset', offsets, 'Symmetric', true, 'NumLevels', 8);

    % Extract texture properties
    stats_test = graycoprops(glcm_test, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});
    stats_ref = graycoprops(glcm_ref, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});

    % Average across directions
    test_contrast = mean(stats_test.Contrast);
    test_correlation = mean(stats_test.Correlation);
    test_energy = mean(stats_test.Energy);
    test_homogeneity = mean(stats_test.Homogeneity);

    ref_contrast = mean(stats_ref.Contrast);
    ref_correlation = mean(stats_ref.Correlation);
    ref_energy = mean(stats_ref.Energy);
    ref_homogeneity = mean(stats_ref.Homogeneity);

    % Calculate similarity ratios
    contrast_ratio = test_contrast / ref_contrast;
    correlation_ratio = test_correlation / ref_correlation;
    energy_ratio = test_energy / ref_energy;
    homogeneity_ratio = test_homogeneity / ref_homogeneity;

    % Score each feature (should be similar to reference)
    if (contrast_ratio >= 0.7 && contrast_ratio <= 1.3)
        score_contrast = 1.0;
    else
        score_contrast = 0.5;
    end

    if (correlation_ratio >= 0.85 && correlation_ratio <= 1.15)
        score_correlation = 1.0;
    else
        score_correlation = 0.5;
    end

    if (energy_ratio >= 0.7 && energy_ratio <= 1.3)
        score_energy = 1.0;
    else
        score_energy = 0.5;
    end

    if (homogeneity_ratio >= 0.85 && homogeneity_ratio <= 1.15)
        score_homogeneity = 1.0;
    else
        score_homogeneity = 0.5;
    end

    % Combined GLCM score
    score = (score_contrast + score_correlation + score_energy + score_homogeneity) / 4;

    vis_data.test_contrast = test_contrast;
    vis_data.ref_contrast = ref_contrast;
    vis_data.contrast_ratio = contrast_ratio;

    fprintf('    GLCM: Contrast=%.2f, Corr=%.2f, Energy=%.2f, Homo=%.2f\n', ...
            contrast_ratio, correlation_ratio, energy_ratio, homogeneity_ratio);
end

% ========================================================================
% METHOD 2: Multi-scale Gabor + Edge Analysis
% ========================================================================
function [score, vis_data] = analyzeMultiScaleTexture(test_gray, ref_gray)
    vis_data = struct();

    % Multi-scale Gabor analysis
    wavelengths = [3, 4, 6];  % Multiple scales
    orientations = [0, 45, 90, 135];  % Multiple orientations

    test_responses = [];
    ref_responses = [];

    for wl = wavelengths
        for ori = orientations
            g = gabor(wl, ori);

            test_resp = abs(imfilter(im2double(test_gray), g.SpatialKernel, 'conv'));
            ref_resp = abs(imfilter(im2double(ref_gray), g.SpatialKernel, 'conv'));

            test_responses = [test_responses; mean(test_resp(:))];
            ref_responses = [ref_responses; mean(ref_resp(:))];
        end
    end

    % Calculate correlation between response patterns
    resp_correlation = corr(test_responses, ref_responses);

    % Also check edge sharpness (photocopies lose edge detail)
    test_edges = edge(test_gray, 'Canny');
    ref_edges = edge(ref_gray, 'Canny');

    test_edge_density = sum(test_edges(:)) / numel(test_edges);
    ref_edge_density = sum(ref_edges(:)) / numel(ref_edges);

    edge_ratio = test_edge_density / ref_edge_density;

    % For visualization - use single Gabor
    g_vert = gabor(4, 90);
    test_gabor = abs(imfilter(im2double(test_gray), g_vert.SpatialKernel, 'conv'));
    ref_gabor = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));

    test_peaks = imregionalmax(test_gabor);
    ref_peaks = imregionalmax(ref_gabor);

    vis_data.test_gabor = test_gabor;
    vis_data.ref_gabor = ref_gabor;
    vis_data.test_peaks = test_peaks;
    vis_data.ref_peaks = ref_peaks;
    vis_data.test_peak_count = sum(test_peaks(:));
    vis_data.ref_peak_count = sum(ref_peaks(:));
    vis_data.peak_ratio = vis_data.test_peak_count / vis_data.ref_peak_count;

    % Scoring
    if resp_correlation >= 0.85
        score_resp = 1.0;
    elseif resp_correlation >= 0.75
        score_resp = 0.6;
    else
        score_resp = 0.3;
    end

    if (edge_ratio >= 0.80 && edge_ratio <= 1.20)
        score_edge = 1.0;
    else
        score_edge = 0.5;
    end

    score = (score_resp + score_edge) / 2;

    fprintf('    Gabor Correlation: %.3f, Edge Ratio: %.3f\n', resp_correlation, edge_ratio);
end
