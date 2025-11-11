function [score, vis_data] = run_channel_B_withVis(aligned_color_image, ref_image_path)
%run_channel_B_withVis Channel B: Detects PRINTER ARTIFACTS in photocopies
%
%   **KEY CHANGE**: Now PENALIZES photocopies instead of rewarding similarity!
%   Photocopies are "too perfect" - they lack natural paper variations

    vis_data = struct();
    vis_data.input_image = aligned_color_image;

    % Load reference image
    if nargin < 2
        ref_image_path = 'ref_camera.png';
    end
    ref_image = imread(ref_image_path);
    ref_image = imresize(ref_image, size(aligned_color_image(:,:,1)));
    vis_data.reference_image = ref_image;

    % --- METHOD 1: Color Variance (Photocopies lack natural color variation) ---
    [score_color, vis_color] = analyzeColorVariance(aligned_color_image, ref_image);
    vis_data.method1_color = vis_color;
    vis_data.score_color = score_color;

    % --- METHOD 2: High-Frequency Analysis (Detect printer artifacts) ---
    [score_freq, vis_freq] = analyzeHighFrequency(aligned_color_image, ref_image);
    vis_data.method2_gradient = vis_freq;  % Keep same name for GUI compatibility
    vis_data.score_gradient = score_freq;

    % --- FINAL SCORE ---
    score = (score_color + score_freq) / 2;
    vis_data.final_score = score;

    fprintf('  Channel B: ColorVar=%.3f, HighFreq=%.3f → Final=%.3f\n', ...
            score_color, score_freq, score);

end

% ========================================================================
% METHOD 1: Color Variance Analysis
% ========================================================================
function [score, vis_data] = analyzeColorVariance(test_img, ref_img)
    vis_data = struct();

    % Convert to L*a*b*
    test_lab = rgb2lab(test_img);
    ref_lab = rgb2lab(ref_img);

    test_a = test_lab(:,:,2);
    ref_a = ref_lab(:,:,2);

    vis_data.test_L = test_lab(:,:,1);
    vis_data.test_a = test_a;
    vis_data.ref_a = ref_a;

    % Calculate LOCAL variance (genuine notes have higher local variation)
    % Use sliding window standard deviation
    test_std = stdfilt(test_a, ones(15));
    ref_std = stdfilt(ref_a, ones(15));

    % Genuine notes have MORE variance (natural fibers, ink variations)
    % Photocopies are smoother
    test_avg_std = mean(test_std(:));
    ref_avg_std = mean(ref_std(:));

    variance_ratio = test_avg_std / ref_avg_std;

    % Score: Penalize if variance is TOO LOW (smooth = photocopy)
    if variance_ratio >= 0.7  % Has sufficient variance
        score = 1.0;
    elseif variance_ratio >= 0.5
        score = 0.6;
    elseif variance_ratio >= 0.3
        score = 0.3;
    else
        score = 0.0;  % Too smooth = likely photocopy
    end

    % Compute histograms for visualization
    [hist_test_a, ~] = imhist(uint8(mat2gray(test_a) * 255), 64);
    [hist_ref_a, ~] = imhist(uint8(mat2gray(ref_a) * 255), 64);
    hist_test_a = hist_test_a / sum(hist_test_a);
    hist_ref_a = hist_ref_a / sum(hist_ref_a);

    vis_data.hist_test_a = hist_test_a;
    vis_data.hist_ref_a = hist_ref_a;
    vis_data.test_variance = test_avg_std;
    vis_data.ref_variance = ref_avg_std;
    vis_data.variance_ratio = variance_ratio;
    vis_data.final_score = score;

    fprintf('    Color Variance: test=%.3f, ref=%.3f, ratio=%.2f\n', ...
            test_avg_std, ref_avg_std, variance_ratio);
end

% ========================================================================
% METHOD 2: High-Frequency Analysis (Detect Printer Patterns)
% ========================================================================
function [score, vis_data] = analyzeHighFrequency(test_img, ref_img)
    vis_data = struct();

    % Convert to grayscale
    test_gray = rgb2gray(test_img);
    ref_gray = rgb2gray(ref_img);

    vis_data.test_gray = test_gray;
    vis_data.ref_gray = ref_gray;

    % Compute gradients
    test_Gmag = imgradient(test_gray);
    ref_Gmag = imgradient(ref_gray);

    vis_data.test_gradient = test_Gmag;
    vis_data.ref_gradient = ref_Gmag;

    % Analyze high-frequency content using FFT
    test_fft = abs(fftshift(fft2(im2double(test_gray))));
    ref_fft = abs(fftshift(fft2(im2double(ref_gray))));

    % Get high-frequency energy (edges of spectrum)
    [M, N] = size(test_fft);
    center_mask = zeros(M, N);
    center_mask(round(M*0.3):round(M*0.7), round(N*0.3):round(N*0.7)) = 1;
    high_freq_mask = 1 - center_mask;

    test_hf_energy = sum(test_fft(high_freq_mask > 0));
    ref_hf_energy = sum(ref_fft(high_freq_mask > 0));

    hf_ratio = test_hf_energy / ref_hf_energy;

    % Photocopies often have LESS high-frequency content (smoother)
    % OR periodic printer artifacts (MORE at specific frequencies)
    if hf_ratio >= 0.8 && hf_ratio <= 1.2
        score = 1.0;  % Similar to reference
    elseif hf_ratio >= 0.6 && hf_ratio <= 1.4
        score = 0.5;
    else
        score = 0.0;  % Too different = likely fake
    end

    vis_data.test_hf_energy = test_hf_energy;
    vis_data.ref_hf_energy = ref_hf_energy;
    vis_data.hf_ratio = hf_ratio;
    vis_data.final_score = score;

    fprintf('    High-Freq: test=%.1f, ref=%.1f, ratio=%.2f\n', ...
            test_hf_energy, ref_hf_energy, hf_ratio);
end
