function [score, vis_data] = run_channel_B_withVis(aligned_image, ~)
%run_channel_B_withVis Channel B: Detect photocopy artifacts
%
%   PHILOSOPHY: Don't compare to reference. Instead, measure properties
%   that distinguish genuine notes from photocopies:
%   - Genuine notes: High local variance, rich detail, natural randomness
%   - Photocopies: Print patterns, quantization, reduced dynamic range
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
    vis_data.step1_grayscale = gray;

    %% METHOD 1: Local Variance Analysis
    % Genuine notes have high local variance due to paper texture and micro-printing
    % Photocopies have reduced variance (smoother, more uniform)

    window_size = 7;
    local_variance = stdfilt(gray, ones(window_size));
    mean_local_variance = mean(local_variance(:));

    vis_data.method1_color = local_variance;  % Keep field name for GUI compatibility
    vis_data.method1_mean_variance = mean_local_variance;

    % Score based on local variance (higher = genuine)
    % Typical values: Genuine > 15, Photocopy < 10
    if mean_local_variance >= 15
        score_variance = 1.0;
    elseif mean_local_variance >= 12
        score_variance = 0.8;
    elseif mean_local_variance >= 10
        score_variance = 0.5;
    else
        score_variance = 0.2;
    end

    %% METHOD 2: Frequency Domain Analysis
    % Photocopies have characteristic periodic patterns from printer dots
    % Use FFT to detect periodicity

    gray_double = im2double(gray);
    fft_result = fft2(gray_double);
    fft_shifted = fftshift(fft_result);
    magnitude_spectrum = abs(fft_shifted);

    % Log scale for visualization
    vis_data.method2_gradient = log(1 + magnitude_spectrum);  % Keep field name for GUI

    % Analyze high-frequency energy
    [M, N] = size(magnitude_spectrum);
    center_mask = zeros(M, N);
    % Exclude DC and very low frequencies (central 20%)
    center_r = round(min(M, N) * 0.1);
    [Y, X] = meshgrid(1:N, 1:M);
    center_mask = sqrt((X - M/2).^2 + (Y - N/2).^2) > center_r;

    high_freq_energy = sum(magnitude_spectrum(center_mask));
    total_energy = sum(magnitude_spectrum(:));
    hf_ratio = high_freq_energy / total_energy;

    vis_data.method2_hf_ratio = hf_ratio;

    % Genuine notes have more high-frequency content (fine details)
    % Typical: Genuine > 0.35, Photocopy < 0.30
    if hf_ratio >= 0.35
        score_freq = 1.0;
    elseif hf_ratio >= 0.32
        score_freq = 0.7;
    elseif hf_ratio >= 0.28
        score_freq = 0.4;
    else
        score_freq = 0.1;
    end

    %% METHOD 3: Edge Density and Sharpness
    % Genuine notes have sharp, well-defined edges from printing
    % Photocopies lose edge sharpness

    edges = edge(gray, 'Canny');
    edge_density = sum(edges(:)) / numel(edges);

    % Measure edge sharpness using gradient magnitude
    [Gx, Gy] = gradient(double(gray));
    gradient_mag = sqrt(Gx.^2 + Gy.^2);
    mean_gradient = mean(gradient_mag(:));

    vis_data.method3_edges = edges;
    vis_data.method3_edge_density = edge_density;
    vis_data.method3_mean_gradient = mean_gradient;

    % Score based on edge quality
    % Genuine: edge_density > 0.15, mean_gradient > 8
    if edge_density >= 0.15 && mean_gradient >= 8
        score_edge = 1.0;
    elseif edge_density >= 0.12 && mean_gradient >= 6
        score_edge = 0.7;
    elseif edge_density >= 0.08
        score_edge = 0.4;
    else
        score_edge = 0.2;
    end

    %% METHOD 4: Color Analysis (if RGB)
    if size(aligned_image, 3) == 3
        % Convert to L*a*b* for perceptual color analysis
        lab_image = rgb2lab(aligned_image);
        a_channel = lab_image(:,:,2);
        b_channel = lab_image(:,:,3);

        % Measure color variance
        color_variance = std(a_channel(:)) + std(b_channel(:));

        vis_data.method4_lab_a = a_channel;
        vis_data.method4_lab_b = b_channel;
        vis_data.method4_color_variance = color_variance;

        % Genuine notes have richer color variation
        % Typical: Genuine > 8, Photocopy < 6
        if color_variance >= 8
            score_color = 1.0;
        elseif color_variance >= 6
            score_color = 0.6;
        else
            score_color = 0.3;
        end
    else
        score_color = 0.5;  % Neutral if grayscale
    end

    %% FINAL SCORE: Weighted average
    score = (score_variance * 0.35) + (score_freq * 0.35) + (score_edge * 0.20) + (score_color * 0.10);

    vis_data.score_color = score_variance;  % For GUI compatibility
    vis_data.score_gradient = score_freq;  % For GUI compatibility
    vis_data.score_variance = score_variance;
    vis_data.score_freq = score_freq;
    vis_data.score_edge = score_edge;
    vis_data.score_colorvar = score_color;
    vis_data.final_score = score;

    fprintf('  Channel B: Variance=%.2f (%.2f), Freq=%.2f (%.2f), Edge=%.2f (%.2f), Color=%.2f → Final=%.3f\n', ...
        mean_local_variance, score_variance, hf_ratio, score_freq, edge_density, score_edge, score_color, score);

end
