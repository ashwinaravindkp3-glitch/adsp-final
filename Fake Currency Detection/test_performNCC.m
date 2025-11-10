% test_performNCC.m (Version 2)
% A script to test the core NCC module and visualize the result with a bounding box.

clear; clc; close all;

% --- 1. Setup ---
% This test requires a fully preprocessed image.
disp('--- Running Full Preprocessing to get a clean image ---');
ref_img = imread('reference_note_100.png');
test_img_raw = imread('test_note_fake_colour.jpg');
% ... (Full preprocessing pipeline)
test_img_standardized = applyNoiseFilter('test_note_fake_colour.jpg');
%test_img_standardized = imrotate(test_img_denoised, -90);
ref_height = size(ref_img, 1);
test_img_standardized = imresize(test_img_standardized, [ref_height, NaN]);
ref_gray = convertToGrayscale(ref_img);
test_gray = convertToGrayscale(test_img_standardized);
[ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
[test_points, test_features] = detectAndExtractFeatures(test_gray);
[matched_points_test, matched_points_ref, ~] = ...
    matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);
[tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
aligned_img = warpImage(test_img_standardized, ref_img, tform);
final_processed_gray = normalizeIllumination(aligned_img);
disp('--- Preprocessing Complete ---');

% Now, setup for the NCC test
disp('Loading template...');
template_color = imread('template_ashoka.jpg');
template_gray = convertToGrayscale(template_color);

% --- 2. Execution ---
disp('Running performNCC.m...');
correlation_map = performNCC(final_processed_gray, template_gray);

% --- 3. Analysis (NEW SECTION) ---
% Find the location of the peak in the correlation map
disp('Analyzing correlation map...');
[score, max_idx] = max(correlation_map(:));
[ypeak, xpeak] = ind2sub(size(correlation_map), max_idx);
% Calculate the top-left corner of the matched region
template_size = size(template_gray);
location = [xpeak - template_size(2) + 1, ypeak - template_size(1) + 1];

% --- 4. Visualization (UPDATED SECTION) ---
disp('Displaying results...');
figure('Name', 'NCC Test with Bounding Box', 'NumberTitle', 'off');

% Plot the correlation map on the left
subplot(1, 2, 1);
surf(correlation_map), shading flat;
title('Output: Correlation Map');
axis tight; % Make the plot fit the data

% Plot the original image with the bounding box on the right
subplot(1, 2, 2);
imshow(final_processed_gray);
hold on;
% Define the bounding box rectangle [x, y, width, height]
bbox = [location(1), location(2), template_size(2), template_size(1)];
rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 2);
hold off;
title(['Feature Detected (Score: ', num2str(score, 2), ')']);

disp('Test script finished.');