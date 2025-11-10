% compare_security_thread.m
% A script to test and visualize the security thread detector on the reference and test images separately.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
ref_filename = 'ref_camera.png';
real_photo_filename = 'test_note_fake_colour.jpg';

% --- 2. Preprocess Test Image ---
disp('Preprocessing test image...');
aligned_real_photo = warpImageAfterHomography(real_photo_filename, ref_filename);

% The reference image is already clean and aligned, so we just load it.
ref_img = imread(ref_filename);

% --- 3. Analyze and Visualize REFERENCE Image ---
disp('--- Analyzing Reference Image ---');
[score_ref, thread_roi_rect_ref, viz_ref] = analyzeSecurityThreadColor(ref_img);

% Create a new figure for the reference image results
figure('Name', 'Reference Image Analysis', 'WindowState', 'maximized');
subplot(1, 2, 1);
imshow(ref_img);
hold on;
rectangle('Position', thread_roi_rect_ref, 'EdgeColor', 'r', 'LineWidth', 2);
title_text = sprintf('Reference Image\nFinal Score: %.2f', score_ref);
title(title_text, 'FontSize', 12);
hold off;
subplot(1, 2, 2);
imshow(viz_ref.a_channel, []);
title('a* Channel (Green = Dark)');

% --- 4. Analyze and Visualize TEST Image ---
disp('--- Analyzing Test Image ---');
[score_real, thread_roi_rect_real, viz_real] = analyzeSecurityThreadColor(aligned_real_photo);

% Create a second figure for the test image results
figure('Name', 'Test Image Analysis', 'WindowState', 'maximized');
subplot(1, 2, 1);
imshow(aligned_real_photo);
hold on;
rectangle('Position', thread_roi_rect_real, 'EdgeColor', 'r', 'LineWidth', 2);
title_text = sprintf('Test Image (Aligned)\nFinal Score: %.2f', score_real);
title(title_text, 'FontSize', 12);
hold off;
subplot(1, 2, 2);
imshow(viz_real.a_channel, []);
title('a* Channel (Green = Dark)');

% --- 5. Display Numerical Scores ---
fprintf('\n--- Security Thread Detection Results ---\n');
fprintf('Reference Image Score: %.4f\n', score_ref);
fprintf('Test Image Score:      %.4f\n', score_real);
disp('------------------------------------');


% --- LOCAL FUNCTIONS ---

function [score, roi_rect, viz_data] = analyzeSecurityThreadColor(aligned_color_image)
    % This function analyzes the thread based on its "greenness" in the L*a*b* space.
    roi_rect = [867, 122, 126, 617]  
    thread_roi_color = extractROI(aligned_color_image, roi_rect);
    thread_lab = rgb2lab(thread_roi_color);
    a_channel = thread_lab(:,:,2);
    avg_a_star = mean(a_channel(:));
    score = 1 / (1 + exp(0.5 * (avg_a_star + 2)));
    viz_data.a_channel = a_channel;
end

function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    % This helper function contains the full preprocessing logic.
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