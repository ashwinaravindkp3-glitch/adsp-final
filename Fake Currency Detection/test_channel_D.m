% test_channel_D_final.m
% Final Channel D detector using ONLY ref_camera.png as reference.

clear; clc; close all;

disp('--- Starting Final Test for Channel D ---');

% --- 1. Setup ---
camera_ref_filename  = 'ref_camera.png';
all_test_filenames = {
    'ref_camera.png', ...
    'test_note_100_1.jpg', ...
    'test_note_fake_colour.jpg', ...
    'test_note_fake_1.jpg', ...
    'test_note_fake_3.jpg'
};
case_names = {
    'Camera Reference', 'Real Photo', ...
    'Fake (Photostat)', 'Fake (Edited 1)', 'Fake (Edited 2)'
};

% --- 2. Preprocessing ---
disp('Preprocessing all notes to a common alignment...');
camera_ref_img = imread(camera_ref_filename);
aligned_images = cell(size(all_test_filenames));

for i = 1:length(all_test_filenames)
    fprintf('Processing: %s\n', case_names{i});
    try
        if i == 1
            % Camera reference itself → no warp
            aligned_images{i} = camera_ref_img;
        else
            % Warp test image to camera reference
            aligned_images{i} = warpImageAfterHomography(all_test_filenames{i}, camera_ref_filename);
        end
    catch ME
        fprintf('WARNING: Could not preprocess %s. Skipping. Reason: %s\n', case_names{i}, ME.message);
        aligned_images{i} = []; 
    end
end
disp('--- Preprocessing Complete ---');

% --- 3. Run Detector ---
disp('--- Running Channel D Detector on all notes ---');

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image)
        continue;
    end
    
    % Run detector using ref_camera as baseline
    peak_count = run_channel_D(current_image, camera_ref_img);
    
    % Simple decision rule
    if peak_count > 500
        verdict = 'REAL';
    else
        verdict = 'FAKE';
    end
    
    fprintf('Result for %-20s -> Found %d peaks. \tVerdict: %s\n', ...
            [case_names{i}, ':'], peak_count, verdict);
end


% --- Preprocessing helper ---
function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    ref_img = imread(ref_filename_str);
    test_img_denoised = applyNoiseFilter(test_filename_str);
    test_img = imrotate(test_img_denoised, 0);
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
