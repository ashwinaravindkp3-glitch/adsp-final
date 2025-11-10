% run_texture_channel.m
% The official, finalized module for Channel C: Texture Analysis.
% This script integrates the full preprocessing pipeline with the directional
% Gabor filter analysis for maximum robustness.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Channel C: Texture Analysis ---');
ref_filename = 'reference_note_100.png';
test_filename = 'test_note_fake_colour.jpg';

% ROI covering the portrait, known to have strong directional texture
texture_roi_rect = [550, 120, 350, 400];

% --- 2. Run the Full Preprocessing Pipeline ---
disp('Step 1: Running full preprocessing on the test note...');
ref_img = imread(ref_filename);
% This single function call runs the entire preprocessing chain.
processed_test_img = run_full_preprocessing(test_filename, ref_img);
disp('Preprocessing complete.');

% --- 3. Visual Alignment & Normalization Check ---
disp('Step 2: Displaying final preprocessed result for verification...');
figure('Name', 'Preprocessing Verification', 'WindowState', 'maximized');
subplot(1, 3, 1);
imshow(ref_img);
title('1. Original Reference Note');
subplot(1, 3, 2);
imshow(processed_test_img);
title('2. Final Processed Test Note');
subplot(1, 3, 3);
imshowpair(ref_img, processed_test_img, 'blend');
title('3. Blended Overlay (Should be sharp)');

% --- 4. Prepare ROIs for Gabor Analysis ---
disp('Step 3: Preparing ROIs for Gabor analysis...');
ref_gray = rgb2gray(ref_img);
processed_test_gray = rgb2gray(processed_test_img);

roi_ref = im2double(imcrop(ref_gray, texture_roi_rect));
roi_fake = im2double(imcrop(processed_test_gray, texture_roi_rect));

% --- 5. Gabor Filter Bank Analysis ---
disp('Step 4: Analyzing texture with Gabor filter bank...');
orientations = 0:45:135;
gabor_bank = gabor(4, orientations);
energy_ref = zeros(1, length(orientations));
energy_fake = zeros(1, length(orientations));

for i = 1:length(gabor_bank)
    g_mag_ref = abs(imfilter(roi_ref, gabor_bank(i).SpatialKernel, 'conv', 'replicate'));
    energy_ref(i) = mean(g_mag_ref(:).^2);
    
    g_mag_fake = abs(imfilter(roi_fake, gabor_bank(i).SpatialKernel, 'conv', 'replicate'));
    energy_fake(i) = mean(g_mag_fake(:).^2);
end

% --- 6. Calculate Final Differentiating Score ---
score_ref = std(energy_ref);
score_fake = std(energy_fake);

% --- 7. Visualization & Results ---
disp('Step 5: Displaying Gabor analysis results...');
figure('Name', 'Directional Texture Analysis Results', 'WindowState', 'maximized');
bar_data = [energy_ref', energy_fake'];
bar(orientations, bar_data);
title('Gabor Filter Energy Response by Orientation');
xlabel('Filter Orientation (Degrees)');
ylabel('Mean Square Energy');
legend('Reference Note', 'Fake Note');
grid on;
set(gca, 'XTick', orientations);

fprintf('\n--- GABOR TEXTURE ANALYSIS COMPLETE ---\n');
fprintf('Directionality Score (Reference): %.6f\n', score_ref);
fprintf('Directionality Score (Fake):      %.6f\n', score_fake);
fprintf('-----------------------------------------\n');

%% -----------------------------------------------------------------------
%                       HELPER FUNCTIONS
% ------------------------------------------------------------------------

function final_processed_img = run_full_preprocessing(test_img_path, ref_img)
    % Encapsulates the entire preprocessing pipeline from your script.
    
    % --- Step A: Load and Standardize ---
    test_img_raw = imread(test_img_path);
    test_img_denoised = imgaussfilt(test_img_raw, 1.0); % Standard denoising
    ref_height = size(ref_img, 1);
    test_img_standardized = imresize(test_img_denoised, [ref_height, NaN]);

    % --- Step B: Geometric Alignment ---
    ref_gray = rgb2gray(ref_img);
    test_gray = rgb2gray(test_img_standardized);
    
    ref_points = detectORBFeatures(ref_gray).selectStrongest(5000);
    test_points = detectORBFeatures(test_gray).selectStrongest(5000);
    
    [ref_features, ref_valid_points] = extractFeatures(ref_gray, ref_points);
    [test_features, test_valid_points] = extractFeatures(test_gray, test_points);
    
    index_pairs = matchFeatures(ref_features, test_features, 'MaxRatio', 0.7, 'Unique', true);
    
    matched_ref_points = ref_valid_points(index_pairs(:, 1), :);
    matched_test_points = test_valid_points(index_pairs(:, 2), :);
    
    if size(matched_ref_points, 1) < 20
        error('Preprocessing failed: Not enough strong matches for alignment.');
    end
    
    tform = estimateGeometricTransform2D(matched_test_points, matched_ref_points, 'projective');
    output_view = imref2d(size(ref_img));
    aligned_img = imwarp(test_img_standardized, tform, 'OutputView', output_view);

    % --- Step C: Photometric Normalization ---
    final_processed_img = normalizeIllumination(aligned_img);
end

function normalized_img = normalizeIllumination(img_rgb)
    % A simple illumination normalization using homomorphic filtering in LAB space.
    img_lab = rgb2lab(img_rgb);
    L = img_lab(:,:,1);
    L(L < 1) = 1; % Avoid log(0)
    L_log = log(L);
    L_fft = fft2(L_log);
    
    [rows, cols] = size(L);
    [X, Y] = meshgrid(1:cols, 1:rows);
    centerX = ceil(cols/2);
    centerY = ceil(rows/2);
    D = sqrt((X-centerX).^2 + (Y-centerY).^2);
    
    % Create a high-pass Butterworth filter to remove low-frequency illumination
    n = 1; D0 = 30; % Filter parameters
    H = 1 ./ (1 + (D0./D).^(2*n)); 
    
    L_fft_filtered = fftshift(L_fft) .* H;
    L_filtered = real(ifft2(ifftshift(L_fft_filtered)));
    L_exp = exp(L_filtered);
    
    % Scale L channel back to the standard [0, 100] range for LAB
    L_norm = (L_exp - min(L_exp(:))) ./ (max(L_exp(:)) - min(L_exp(:))) * 100;
    
    img_lab(:,:,1) = L_norm;
    normalized_img = lab2rgb(img_lab);
end