% test_estimateHomography.m
% A script to test the homography estimation and the full registration pipeline.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
ref_img_color = imread('reference_note_100.png');
test_img_color = imread('test_note_fake_colour.jpg');

% --- 2. Full Pipeline Execution ---
% Step A: Pre-process test image (orientation and scale)
disp('Standardizing test image...');
test_img_color = imrotate(test_img_color, 0); % Rotate
ref_height = size(ref_img_color, 1);
test_img_color = imresize(test_img_color, [ref_height, NaN]); % Scale

% Step B: Convert to grayscale
disp('Converting to grayscale...');
ref_gray = convertToGrayscale(ref_img_color);
test_gray = convertToGrayscale(test_img_color);

% Step C: Detect and Extract Features for both images
disp('Detecting features...');
[ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
[test_points, test_features] = detectAndExtractFeatures(test_gray);

% Step D: Match features
disp('Matching features...');
[matched_points_test, matched_points_ref, match_status] = ...
    matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);

if ~match_status.success
    error('Feature matching failed. Cannot proceed.');
end

% Step E: Call the new function we are testing
disp('Estimating homography...');
[tform, homo_status] = estimateHomography(matched_points_test, matched_points_ref);


% --- 3. Visualization ---
if homo_status.success
    disp('Homography estimation successful!');
    fprintf('Used %d inlier points to calculate the transformation.\n', homo_status.inlier_count);
    
    % WARP the test image using the calculated transformation
    output_view = imref2d(size(ref_img_color));
    warped_test_image = imwarp(test_img_color, tform, 'OutputView', output_view);
    
    % Display the result: The reference, the warped, and an overlay
    figure('Name', 'Homography Test Result', 'NumberTitle', 'off');
    
    subplot(1, 3, 1);
    imshow(ref_img_color);
    title('Reference Image');
    
    subplot(1, 3, 2);
    imshow(warped_test_image);
    title('Warped Test Image');
    
    subplot(1, 3, 3);
    imshowpair(ref_img_color, warped_test_image, 'blend');
    title('Blended Overlay');
    
else
    disp('Homography estimation failed.');
end

disp('Test script finished.');