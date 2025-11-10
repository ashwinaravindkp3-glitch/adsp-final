% run_full_preprocessing.m
% This script runs the entire end-to-end preprocessing and normalization pipeline.

clear; clc; close all;

disp('--- Starting Full Preprocessing Pipeline ---');

% --- 1. Load Images ---
disp('Step 1: Loading images...');
ref_img = imread('reference_note_100.png');
test_img_raw = imread('test_note_fake_colour.jpg');

% --- 2. Pre-Alignment Processing ---
disp('Step 2: Denoising and standardizing test image...');
test_img_denoised = applyNoiseFilter('test_note_fake_colour.jpg');

ref_height = size(ref_img, 1);
test_img_standardized = imresize(test_img_denoised, [ref_height, NaN]); % Scale
figure;
imshow(test_img_standardized);
title(' Test Image');
% --- 3. Geometric Alignment ---
disp('Step 3: Performing geometric alignment...');
% Convert to grayscale for feature detection
ref_gray = convertToGrayscale(ref_img);
test_gray = convertToGrayscale(test_img_standardized);
figure;
imshow(test_gray);
% Detect and match features
[ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
[test_points, test_features] = detectAndExtractFeatures(test_gray);
[matched_points_test, matched_points_ref, ~] = ...
    matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);

% Estimate and apply homography
[tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
aligned_img = warpImage(test_img_standardized, ref_img, tform);

% --- 4. Photometric Normalization ---
disp('Step 4: Normalizing illumination...');
final_processed_img = normalizeIllumination(aligned_img);
imshow(test_img_standardized);
title(' Test colour Image');
disp('--- Pipeline Complete ---');

% --- 5. Visualization ---
figure('Name', 'Full Preprocessing Result', 'NumberTitle', 'off');

subplot(1, 3, 1);
imshow(ref_img);
title('Original Reference');

subplot(1, 3, 2);
imshow(final_processed_img);
title('Final Processed Test Image');

subplot(1, 3, 3);
imshowpair(ref_img, final_processed_img, 'blend');
title('Blended Overlay');
% --- 2. Template Library ---
% Define all the templates we want to search for.
template_files = {'template_pattern.jpg','template_kuthira.jpg','template_verysmall_100.jpg','template_ashoka.png','template_sathyam.png', 'template_devanagiri.jpg', 'template_rbi_seal.jpg', 'template_small100.jpg'};
detection_threshold = 0.5; % Let's set a threshold for a "pass"
results = {};

% --- 3. Loop Through and Detect Each Template ---
figure('Name', 'Channel A Multi-Template Results', 'NumberTitle', 'off');
imshow(final_processed_img);
hold on;
title('Detected Features for Channel A');

for i = 1:length(template_files)
    template_name = template_files{i};
    disp(['--- Detecting template: ', template_name, ' ---']);
    
    % Load and preprocess the template
    template_processed = convertToGrayscale(imread(template_name));
    % template_processed = normalizeIllumination(template_gray);
    
    % Perform detection
    correlation_map = performNCC(final_processed_img, template_processed);
    [score, location] = analyzeNCCResult(correlation_map, size(template_processed));
    
    % Store and display result
    results{i}.name = template_name;
    results{i}.score = score;
    results{i}.location = location;
    
    % Draw bounding box on the image
    bbox = [location, size(template_processed, 2), size(template_processed, 1)];
    if score >= detection_threshold
        rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 2);
        disp(['Result: FOUND with score ', num2str(score)]);
    else
        rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
        disp(['Result: NOT FOUND (score ', num2str(score), ' is below threshold)']);
    end
end

hold off;

% A simple helper function to represent the full pipeline for this script
function warped_img = warpImageAfterHomography(test_img, ref_img)
    ref_gray = convertToGrayscale(ref_img);
    test_gray = convertToGrayscale(test_img);
    [ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
    [test_points, test_features] = detectAndExtractFeatures(test_gray);
    [matched_points_test, matched_points_ref, ~] = ...
        matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);
    [tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
    warped_img = warpImage(test_img, ref_img, tform);
end