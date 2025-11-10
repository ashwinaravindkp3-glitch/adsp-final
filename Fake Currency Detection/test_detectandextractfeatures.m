% test_detectAndExtractFeatures.m
% A script to test the functionality of the detectAndExtractFeatures module.

clear; clc; close all;

% --- 1. Setup ---
image_filename = 'reference_note_100.png'; 

if ~exist(image_filename, 'file')
    error('Test image "%s" not found. Please place your reference image in the directory.', image_filename);
end

disp('Loading image...');
color_img = imread(image_filename);

% --- 2. Execution ---
% Call the prerequisite module to get the grayscale image
disp('Running prerequisite module: convertToGrayscale...');
gray_img = convertToGrayscale(color_img);

% Call the new function we are testing
disp('Running detectAndExtractFeatures.m...');
[points, features] = detectAndExtractFeatures(gray_img);
disp(['Detection complete. Found ', num2str(length(points)), ' features.']);


% --- 3. Visualization ---
% Display the image and plot the detected points on top
figure('Name', 'Feature Detection Test', 'NumberTitle', 'off');
imshow(gray_img);
hold on; 

% Plot the 100 strongest points for clarity
plot(points.selectStrongest(100)); 

title('100 Strongest ORB Features Detected');
hold off;

disp('Test script finished. Please check the figure window.');