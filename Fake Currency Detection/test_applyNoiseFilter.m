% test_applyNoiseFilter.m
% A script to test the functionality of the applyNoiseFilter module.

clear; clc; close all;

% --- 1. Setup ---
% Specify the path to a sample image.
% Make sure you have an image file (e.g., 'reference_note.png') in this directory.
image_filename = 'reference_note_100.jpg'; 

% Check if the image file exists before proceeding.
if ~exist(image_filename, 'file')
    error('Test image "%s" not found. Please place a sample image in the directory.', image_filename);
end

disp('Loading original image...');
original_img = imread(image_filename);

% Add synthetic 'salt & pepper' noise to the image to simulate sensor defects.
% This makes the effect of the filter more obvious for testing.
%disp('Adding synthetic noise for testing purposes...');
%noisy_img = imnoise(original_img, 'salt & pepper', 0.02);

% Create a temporary file for the noisy image, as our function expects a file path.
%temp_noisy_filename = 'temp_noisy_image.jpg';
%imwrite(noisy_img, temp_noisy_filename);


% --- 2. Execution ---
% Call the function we are testing.
%disp('Running applyNoiseFilter.m on the noisy image...');
denoised_img = applyNoiseFilter(image_filename);
%disp('Filtering complete.');


% --- 3. Visualization & Cleanup ---
% Display the results in a single figure for comparison.
figure('Name', 'Noise Filter Test', 'NumberTitle', 'off');

subplot(1, 3, 1);
imshow(original_img);
title('Original Image');

%subplot(1, 3, 2);
%imshow(noisy_img);
%title('Image with Synthetic Noise');

subplot(1, 3, 3);
imshow(denoised_img);
title('Denoised Image (Bilateral Filter)');

% Clean up the temporary file.
delete(temp_noisy_filename);

disp('Test script finished. Observe the output figure.');