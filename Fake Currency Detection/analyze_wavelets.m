% run_channel_C_full_test.m
% A script to perform a full texture analysis (Channel C) using 2D Wavelet Transform
% on a complete set of real and fake notes.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Channel C: Full Wavelet Texture Test ---');

% Define all image filenames
ref_filename = 'reference_note_100.png';
test_filenames = {
    'test_note_100_1.jpg', ...
    'test_note_100_2.jpg', ...
    'test_note_fake_colour.jpg', ...
    'test_note_fake_1.jpg', ...
    'test_note_fake_2.jpg'
};
case_names = {
    'Reference', ...
    'Real Photo 1', ...
    'Real Photo 2', ...
    'Fake (Photostat)', ...
    'Fake (Edited 1)', ...
    'Fake (Edited 2)'
};

% --- 2. Preprocessing ---
disp('Preprocessing all test notes...');
ref_img = imread(ref_filename);
aligned_images = {ref_img}; % Start the list with the reference image

for i = 1:length(test_filenames)
    fprintf('Processing: %s\n', test_filenames{i});
    try
        aligned_images{i+1} = warpImageAfterHomography(test_filenames{i}, ref_filename);
    catch ME
        fprintf('WARNING: Could not preprocess %s. Skipping. Reason: %s\n', test_filenames{i}, ME.message);
        % Add an empty placeholder if preprocessing fails
        aligned_images{i+1} = []; 
    end
end
disp('--- Preprocessing Complete ---');

% --- 3. Wavelet Energy Analysis ---
disp('Analyzing wavelet texture energy for all notes...');

% We'll store energies in a matrix: rows are cases, columns are energy types (H, V, D)
energies = zeros(length(aligned_images), 3);

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue; % Skip if preprocessing failed for this image
    end
    
    current_image_gray = convertToGrayscale(current_image);
    
    % Perform single-level 2D wavelet decomposition
    [~, cH, cV, cD] = dwt2(current_image_gray, 'haar');
    
    % Calculate the energy for each detail coefficient matrix
    energies(i, 1) = mean(cH(:).^2); % Horizontal Energy
    energies(i, 2) = mean(cV(:).^2); % Vertical Energy
    energies(i, 3) = mean(cD(:).^2); % Diagonal Energy
end

% --- 4. Visualization and Results ---
figure('Name', 'Full Wavelet Energy Comparison', 'WindowState', 'maximized');

% The bar function automatically groups the data when given a matrix
bar(energies);

% Add labels and titles for clarity
title('Wavelet Detail Coefficient Energy Comparison');
xlabel('Banknote Case');
ylabel('Mean Square Energy');
set(gca, 'XTickLabel', case_names);
legend('Horizontal (LH)', 'Vertical (HL)', 'Diagonal (HH)');
grid on;

fprintf('\n--- WAVELET TEXTURE ANALYSIS (CHANNEL C) COMPLETE ---\n');
fprintf('%-20s \tHorizontal \tVertical \tDiagonal\n', 'Case');
fprintf('------------------------------------------------------------\n');
for i = 1:length(case_names)
    fprintf('%-20s \t%.4f \t%.4f \t%.4f\n', case_names{i}, energies(i,1), energies(i,2), energies(i,3));
end
fprintf('------------------------------------------------------------\n');


% --- HELPER FUNCTION for Preprocessing ---
function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    ref_img = imread(ref_filename_str);
    test_img_denoised = applyNoiseFilter(test_filename_str);
    test_img = imrotate(test_img_denoised, -90);
    ref_height = size(ref_img, 1);
    test_img = imresize(test_img, [ref_height, NaN]);
    ref_gray = convertToGrayscale(ref_img);
    test_gray = convertToGrayscale(test_img);
    [ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
    [test_points, test_features] = detectAndExtractFeatures(test_gray);
    [matched_points_test, matched_points_ref, ~] = ...
        matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);
    [tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
    warped_img = warpImage(test_img, ref_img, tform);
end