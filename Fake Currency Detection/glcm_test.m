% analyze_glcm_texture.m
% A script to perform a full texture analysis (Channel C) using GLCM
% on the complete set of real and fake notes.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Channel C: GLCM Texture Analysis ---');

% Define all image filenames
ref_filename = 'reference_note_100.png';
all_filenames = {
    'reference_note_100.png', ...
    'test_note_100_1.jpg', ...
    'test_note_100_2.jpg', ...
    'test_note_fake_colour.jpg', ...
    'test_note_fake_1.jpg', ...
    'test_note_fake_2.jpg'
};
case_names = {
    'Reference', 'Real 1', 'Real 2', 'Fake (Copy)', 'Fake (Edit 1)', 'Fake (Edit 2)'
};

% --- 2. Preprocessing ---
disp('Preprocessing all test notes...');
ref_img = imread(ref_filename);
aligned_images = {ref_img}; % Start the list with the reference image

for i = 2:length(all_filenames)
    fprintf('Processing: %s\n', all_filenames{i});
    try
        aligned_images{i} = warpImageAfterHomography(all_filenames{i}, ref_filename);
    catch ME
        fprintf('WARNING: Could not preprocess %s. Skipping. Reason: %s\n', all_filenames{i}, ME.message);
        aligned_images{i} = []; 
    end
end
disp('--- Preprocessing Complete ---');

% --- 3. GLCM Texture Analysis ---
disp('Analyzing GLCM texture for all notes...');
texture_properties = zeros(length(aligned_images), 2); % Rows for cases, Cols for [Contrast, Homogeneity]

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue; % Skip if preprocessing failed
    end
    
    current_image_gray = convertToGrayscale(current_image);
    
    % To get a rotation-invariant measure, we calculate GLCM in 4 directions
    % (0, 45, 90, 135 degrees) and average the properties.
    offsets = [0 1; -1 1; -1 0; -1 -1];
    glcms = graycomatrix(current_image_gray, 'Offset', offsets, 'Symmetric', true);
    
    % Calculate texture properties from the GLCMs
    stats = graycoprops(glcms, {'Contrast', 'Homogeneity'});
    
    % Average the properties across the 4 directions
    texture_properties(i, 1) = mean(stats.Contrast);
    texture_properties(i, 2) = mean(stats.Homogeneity);
end

% --- 4. Visualization and Results ---
figure('Name', 'GLCM Texture Property Comparison', 'WindowState', 'maximized');

% Plot Contrast
subplot(1, 2, 1);
bar(texture_properties(:, 1));
title('GLCM Contrast (Higher is Better)');
ylabel('Average Contrast');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% Plot Homogeneity
subplot(1, 2, 2);
bar(texture_properties(:, 2));
title('GLCM Homogeneity (Lower is Better)');
ylabel('Average Homogeneity');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

fprintf('\n--- GLCM TEXTURE ANALYSIS (CHANNEL C) COMPLETE ---\n');
fprintf('%-20s \tContrast \tHomogeneity\n', 'Case');
fprintf('--------------------------------------------------\n');
for i = 1:length(case_names)
    fprintf('%-20s \t%.4f \t%.4f\n', case_names{i}, texture_properties(i,1), texture_properties(i,2));
end
fprintf('--------------------------------------------------\n');


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