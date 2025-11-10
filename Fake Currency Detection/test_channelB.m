% test_full_ChannelB_visual.m
% A script to test and VISUALIZE the complete Channel B detector.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
ref_filename = 'reference_note_10.png';
real_photo_filename = 'test_note_100_1.jpg';
fake_photo_filename = 'test_note_fake_2.jpg';

% --- 2. Preprocessing ---
disp('Preprocessing real photo...');
aligned_real_photo = warpImageAfterHomography(real_photo_filename, ref_filename);
disp('Preprocessing fake photo...');
aligned_fake_photo = warpImageAfterHomography(fake_photo_filename, ref_filename);
ref_img = imread(ref_filename);

% --- 3. Execution & Visualization ---
disp('--- Running Full Channel B on All Cases ---');
scores_ref = run_channel_B(ref_img, 'Case 1: Ideal Reference');
scores_real = run_channel_B(aligned_real_photo, 'Case 2: Real Photo');
scores_fake = run_channel_B(aligned_fake_photo, 'Case 3: Fake Photo');

% --- 4. Display Final Numerical Scores ---
fprintf('\n--- FINAL SEPARATE CHANNEL B SCORES ---\n');
fprintf('Case 1 (Ideal Reference): \tThread = %.4f, \tBleed Lines = %.4f\n', scores_ref.thread, scores_ref.lines);
fprintf('Case 2 (Real Photo): \t\tThread = %.4f, \tBleed Lines = %.4f\n', scores_real.thread, scores_real.lines);
fprintf('Case 3 (Fake Photo): \t\tThread = %.4f, \tBleed Lines = %.4f\n', scores_fake.thread, scores_fake.lines);
disp('------------------------------------');


% --- LOCAL FUNCTIONS ---

function scores_B = run_channel_B(aligned_color_image, case_name)
    % This orchestrator now also handles plotting.
    disp(['Analyzing ', case_name, '...']);
    
    % Run Detectors
    [score_thread, thread_roi_rect] = analyzeSecurityThreadColor(aligned_color_image);
    [score_lines, line_roi_left, line_roi_right] = analyzeBleedLines(aligned_color_image);
    
    % Package Scores
    scores_B.thread = score_thread;
    scores_B.lines = score_lines;
    
    % Create Visualization
    figure('Name', case_name, 'WindowState', 'maximized');
    imshow(aligned_color_image);
    hold on;
    % Draw ROIs
    rectangle('Position', thread_roi_rect, 'EdgeColor', 'r', 'LineWidth', 2);
    rectangle('Position', line_roi_left, 'EdgeColor', 'b', 'LineWidth', 2);
    rectangle('Position', line_roi_right, 'EdgeColor', 'b', 'LineWidth', 2);
    % Create title with scores
    title_text = sprintf('%s\nThread Score: %.2f | Bleed Lines Score: %.2f', ...
                         case_name, score_thread, score_lines);
    title(title_text, 'FontSize', 12);
    legend('Security Thread ROI', 'Bleed Lines ROIs');
    hold off;
end

function [score, roi_rect] = analyzeSecurityThreadColor(aligned_color_image)
    roi_rect = [930, 25, 105, 725]
    thread_roi_color = extractROI(aligned_color_image, roi_rect);
    thread_lab = rgb2lab(thread_roi_color);
    a_channel = thread_lab(:,:,2);
    avg_a_star = mean(a_channel(:));
    score = 1 / (1 + exp(0.5 * (avg_a_star + 2)));
end

function [score, roi_rect_left, roi_rect_right] = analyzeBleedLines(aligned_color_image)
    roi_rect_left = [20, 150, 75, 200]; 
    roi_rect_right = [1572, 234, 95, 126]
    roi_left_color = extractROI(aligned_color_image, roi_rect_left);
    hsv_left = rgb2hsv(roi_left_color);
    avg_saturation_left = mean(hsv_left(:,:,2), 'all');
    roi_right_color = extractROI(aligned_color_image, roi_rect_right);
    hsv_right = rgb2hsv(roi_right_color);
    avg_saturation_right = mean(hsv_right(:,:,2), 'all');
    score_left = 1 / (1 + exp(-15 * (avg_saturation_left - 0.4)));
    score_right = 1 / (1 + exp(-15 * (avg_saturation_right - 0.4)));
    score = (score_left + score_right) / 2;
end

function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    ref_img = imread(ref_filename_str);
    test_img = applyNoiseFilter(test_filename_str);
    
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