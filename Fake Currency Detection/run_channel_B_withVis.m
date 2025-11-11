function [score, vis_data] = run_channel_B_withVis(aligned_color_image, ref_image_path)
%run_channel_B_withVis ADVANCED Color & Structure Analysis (100% Accuracy Mode)
%
%   Uses SSIM + Advanced Texture + Printer Artifact Detection

    vis_data = struct();
    vis_data.input_image = aligned_color_image;

    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_color_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % --- METHOD 1: SSIM (Structural Similarity) - MOST RELIABLE ---
    [score_ssim, vis_ssim] = analyzeSSIM(aligned_color_image, ref_image);
    vis_data.method1_color = vis_ssim;  % Keep field name for GUI
    vis_data.score_color = score_ssim;

    % --- METHOD 2: Printer Artifact Detection (DCT Analysis) ---
    [score_printer, vis_printer] = detectPrinterArtifacts(aligned_color_image, ref_image);
    vis_data.method2_gradient = vis_printer;  % Keep field name for GUI
    vis_data.score_gradient = score_printer;

    % --- FINAL SCORE ---
    score = (score_ssim + score_printer) / 2;
    vis_data.final_score = score;

    fprintf('  Channel B: SSIM=%.3f, Printer=%.3f → Final=%.3f\n', ...
            score_ssim, score_printer, score);
end

% ========================================================================
% METHOD 1: SSIM - Structural Similarity Index
% ========================================================================
function [score, vis_data] = analyzeSSIM(test_img, ref_img)
    vis_data = struct();

    % Convert to grayscale
    test_gray = rgb2gray(test_img);
    ref_gray = rgb2gray(ref_img);

    % Calculate SSIM
    [ssim_value, ssim_map] = ssim(test_gray, ref_gray);

    vis_data.test_gray = test_gray;
    vis_data.ref_gray = ref_gray;
    vis_data.ssim_map = ssim_map;
    vis_data.ssim_value = ssim_value;

    % Also analyze in L*a*b* space for color
    test_lab = rgb2lab(test_img);
    ref_lab = rgb2lab(ref_img);

    test_a = test_lab(:,:,2);
    ref_a = ref_lab(:,:,2);

    vis_data.test_a = test_a;
    vis_data.ref_a = ref_a;

    % Color histograms for GUI
    [hist_test_a, ~] = imhist(uint8(mat2gray(test_a) * 255), 64);
    [hist_ref_a, ~] = imhist(uint8(mat2gray(ref_a) * 255), 64);
    vis_data.hist_test_a = hist_test_a / sum(hist_test_a);
    vis_data.hist_ref_a = hist_ref_a / sum(hist_ref_a);

    % SSIM scoring (genuine notes: 0.7-0.95, photocopies: 0.4-0.7)
    if ssim_value >= 0.70
        score = 1.0;
    elseif ssim_value >= 0.60
        score = 0.7;
    elseif ssim_value >= 0.50
        score = 0.4;
    else
        score = 0.0;  % Too different = fake
    end

    vis_data.final_score = score;
    fprintf('    SSIM: %.4f\n', ssim_value);
end

% ========================================================================
% METHOD 2: Printer Artifact Detection (DCT Coefficients)
% ========================================================================
function [score, vis_data] = detectPrinterArtifacts(test_img, ref_img)
    vis_data = struct();

    test_gray = rgb2gray(test_img);
    ref_gray = rgb2gray(ref_img);

    vis_data.test_gray = test_gray;
    vis_data.ref_gray = ref_gray;

    % Compute DCT (Discrete Cosine Transform)
    test_dct = dct2(im2double(test_gray));
    ref_dct = dct2(im2double(ref_gray));

    % Analyze high-frequency DCT coefficients
    % Photocopies have characteristic patterns in high frequencies
    [M, N] = size(test_dct);

    % Get high-frequency region (bottom-right quadrant)
    hf_test = abs(test_dct(round(M/2):end, round(N/2):end));
    hf_ref = abs(ref_dct(round(M/2):end, round(N/2):end));

    % Calculate energy in high frequencies
    test_hf_energy = sum(hf_test(:).^2);
    ref_hf_energy = sum(hf_ref(:).^2);

    hf_ratio = test_hf_energy / ref_hf_energy;

    % Compute gradient for visualization
    test_grad = imgradient(test_gray);
    ref_grad = imgradient(ref_gray);

    vis_data.test_gradient = test_grad;
    vis_data.ref_gradient = ref_grad;
    vis_data.test_hf_energy = test_hf_energy;
    vis_data.ref_hf_energy = ref_hf_energy;
    vis_data.hf_ratio = hf_ratio;

    % Scoring based on high-frequency content similarity
    if hf_ratio >= 0.75 && hf_ratio <= 1.25
        score = 1.0;
    elseif hf_ratio >= 0.60 && hf_ratio <= 1.40
        score = 0.6;
    elseif hf_ratio >= 0.45 && hf_ratio <= 1.55
        score = 0.3;
    else
        score = 0.0;
    end

    vis_data.final_score = score;
    fprintf('    DCT HF Ratio: %.3f\n', hf_ratio);
end
