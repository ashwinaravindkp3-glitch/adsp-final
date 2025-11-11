function [score, vis_data] = run_channel_B_withVis(aligned_image, ref_image_path)
%run_channel_B_withVis Channel B: Color Channel Analysis
%
%   Analyzes mean values of Saturation, Red, and Green channels
%   Compares with reference image

    vis_data = struct();
    vis_data.input_image = aligned_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end

    % Load reference
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_image(:,:,1)));
    vis_data.reference_image = ref_image;

    %% Extract RGB channels
    test_R = aligned_image(:,:,1);
    test_G = aligned_image(:,:,2);
    test_B = aligned_image(:,:,3);

    ref_R = ref_image(:,:,1);
    ref_G = ref_image(:,:,2);
    ref_B = ref_image(:,:,3);

    vis_data.test_R = test_R;
    vis_data.test_G = test_G;
    vis_data.test_B = test_B;

    %% Convert to HSV for saturation
    test_hsv = rgb2hsv(aligned_image);
    ref_hsv = rgb2hsv(ref_image);

    test_S = test_hsv(:,:,2);
    ref_S = ref_hsv(:,:,2);

    vis_data.method1_color = test_S;  % For GUI visualization

    %% Calculate mean values
    mean_test_R = mean(test_R(:));
    mean_test_G = mean(test_G(:));
    mean_test_S = mean(test_S(:));

    mean_ref_R = mean(ref_R(:));
    mean_ref_G = mean(ref_G(:));
    mean_ref_S = mean(ref_S(:));

    vis_data.mean_test_R = mean_test_R;
    vis_data.mean_test_G = mean_test_G;
    vis_data.mean_test_S = mean_test_S;

    vis_data.mean_ref_R = mean_ref_R;
    vis_data.mean_ref_G = mean_ref_G;
    vis_data.mean_ref_S = mean_ref_S;

    fprintf('  Test: R=%.2f, G=%.2f, S=%.4f\n', mean_test_R, mean_test_G, mean_test_S);
    fprintf('  Ref:  R=%.2f, G=%.2f, S=%.4f\n', mean_ref_R, mean_ref_G, mean_ref_S);

    %% Score based on similarity to reference
    % Use ratio (closer to 1.0 = better)

    % Red channel score
    ratio_R = min(mean_test_R, mean_ref_R) / max(mean_test_R, mean_ref_R);
    score_R = ratio_R;

    % Green channel score
    ratio_G = min(mean_test_G, mean_ref_G) / max(mean_test_G, mean_ref_G);
    score_G = ratio_G;

    % Saturation channel score
    ratio_S = min(mean_test_S, mean_ref_S) / max(mean_test_S, mean_ref_S);
    score_S = ratio_S;

    vis_data.ratio_R = ratio_R;
    vis_data.ratio_G = ratio_G;
    vis_data.ratio_S = ratio_S;

    vis_data.score_R = score_R;
    vis_data.score_G = score_G;
    vis_data.score_S = score_S;

    %% Final score: average of three channels
    score = (score_R + score_G + score_S) / 3;

    vis_data.method2_gradient = test_G;  % For GUI visualization
    vis_data.score_color = score_R;      % For GUI compatibility
    vis_data.score_gradient = score_G;   % For GUI compatibility
    vis_data.final_score = score;

    fprintf('  Ratios: R=%.4f, G=%.4f, S=%.4f\n', ratio_R, ratio_G, ratio_S);
    fprintf('  Channel B Score: %.4f\n', score);

end
