% debug_ChannelB.m (Version 4 with Full Image Visualization)
% A script to debug Channel B by visualizing results on the full image.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
ref_img = imread('reference_note_100.png');
real_photo = imread('test_note_100_1.jpg');
fake_photo = imread('test_note_fake_colour.jpg');

% --- 2. Preprocessing ---
disp('Preprocessing real photo...');
aligned_real_photo = warpImageAfterHomography(real_photo, ref_img);
disp('Preprocessing fake photo...');
aligned_fake_photo = warpImageAfterHomography(fake_photo, ref_img);

% --- 3. Define Image Cases ---
image_cases = {ref_img, aligned_real_photo, aligned_fake_photo};
case_names = {'Case 1: Ideal Reference', 'Case 2: Real Photo', 'Case 3: Fake Photo'};
scores = zeros(1, 3);

% --- 4. Loop Through and Analyze Each Case ---
for i = 1:3
    current_image = image_cases{i};
    disp(['--- Analyzing ', case_names{i}, ' ---']);
    
    % --- Core Analysis Logic ---
    roi_rect = [955, 1, 65, size(current_image, 1)-1]; 
    thread_roi_color = extractROI(current_image, roi_rect);
    thread_lab = rgb2lab(thread_roi_color);
    a_channel_roi = thread_lab(:,:,2);
    avg_a_star = mean(a_channel_roi(:));
    final_score = 1 / (1 + exp(0.5 * (avg_a_star + 2)));
    scores(i) = final_score;
    
    % --- New Full-Image Visualization ---
    % Create a "green mask" for the entire image
    full_lab = rgb2lab(current_image);
    a_channel_full = full_lab(:,:,2);
    green_mask = a_channel_full < -5; % Threshold to find "green" pixels
    
    % Create a new figure for each case
    figure('Name', case_names{i}, 'WindowState', 'maximized');
    
    % Use imshowpair to blend the mask with the original image
    imshowpair(current_image, green_mask, 'blend');
    
    hold on;
    % Draw the ROI box we are analyzing
    rectangle('Position', roi_rect, 'EdgeColor', 'r', 'LineWidth', 2);
    title_text = sprintf('%s | Final Score: %.4f', case_names{i}, final_score);
    title(title_text);
    hold off;
end

% --- 5. Display Final Scores ---
fprintf('\n--- Channel B Debugging Results ---\n');
fprintf('%s: \tScore = %.4f\n', case_names{1}, scores(1));
fprintf('%s: \t\tScore = %.4f\n', case_names{2}, scores(2));
fprintf('%s: \t\tScore = %.4f\n', case_names{3}, scores(3));
disp('------------------------------------');

% (Helper function is the same)
function warped_img = warpImageAfterHomography(test_img, ref_img)
    test_img = imrotate(test_img, -90);
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