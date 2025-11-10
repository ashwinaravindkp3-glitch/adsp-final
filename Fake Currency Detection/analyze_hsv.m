% analyze_hsv_thread.m
% A script to analyze the Hue component of the security thread for three cases.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading all three images...');
ref_img = imread('test_note_100_1.jpg');
real_photo = imread('reference_note_100.png');
fake_photo = imread('test_note_fake_colour.jpg');

% --- 2. Preprocessing for Test Images ---
disp('Preprocessing real photo...');
aligned_real_photo = warpImageAfterHomography(real_photo, ref_img);
disp('Preprocessing fake photo...');
aligned_fake_photo = warpImageAfterHomography(fake_photo, ref_img);

% --- 3. Define ROI ---
% Use the fixed, reliable ROI for the security thread.
roi_rect = [355, 1, 100, size(ref_img, 1)-1]; 

% --- 4. Create Figure for Comparison ---
figure('Name', 'Security Thread Hue Analysis', 'NumberTitle', 'off');

% --- CASE 1: Ideal Reference Note ---
roi_ref_color = extractROI(ref_img, roi_rect);
hsv_ref = rgb2hsv(roi_ref_color);
hue_ref = hsv_ref(:,:,1); % Extract the Hue channel
subplot(3, 3, 1); imshow(roi_ref_color); title('Case 1: Reference ROI (RGB)');
subplot(3, 3, 2); imshow(hue_ref); title('Hue Channel');
subplot(3, 3, 3); imhist(hue_ref, 64); title('Hue Histogram');

% --- CASE 2: Real-World Photo (Genuine) ---
roi_real_color = extractROI(aligned_real_photo, roi_rect);
hsv_real = rgb2hsv(roi_real_color);
hue_real = hsv_real(:,:,1);
subplot(3, 3, 4); imshow(roi_real_color); title('Case 2: Real Photo ROI (RGB)');
subplot(3, 3, 5); imshow(hue_real); title('Hue Channel');
subplot(3, 3, 6); imhist(hue_real, 64); title('Hue Histogram');

% --- CASE 3: Real-World Photo (Fake) ---
roi_fake_color = extractROI(aligned_fake_photo, roi_rect);
hsv_fake = rgb2hsv(roi_fake_color);
hue_fake = hsv_fake(:,:,1);
subplot(3, 3, 7); imshow(roi_fake_color); title('Case 3: Fake Photo ROI (RGB)');
subplot(3, 3, 8); imshow(hue_fake); title('Hue Channel');
subplot(3, 3, 9); imhist(hue_fake, 64); title('Hue Histogram');

disp('Analysis complete.');

% --- Helper function for preprocessing ---
function warped_img = warpImageAfterHomography(test_img, ref_img)
    % Standardize rotation and scale first
    ref_height = size(ref_img, 1);
    test_img = imresize(test_img, [ref_height, NaN]);
    % Now find and apply homography
    ref_gray = convertToGrayscale(ref_img);
    test_gray = convertToGrayscale(test_img);
    [ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
    [test_points, test_features] = detectAndExtractFeatures(test_gray);
    [matched_points_test, matched_points_ref, ~] = ...
        matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);
    [tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
    warped_img = warpImage(test_img, ref_img, tform);
end