% test_convertToGrayscale.m
% A script to test the functionality of the convertToGrayscale module.

clear; clc; close all;

% --- 1. Setup ---
% Specify the path to a sample image.
image_filename = 'reference_note_100.png'; 

if ~exist(image_filename, 'file')
    error('Test image "%s" not found. Please place a sample image in the directory.', image_filename);
end

disp('Loading original color image...');
color_img = imread(image_filename);


% --- 2. Execution ---
% Call the function we are testing.
disp('Running convertToGrayscale.m...');
gray_img = convertToGrayscale(color_img);
disp('Conversion complete.');


% --- 3. Visualization ---
% Display the results in a single figure for comparison.
figure('Name', 'Grayscale Conversion Test', 'NumberTitle', 'off');

subplot(1, 2, 1);
imshow(color_img);
title('Original Color Image');

subplot(1, 2, 2);
imshow(gray_img);
title('Grayscale Image');

disp('Test script finished. Observe the output figure.');