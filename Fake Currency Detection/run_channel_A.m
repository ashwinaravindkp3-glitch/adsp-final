function score = run_channel_A(aligned_image)
%run_channel_A Channel A: Graphical Integrity (Template Matching)
%
%   Uses Normalized Cross-Correlation (NCC) with histogram equalization
%   to detect key graphical elements on the currency note.
%
%   Method:
%   1. Apply homomorphic filter (normalizeIllumination) for even lighting
%   2. Apply histogram equalization (histeq) to enhance contrast
%   3. Match at least 3 templates using NCC
%   4. Return percentage of templates found (0.0 to 1.0)
%
%   Inputs:
%       aligned_image - Preprocessed, aligned color image
%
%   Outputs:
%       score - Detection score (0.0 to 1.0)

    fprintf('\n--- Channel A: Template Matching ---\n');

    % --- STEP 1: Normalize Illumination (Homomorphic Filter) ---
    processed_gray = normalizeIllumination(aligned_image);

    % --- STEP 2: Histogram Equalization ---
    processed_histeq = histeq(processed_gray);

    % --- STEP 3: Define Templates (at least 3) ---
    template_files = {
        'template_ashoka.jpg', ...
        'template_devanagiri.jpg', ...
        'template_rbi_seal.jpg'
    };

    % --- STEP 4: Match Each Template ---
    detection_threshold = 0.60;  % NCC threshold for detection
    num_found = 0;

    for i = 1:length(template_files)
        try
            % Load and preprocess template
            template = imread(template_files{i});
            template_gray = rgb2gray(template);
            template_histeq = histeq(template_gray);

            % Perform Normalized Cross-Correlation
            corr_map = normxcorr2(template_histeq, processed_histeq);
            max_corr = max(corr_map(:));

            % Check if template is detected
            if max_corr >= detection_threshold
                num_found = num_found + 1;
                fprintf('  [✓] %s (score: %.3f)\n', template_files{i}, max_corr);
            else
                fprintf('  [✗] %s (score: %.3f)\n', template_files{i}, max_corr);
            end

        catch ME
            fprintf('  [!] %s - Error: %s\n', template_files{i}, ME.message);
        end
    end

    % --- STEP 5: Calculate Final Score ---
    score = num_found / length(template_files);
    fprintf('Templates Found: %d/%d (Score: %.2f)\n', ...
            num_found, length(template_files), score);
end


% ============================================================================
% HELPER FUNCTION: normalizeIllumination
% ============================================================================
function normalized_image = normalizeIllumination(image)
%normalizeIllumination Applies homomorphic filtering for illumination correction
%
%   This creates an evenly lit, high-contrast grayscale output by:
%   1. Log transform to separate illumination and reflectance
%   2. High-pass filter in frequency domain to suppress illumination
%   3. Exponential transform to return to spatial domain

    % Convert to grayscale
    if size(image, 3) == 3
        image_gray = rgb2gray(image);
    else
        image_gray = image;
    end

    % Convert to double and apply log transform
    I = im2double(image_gray);
    I_log = log(1 + I);

    % Fourier transform
    I_fft = fft2(I_log);

    % Create Butterworth High-Pass Filter
    [M, N] = size(I);
    D0 = 15;  % Cutoff frequency
    n = 2;    % Filter order
    [X, Y] = meshgrid(1:N, 1:M);
    D = sqrt((X - N/2).^2 + (Y - M/2).^2);
    H = 1 ./ (1 + (D0./D).^(2*n));

    % Apply filter
    I_fft_filtered = fftshift(I_fft) .* H;

    % Return to spatial domain
    I_filtered = real(ifft2(ifftshift(I_fft_filtered)));
    I_exp = exp(I_filtered) - 1;

    % Normalize to uint8
    normalized_image = im2uint8(mat2gray(I_exp));
end
