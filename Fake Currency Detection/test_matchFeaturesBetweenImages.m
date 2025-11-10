% test_matchFeaturesBetweenImages.m
% A script to test the feature matching module.

clear; clc; close all;

% --- 1. Setup ---
% Define file paths for both images.
ref_filename = 'reference_note_100.png';
test_filename = 'test_note_100_1.jpg';

% Load images
disp('Loading images...');
ref_img_color = imread(ref_filename);
test_img_color = imread(test_filename);

% --- FIX 1: Rotate the test image if necessary ---
% (Assuming you have saved a manually rotated version, or you can use imrotate)
% For this test, let's assume test_image_100.jpg is now horizontal.

% --- FIX 2: Resize the test image to match the reference scale ---
disp('Standardizing image scale...');
ref_height = size(ref_img_color, 1);
test_img_color = imresize(test_img_color, [ref_height, NaN]); % Resize to match height, maintain aspect ratio
% --------------------------------------------------------------------

% --- 2. Execution ---
% Process Reference Image
disp('Processing reference image...');
ref_gray = convertToGrayscale(ref_img_color);
[ref_points, ref_features] = detectAndExtractFeatures(ref_gray);

% Process Test Image
disp('Processing test image...');
test_gray = convertToGrayscale(test_img_color);
[test_points, test_features] = detectAndExtractFeatures(test_gray);

% Call the new function we are testing
disp('Matching features between images...');
[matched_points_test, matched_points_ref, status] = matchFeaturesBetweenImages(...
    test_points, test_features, ref_points, ref_features);

% --- 3. Visualization ---
if status.success
    disp(['Matching successful. Found ', num2str(status.matches), ' matched points.']);
    
    % Display the matched features
    figure('Name', 'Feature Matching Test', 'NumberTitle', 'off');
    showMatchedFeatures(test_img_color, ref_img_color, matched_points_test, matched_points_ref, 'montage');
    
    title('Matched Feature Points');
    legend('Matched points from Test Image', 'Matched points from Reference Image');
else
    disp('Matching failed. No points were matched.');
end

disp('Test script finished.');