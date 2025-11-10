% test_watermark_final_metrics.m
% A final script to calculate robust texture metrics for the watermark area.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Final Watermark Texture Test ---');
roi_rect = [1150, 154, 354, 372]; % <<< Use the ROI you found for the watermark area
NOISE_THRESHOLD = 0.1; % Our threshold for what counts as a "feature"

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

% --- 3. Analysis ---
disp('Calculating final texture metrics for all notes...');
clutter_scores = zeros(1, length(aligned_images)); 
std_dev_scores = zeros(1, length(aligned_images)); 

for i = 1:length(aligned_images)
    current_image = aligned_images{i};
    if isempty(current_image), continue; end
    
    roi = extractROI(convertToGrayscale(current_image), roi_rect);
    [pc, ~] = phasecong3(roi);
    
    % Metric 1: Clutter Score
    clutter_pixels = sum(pc(:) > NOISE_THRESHOLD);
    total_pixels = numel(pc);
    clutter_scores(i) = (clutter_pixels / total_pixels) * 100;

    % Metric 2: Standard Deviation
    std_dev_scores(i) = std(pc(:));
end

% --- 4. Display the Final Results ---
figure('Name', 'Final Watermark Texture Metrics', 'WindowState', 'maximized');
subplot(1, 2, 1);
bar(clutter_scores);
title('Clutter Score (Higher is worse)');
ylabel('Percentage of Feature Pixels (%)');
set(gca, 'XTickLabel', case_names); xtickangle(45); grid on;

subplot(1, 2, 2);
bar(std_dev_scores);
title('Standard Deviation (Higher is worse)');
ylabel('Std. Dev. of PC Values');
set(gca, 'XTickLabel', case_names); xtickangle(45); grid on;

fprintf('\n--- FINAL TEXTURE METRICS ---\n');
for i = 1:length(case_names)
    fprintf('%-15s \tClutter Score = %.2f%% \tStd Dev = %.4f\n', case_names{i}, clutter_scores(i), std_dev_scores(i));
end
fprintf('------------------------------------\n');


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