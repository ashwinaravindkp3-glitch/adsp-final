% compare_phase_congruency.m
% A script to compare the full-image phase congruency maps for all six currency notes.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Full Phase Congruency Comparison ---');

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


% --- 3. Phase Congruency Analysis & Visualization ---
disp('Analyzing phase congruency for all notes...');

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue; % Skip if preprocessing failed for this image
    end
    
    current_image_gray = convertToGrayscale(current_image);
    
    % Calculate phase congruency for the full image
    try
        [pc, ~] = phasecong3(current_image_gray);
    catch ME
        if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
            error('The function "phasecong3" was not found. Please ensure Peter Kovesi''s toolbox is in your MATLAB path.');
        else
            rethrow(ME);
        end
    end
    
    % Create a new figure for each case
    figure('Name', ['Phase Congruency: ', case_names{i}], 'WindowState', 'maximized');
    
    subplot(1, 2, 1);
    imshow(current_image);
    title(['Processed Image: ', case_names{i}]);
    
    subplot(1, 2, 2);
    imshow(pc);
    title('Phase Congruency Map');
end

disp('Analysis complete.');


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