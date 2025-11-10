% debug_pc_threshold_all.m
% A script to analyze the phase congruency map and histogram for all six notes.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Finding Phase Congruency Noise Threshold for All Cases ---');

% --- PASTE YOUR ROI COORDINATES for the clean watermark area HERE ---
% Use the coordinates you found with the interactive tool.
roi_rect = [1150, 154, 354, 372]; % <<< ADJUST THIS LINE

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

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue; 
    end
    
    current_image_gray = convertToGrayscale(current_image);
    roi = extractROI(current_image_gray, roi_rect);
    
    % Calculate phase congruency for the ROI
    try
        [pc, ~] = phasecong3(roi);
    catch ME
        error('The function "phasecong3" was not found. Please ensure Peter Kovesi''s toolbox is in your MATLAB path.');
    end
    
    % --- Create a new figure for this specific case ---
    figure('Name', ['PC Analysis: ', case_names{i}], 'WindowState', 'maximized');
    
    % Plot the phase congruency map of the ROI
    subplot(1, 2, 1);
    imshow(pc);
    title(['Phase Congruency Map of ROI: ', case_names{i}]);
    
    % Plot the histogram of the PC values
    subplot(1, 2, 2);
    imhist(pc);
    title('Histogram of PC Values');
    xlabel('Feature Strength (Phase Congruency)');
    ylabel('Pixel Count');
    grid on;
end

disp('Analysis complete. Please inspect the histograms to find a threshold.');

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