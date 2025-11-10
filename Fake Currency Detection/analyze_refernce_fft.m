% analyze_reference_fft.m
% A script to analyze the frequency spectrum of the security thread on the reference note.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading reference image...');
ref_img_color = imread('reference_note_100.jpg');
ref_gray = convertToGrayscale(ref_img_color);

% Define the Region of Interest (ROI) for the security thread.
% These coordinates [xmin, ymin, width, height] may need slight tuning.
% This is a vertical strip that covers the thread.
thread_roi_rect = [402, 45, 10, size(ref_gray, 1)-70]; 

% --- 2. Execution ---
disp('Extracting security thread ROI...');
thread_roi = extractROI(ref_gray, thread_roi_rect);

disp('Computing 2D FFT of the ROI...');
% Compute the 2D Fast Fourier Transform
F = fft2(im2double(thread_roi));

% Shift the zero-frequency component to the center for visualization
F_shifted = fftshift(F);

% Calculate the magnitude spectrum and apply a log transform for better visibility
spectrum_vis = log(1 + abs(F_shifted));


% --- 3. Visualization ---
figure('Name', 'Security Thread FFT Analysis', 'NumberTitle', 'off');

% Show the original image with the ROI highlighted
subplot(1, 3, 1);
imshow(ref_img_color);
hold on;
rectangle('Position', thread_roi_rect, 'EdgeColor', 'r', 'LineWidth', 2);
hold off;
title('Reference Note with ROI');

% Show the cropped ROI
subplot(1, 3, 2);
imshow(thread_roi);
title('Security Thread ROI');

% Show the resulting frequency spectrum
subplot(1, 3, 3);
imshow(spectrum_vis, []); % Use [] to autoscale the display range
title('Frequency Spectrum');

disp('Analysis complete.');