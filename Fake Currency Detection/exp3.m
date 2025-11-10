%==========================================================================
% Morphological Operations on a Currency Note Image (Revised Plotting)
%==========================================================================

%% Housekeeping
clc;
clear all;
close all;

%% 1. Load Image and Add Noise
try
    inputImage = imread('test_note_100_1.jpg');
catch
    error('Image file not found. Please check the path.');
end
grayscaleImage = rgb2gray(inputImage);
noisyImage = imnoise(grayscaleImage, 'salt & pepper', 0.02);

%% 2. Define Structuring Elements
se_rectangle = strel('rectangle', [3, 2]);
se_square = strel('square', 3);
se_disk = strel('disk', 2);

%% 3. Perform Morphological Operations
% Dilation
dilated_rect = imdilate(noisyImage, se_rectangle);
dilated_square = imdilate(noisyImage, se_square);
dilated_disk = imdilate(noisyImage, se_disk);

% Erosion
eroded_rect = imerode(noisyImage, se_rectangle);
eroded_square = imerode(noisyImage, se_square);
eroded_disk = imerode(noisyImage, se_disk);

%% 4. Display the Results in Separate Figures

% --- Figure 1: Dilation with Rectangle ---
figure('Name', 'Dilation Comparison 1');
subplot(1, 2, 1);
imshow(grayscaleImage);
title('Original Grayscale');
subplot(1, 2, 2);
imshow(dilated_rect);
title('Dilation (Rectangle)');

% --- Figure 2: Dilation with Square & Disk ---
figure('Name', 'Dilation Comparison 2');
subplot(1, 2, 1);
imshow(dilated_square);
title('Dilation (Square)');
subplot(1, 2, 2);
imshow(dilated_disk);
title('Dilation (Disk)');

% --- Figure 3: Erosion with Rectangle ---
figure('Name', 'Erosion Comparison 1');
subplot(1, 2, 1);
imshow(noisyImage);
title('Image with Noise');
subplot(1, 2, 2);
imshow(eroded_rect);
title('Erosion (Rectangle)');

% --- Figure 4: Erosion with Square & Disk ---
figure('Name', 'Erosion Comparison 2');
subplot(1, 2, 1);
imshow(eroded_square);
title('Erosion (Square)');
subplot(1, 2, 2);
imshow(eroded_disk);
title('Erosion (Disk)');