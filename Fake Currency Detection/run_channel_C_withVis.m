function [score, vis_data] = run_channel_C_withVis(aligned_image, ~)
%run_channel_C_withVis Channel C: Paper authenticity analysis
%
%   PHILOSOPHY: Don't compare to reference. Instead, measure texture
%   complexity that is inherent to genuine currency paper:
%   - Genuine notes: Complex natural fiber texture, high entropy, randomness
%   - Photocopies: Regular paper lacks texture complexity, lower entropy
%
%   Returns score (0-1, higher = more likely genuine)

    vis_data = struct();
    vis_data.input_image = aligned_image;

    % Convert to grayscale
    if size(aligned_image, 3) == 3
        gray = rgb2gray(aligned_image);
    else
        gray = aligned_image;
    end
    vis_data.step1_test_grayscale = gray;

    %% METHOD 1: Texture Entropy
    % Genuine currency paper has high local entropy due to fiber structure
    % Photocopies on regular paper have lower entropy

    entropy_map = entropyfilt(gray, ones(9));
    mean_entropy = mean(entropy_map(:));

    vis_data.method1_entropy_map = entropy_map;
    vis_data.method1_mean_entropy = mean_entropy;

    % Score based on entropy
    % Genuine: > 5.5, Photocopy: < 4.5
    if mean_entropy >= 5.5
        score_entropy = 1.0;
    elseif mean_entropy >= 5.0
        score_entropy = 0.8;
    elseif mean_entropy >= 4.5
        score_entropy = 0.5;
    else
        score_entropy = 0.2;
    end

    %% METHOD 2: GLCM Texture Complexity
    % Analyze texture using Gray-Level Co-occurrence Matrix
    % Genuine notes have more complex texture patterns

    % Quantize to reduce computation
    gray_quant = im2uint8(mat2gray(gray));
    gray_quant = imadjust(gray_quant);

    % Create GLCM in multiple directions
    offsets = [0 1; -1 1; -1 0; -1 -1];
    glcm = graycomatrix(gray_quant, 'Offset', offsets, 'Symmetric', true, 'NumLevels', 16);
    stats = graycoprops(glcm, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});

    contrast = mean(stats.Contrast);
    correlation = mean(stats.Correlation);
    energy = mean(stats.Energy);
    homogeneity = mean(stats.Homogeneity);

    vis_data.method2_glcm_contrast = contrast;
    vis_data.method2_glcm_correlation = correlation;
    vis_data.method2_glcm_energy = energy;
    vis_data.method2_glcm_homogeneity = homogeneity;

    % Genuine notes have:
    % - Higher contrast (more texture variation)
    % - Lower energy (less uniformity)
    % - Moderate homogeneity

    score_glcm = 0;

    % Contrast score (higher is better for genuine)
    if contrast >= 2.0
        score_glcm = score_glcm + 0.3;
    elseif contrast >= 1.5
        score_glcm = score_glcm + 0.2;
    else
        score_glcm = score_glcm + 0.1;
    end

    % Energy score (lower is better for genuine - indicates non-uniformity)
    if energy <= 0.1
        score_glcm = score_glcm + 0.3;
    elseif energy <= 0.15
        score_glcm = score_glcm + 0.2;
    else
        score_glcm = score_glcm + 0.1;
    end

    % Correlation score
    if correlation >= 0.7
        score_glcm = score_glcm + 0.2;
    else
        score_glcm = score_glcm + 0.1;
    end

    % Homogeneity score
    if homogeneity >= 0.5 && homogeneity <= 0.8
        score_glcm = score_glcm + 0.2;
    else
        score_glcm = score_glcm + 0.1;
    end

    %% METHOD 3: Gabor Texture Analysis
    % Multi-orientation Gabor to detect directional texture patterns
    % Genuine notes have rich multi-directional texture

    wavelength = 4;
    orientations = [0, 45, 90, 135];
    gabor_responses = zeros(size(gray, 1), size(gray, 2), length(orientations));

    for i = 1:length(orientations)
        gabor_filter = gabor(wavelength, orientations(i));
        gabor_responses(:,:,i) = imgaborfilt(gray, wavelength, orientations(i));
    end

    % Calculate response strength
    gabor_magnitude = sqrt(sum(gabor_responses.^2, 3));
    mean_gabor_response = mean(gabor_magnitude(:));

    vis_data.step3_test_gabor = gabor_responses(:,:,3);  % For visualization
    vis_data.method3_gabor_magnitude = gabor_magnitude;
    vis_data.method3_mean_response = mean_gabor_response;

    % Genuine notes have higher Gabor response due to complex texture
    if mean_gabor_response >= 15
        score_gabor = 1.0;
    elseif mean_gabor_response >= 10
        score_gabor = 0.7;
    elseif mean_gabor_response >= 7
        score_gabor = 0.4;
    else
        score_gabor = 0.2;
    end

    %% METHOD 4: Standard Deviation of Local Statistics
    % Measure variation in local properties - genuine paper is more heterogeneous

    % Calculate standard deviation in local windows
    window_size = 15;
    std_map = stdfilt(gray, ones(window_size));
    std_of_std = std(std_map(:));  % How much does local variation vary?

    vis_data.method4_std_map = std_map;
    vis_data.method4_std_of_std = std_of_std;

    % Genuine notes have higher "variation of variation"
    if std_of_std >= 6
        score_heterogeneity = 1.0;
    elseif std_of_std >= 4.5
        score_heterogeneity = 0.7;
    elseif std_of_std >= 3
        score_heterogeneity = 0.4;
    else
        score_heterogeneity = 0.2;
    end

    %% FINAL SCORE: Weighted average
    score = (score_entropy * 0.30) + (score_glcm * 0.30) + (score_gabor * 0.25) + (score_heterogeneity * 0.15);

    vis_data.score_entropy = score_entropy;
    vis_data.score_glcm = score_glcm;
    vis_data.score_gabor = score_gabor;
    vis_data.score_heterogeneity = score_heterogeneity;
    vis_data.final_score = score;

    % For GUI compatibility - create dummy peak data
    vis_data.step4_test_peaks_mask = gabor_magnitude > mean(gabor_magnitude(:));
    vis_data.step4_test_total_peaks = sum(vis_data.step4_test_peaks_mask(:));
    vis_data.step5_test_peak_count = vis_data.step4_test_total_peaks;

    fprintf('  Channel C: Entropy=%.2f (%.2f), GLCM=%.2f, Gabor=%.2f (%.2f), Hetero=%.2f (%.2f) → Final=%.3f\n', ...
        mean_entropy, score_entropy, score_glcm, mean_gabor_response, score_gabor, std_of_std, score_heterogeneity, score);

end
