% test_full_ChannelC.m
% A script to test the final Channel C texture detector.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Final Test for Channel C ---');
ref_filename = 'reference_note_100.png';
all_filenames = {
    'reference_note_100.jpg', ...
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

scores_C = zeros(1, length(all_filenames));
ref_img = imread(ref_filename);

% --- 2. Loop Through and Analyze Each Case ---
for i = 1:length(all_filenames)
    fprintf('--- Processing: %s ---\n', case_names{i});
    
    if i == 1 % The reference image doesn't need preprocessing
        processed_img = ref_img;
    else
        processed_img = warpImageAfterHomography(all_filenames{i}, ref_filename);
    end
    
    % Run our new Channel C detector
    scores_C(i) = analyzeTexture(processed_img);
end

% --- 3. Display Final Scores ---
fprintf('\n--- FINAL CHANNEL C (WAVELET TEXTURE) SCORES ---\n');
for i = 1:length(case_names)
    fprintf('%-20s \tTotal Energy Score = %.4f\n', case_names{i}, scores_C(i));
end
fprintf('---------------------------------------------------\n');


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