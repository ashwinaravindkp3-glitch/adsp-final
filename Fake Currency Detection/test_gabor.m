% compare_gabor_orientations.m
% A script to apply Gabor filters at different orientations to the entire reference image.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading reference image...');
ref_img = imread('test_note_fake_colour.jpg');
ref_gray = convertToGrayscale(ref_img);

disp('Applying Gabor filters at multiple orientations...');

% --- 2. Vertical Gabor Filter (90 degrees) ---
g_vert = gabor(4, 90);
gabor_mag_vert = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));
figure('Name','Vertical Gabor Filter (90 deg)','WindowState','maximized');
imshow(gabor_mag_vert, []);
title('Gabor Filter Response (Vertical)');

% --- 3. Horizontal Gabor Filter (0 degrees) ---
g_horiz = gabor(4, 0);
gabor_mag_horiz = abs(imfilter(im2double(ref_gray), g_horiz.SpatialKernel, 'conv'));
figure('Name','Horizontal Gabor Filter (0 deg)','WindowState','maximized');
imshow(gabor_mag_horiz, []);
title('Gabor Filter Response (Horizontal)');

% --- 4. Diagonal Gabor Filter (45 degrees) ---
g_45 = gabor(8, 45); % Using wavelength=8 as in your previous script
gabor_mag_45 = abs(imfilter(im2double(ref_gray), g_45.SpatialKernel, 'conv'));
figure('Name', '45-Degree Gabor Filter', 'WindowState', 'maximized');
imshow(gabor_mag_45, []);
title('45-Degree Gabor Magnitude Response');

disp('Analysis complete.');