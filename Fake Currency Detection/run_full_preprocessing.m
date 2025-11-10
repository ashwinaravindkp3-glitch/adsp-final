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
%test_img_standardized = imrotate(test_img_denoised, -90); % Rotate
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