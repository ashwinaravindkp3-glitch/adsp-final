% calibrate_channels.m
% Run this script once to measure the ideal feature values from the reference note.

clear; clc; close all;

% --- Configuration ---
ref_filename = 'reference_note_100.png';
ref_img = imread(ref_filename);

fprintf('Starting calibration process using %s...\n', ref_filename);

% --- Calibrate Security Thread ---
disp('Calibrating Security Thread...');
[~, thread_roi_rect] = analyzeSecurityThreadColor(ref_img); % We just need the ROI
thread_roi_color = imcrop(ref_img, thread_roi_rect);
thread_lab = rgb2lab(thread_roi_color);
a_channel = thread_lab(:,:,2);
calibration_data.thread.target_a = mean(a_channel(:));
fprintf('  -> Target a* for thread: %.4f\n', calibration_data.thread.target_a);

% --- Calibrate Bleed Lines ---
disp('Calibrating Bleed Lines...');
[~, line_roi_left, line_roi_right] = analyzeBleedLines(ref_img); % We just need ROIs
[target_L_left, target_b_left] = getBleedLineProperties(ref_img, line_roi_left);
[target_L_right, target_b_right] = getBleedLineProperties(ref_img, line_roi_right);
calibration_data.lines.target_L = (target_L_left + target_L_right) / 2;
calibration_data.lines.target_b = (target_b_left + target_b_right) / 2;
fprintf('  -> Target L* for bleed lines: %.4f\n', calibration_data.lines.target_L);
fprintf('  -> Target b* for bleed lines: %.4f\n', calibration_data.lines.target_b);

% --- Save Calibration Data ---
save('calibration_data.mat', 'calibration_data');
disp('Calibration complete. Data saved to calibration_data.mat');

% --- Helper function for bleed line calibration ---
function [mean_L, mean_b] = getBleedLineProperties(image_rgb, roi_rect)
    roi_img_rgb = imcrop(image_rgb, roi_rect);
    roi_img_gray = rgb2gray(roi_img_rgb);
    roi_img_lab = rgb2lab(roi_img_rgb);
    se = strel('line', 10, 0);
    line_intensity_map = imbothat(roi_img_gray, se);
    line_mask = imbinarize(line_intensity_map);
    
    L_channel = roi_img_lab(:,:,1);
    b_channel = roi_img_lab(:,:,3); % Using b* for blueness
    
    line_L_values = L_channel(line_mask);
    line_b_values = b_channel(line_mask);
    
    mean_L = mean(line_L_values);
    mean_b = mean(line_b_values);
end