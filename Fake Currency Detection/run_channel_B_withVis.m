function [score, vis_data] = run_channel_B_withVis(aligned_color_image, ref_image_path)
%run_channel_B_withVis Channel B: Color & Structure Analysis (FULL IMAGE)
%
%   Analyzes ENTIRE image instead of specific ROIs
%   Compares with ref_camera.png

    vis_data = struct();
    vis_data.input_image = aligned_color_image;

    % Load reference image
    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
    ref_image = imread(ref_image_path);

    % Make sure they're the same size
    ref_image = imresize(ref_image, size(aligned_color_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % --- METHOD 1: Color Distribution Analysis ---
    [score_color, vis_color] = analyzeColorDistribution(aligned_color_image, ref_image);
    vis_data.method1_color = vis_color;
    vis_data.score_color = score_color;

    % --- METHOD 2: Gradient/Edge Analysis ---
    [score_gradient, vis_gradient] = analyzeGradientSimilarity(aligned_color_image, ref_image);
    vis_data.method2_gradient = vis_gradient;
    vis_data.score_gradient = score_gradient;

    % --- FINAL SCORE ---
    score = (score_color + score_gradient) / 2;
    vis_data.final_score = score;

    fprintf('  Channel B: Color=%.3f, Gradient=%.3f → Final=%.3f\n', ...
            score_color, score_gradient, score);

end

% ========================================================================
% METHOD 1: Color Distribution Analysis
% ========================================================================
function [score, vis_data] = analyzeColorDistribution(test_img, ref_img)
    vis_data = struct();

    % Convert to L*a*b* for perceptually uniform color space
    test_lab = rgb2lab(test_img);
    ref_lab = rgb2lab(ref_img);

    % Extract channels
    test_L = test_lab(:,:,1);
    test_a = test_lab(:,:,2);
    test_b = test_lab(:,:,3);

    ref_L = ref_lab(:,:,1);
    ref_a = ref_lab(:,:,2);
    ref_b = ref_lab(:,:,3);

    vis_data.test_L = test_L;
    vis_data.test_a = test_a;
    vis_data.ref_a = ref_a;

    % Compute histograms for each channel
    [hist_test_L, ~] = imhist(uint8(mat2gray(test_L) * 255), 64);
    [hist_ref_L, ~] = imhist(uint8(mat2gray(ref_L) * 255), 64);

    [hist_test_a, ~] = imhist(uint8(mat2gray(test_a) * 255), 64);
    [hist_ref_a, ~] = imhist(uint8(mat2gray(ref_a) * 255), 64);

    [hist_test_b, ~] = imhist(uint8(mat2gray(test_b) * 255), 64);
    [hist_ref_b, ~] = imhist(uint8(mat2gray(ref_b) * 255), 64);

    % Normalize histograms
    hist_test_L = hist_test_L / sum(hist_test_L);
    hist_ref_L = hist_ref_L / sum(hist_ref_L);
    hist_test_a = hist_test_a / sum(hist_test_a);
    hist_ref_a = hist_ref_a / sum(hist_ref_a);
    hist_test_b = hist_test_b / sum(hist_test_b);
    hist_ref_b = hist_ref_b / sum(hist_ref_b);

    vis_data.hist_test_a = hist_test_a;
    vis_data.hist_ref_a = hist_ref_a;

    % Compute histogram correlation (similarity measure)
    corr_L = sum(sqrt(hist_test_L .* hist_ref_L));
    corr_a = sum(sqrt(hist_test_a .* hist_ref_a));
    corr_b = sum(sqrt(hist_test_b .* hist_ref_b));

    % Average correlation across channels
    score = (corr_L + corr_a + corr_b) / 3;

    vis_data.corr_L = corr_L;
    vis_data.corr_a = corr_a;
    vis_data.corr_b = corr_b;
    vis_data.final_score = score;

    fprintf('    Color: L=%.3f, a=%.3f, b=%.3f\n', corr_L, corr_a, corr_b);
end

% ========================================================================
% METHOD 2: Gradient/Edge Similarity
% ========================================================================
function [score, vis_data] = analyzeGradientSimilarity(test_img, ref_img)
    vis_data = struct();

    % Convert to grayscale
    test_gray = rgb2gray(test_img);
    ref_gray = rgb2gray(ref_img);

    vis_data.test_gray = test_gray;
    vis_data.ref_gray = ref_gray;

    % Compute gradients
    [test_Gx, test_Gy] = imgradientxy(test_gray);
    [ref_Gx, ref_Gy] = imgradientxy(ref_gray);

    test_Gmag = sqrt(test_Gx.^2 + test_Gy.^2);
    ref_Gmag = sqrt(ref_Gx.^2 + ref_Gy.^2);

    vis_data.test_gradient = test_Gmag;
    vis_data.ref_gradient = ref_Gmag;

    % Compute histogram of gradient magnitudes
    [hist_test, ~] = imhist(uint8(mat2gray(test_Gmag) * 255), 64);
    [hist_ref, ~] = imhist(uint8(mat2gray(ref_Gmag) * 255), 64);

    % Normalize
    hist_test = hist_test / sum(hist_test);
    hist_ref = hist_ref / sum(hist_ref);

    vis_data.hist_test_gradient = hist_test;
    vis_data.hist_ref_gradient = hist_ref;

    % Compute histogram correlation
    score = sum(sqrt(hist_test .* hist_ref));

    vis_data.final_score = score;

    fprintf('    Gradient similarity: %.3f\n', score);
end
