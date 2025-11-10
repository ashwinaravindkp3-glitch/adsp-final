% compare_gabor_cases.m (Version 2)
% A script to compare Gabor responses for the reference, a real photo, and a fake photo.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading all three images...');
ref_img = imread('reference_note_100.png');
real_photo = imread('test_note_100_1.jpg');
fake_photo = imread('test_note_fake_colour.jpg');

% --- 2. Gabor Filter Design ---
wavelength = 4;
orientation = 90;
g = gabor(wavelength, orientation);

% --- 3. Preprocessing for Test Images ---
% We need to align both the real and fake photos to our reference.
disp('Preprocessing real photo...');
aligned_real_photo = warpImageAfterHomography(real_photo, ref_img);
disp('Preprocessing fake photo...');
aligned_fake_photo = warpImageAfterHomography(fake_photo, ref_img);

% --- 4. Create Figure for Comparison ---
figure('Name', 'Gabor Response Comparison', 'NumberTitle', 'off');

% --- CASE 1: Ideal Reference Note ---
disp('Processing Case 1: Ideal Reference...');
roi_rect = [945, 1, 65, size(ref_img, 1)-1]; ; % Use the good ROI for the thread
roi_ref = extractROI(ref_img, roi_rect);
response_ref = abs(imfilter(im2double(roi_ref), g.SpatialKernel, 'conv'));

subplot(3, 2, 1);
imshow(roi_ref);
title('Case 1: Reference Note ROI');
subplot(3, 2, 2);
imshow(response_ref, []);
title('Response: Strong, Continuous');

% --- CASE 2: Real-World Photo (Genuine) ---
disp('Processing Case 2: Real Photo...');
roi_real = extractROI(aligned_real_photo, roi_rect);
response_real = abs(imfilter(im2double(roi_real), g.SpatialKernel, 'conv'));

subplot(3, 2, 3);
imshow(roi_real);
title('Case 2: Real Photo ROI');
subplot(3, 2, 4);
imshow(response_real, []);
title('Response: Strong, Continuous');

% --- CASE 3: Real-World Photo (Fake) ---
disp('Processing Case 3: Fake Photo...');
roi_fake = extractROI(aligned_fake_photo, roi_rect);
response_fake = abs(imfilter(im2double(roi_fake), g.SpatialKernel, 'conv'));

subplot(3, 2, 5);
imshow(roi_fake);
title('Case 3: Fake Photo ROI');
subplot(3, 2, 6);
imshow(response_fake, []);
title('Response: Discontinuous/Broken');

disp('Comparison complete.');

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