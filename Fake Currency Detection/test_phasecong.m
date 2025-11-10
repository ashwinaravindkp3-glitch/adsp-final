% analyze_phase_congruency_roi_final.m
% A script to generate a separate visual report for each of the six notes,
% analyzing the texture of a specific ROI using Phase Congruency.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Final Phase Congruency ROI Analysis ---');

% --- PASTE YOUR COORDINATES HERE ---
% This ROI should be for the "clean" watermark area on the right.
% Format is [xmin, ymin, width, height]
texture_roi_rect = [1150, 154, 354, 372]; % <<< ADJUST THIS LINE

% --- Define all image filenames ---
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
    'Reference', 'Real Photo 1', 'Real Photo 2', ...
    'Fake (Photostat)', 'Fake (Edited 1)', 'Fake (Edited 2)'
};

% --- 2. Preprocessing ---
disp('Preprocessing all test notes...');
ref_img = imread(ref_filename);
aligned_images = {ref_img}; 

for i = 2:length(all_filenames)
    fprintf('Processing: %s\n', all_filenames{i});
    try
        aligned_images{i} = warpImageAfterHomography(all_filenames{i}, ref_filename);
    catch ME
        fprintf('WARNING: Could not preprocess %s. Skipping.\n', all_filenames{i});
        aligned_images{i} = []; 
    end
end
disp('--- Preprocessing Complete ---');

% --- 3. Phase Congruency Analysis & Visualization ---
disp('Analyzing phase congruency and generating reports...');
texture_metrics = zeros(length(aligned_images), 3); 

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue; 
    end
    
    current_image_gray = convertToGrayscale(current_image);
    roi = extractROI(current_image_gray, texture_roi_rect);
    
    % Calculate phase congruency for the ROI
    try
        [pc, ~] = phasecong3(roi);
    catch ME
        error('The function "phasecong3" was not found. Please ensure Peter Kovesi''s toolbox is in your MATLAB path.');
    end
    
    % Calculate texture metrics
    mean_energy = mean(pc(:));
    entropy_val = entropy(pc);
    std_dev = std(pc(:));
    texture_metrics(i, :) = [mean_energy, entropy_val, std_dev];
    
    % --- Create a new figure for this specific case ---
    figure('Name', ['Report: ', case_names{i}], 'WindowState', 'maximized');
    
    % Plot the full image with the ROI marked
    subplot(1, 2, 1);
    imshow(current_image);
    hold on;
    rectangle('Position', texture_roi_rect, 'EdgeColor', 'r', 'LineWidth', 2);
    title(['Full Processed Image: ', case_names{i}]);
    hold off;
    
    % Plot the phase congruency map of the ROI
    subplot(1, 2, 2);
    imshow(pc);
    title_text = sprintf('Phase Congruency of ROI\nEnergy: %.4f | Entropy: %.4f | Std Dev: %.4f', ...
                         mean_energy, entropy_val, std_dev);
    title(title_text);
end

% --- 4. Display Final Numerical Summary ---
fprintf('\n--- FINAL PHASE CONGRUENCY TEXTURE METRICS ---\n\n');
fprintf('%-15s \tMean Energy \tEntropy \tStd Dev\n', 'Banknote');
fprintf('-----------------------------------------------------------\n');
for i = 1:length(case_names)
    fprintf('%-15s \t%.4f \t\t%.4f \t\t%.4f\n', case_names{i}, texture_metrics(i,1), texture_metrics(i,2), texture_metrics(i,3));
end
fprintf('-----------------------------------------------------------\n');


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