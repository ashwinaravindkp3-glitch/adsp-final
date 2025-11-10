% test_illumination.m
% A script to test the illumination normalization module.

clear; clc; close all;

% --- 1. Setup ---
% Use your test photo to see the effect.
image_filename = 'test_note_100.jpg';
if ~exist(image_filename, 'file'), error('Test image not found.'); end

img_color = imread(image_filename);
% Let's also create a synthetically shadowed version to see the effect more clearly
[rows, cols, ~] = size(img_color);
[X, ~] = meshgrid(1:cols, 1:rows);
shadow = mat2gray(X, [1, cols*2]); % Create a left-to-right brightness gradient
img_shadowed = im2uint8(im2double(img_color) .* shadow);


% --- 2. Execution ---
disp('Normalizing illumination...');
img_normalized = normalizeIllumination(img_shadowed);


% --- 3. Visualization ---
figure('Name', 'Illumination Normalization Test', 'NumberTitle', 'off');
subplot(1, 2, 1);
imshow(img_shadowed);
title('Image with Synthetic Shadow');

subplot(1, 2, 2);
imshow(img_normalized);
title('After Homomorphic Filtering');

disp('Test script finished.');