
% interactive_roi_selector.m
% A script to interactively select and obtain coordinates for a Region of Interest.

clear; clc; close all;

% --- 1. Load Image ---
disp('Loading reference image...');
ref_img = imread('reference_note_10.png');

% --- 2. Display Image ---
figure('Name', 'Interactive ROI Selector', 'WindowState', 'maximized');
imshow(ref_img);
title('Drag and Resize the Rectangle to Select ROI. Press ENTER when done.');

% --- 3. Create Draggable Rectangle ---
% Initial position: somewhere in the middle with a reasonable size.
% [xmin, ymin, width, height]
initial_roi = [500, 500, 300, 150]; 

% Create a draggable rectangle object
h = drawrectangle('Position', initial_roi, 'Color', 'r', 'LineWidth', 2);

% --- 4. Wait for User Input ---
disp('Adjust the rectangle. Press ENTER in the command window when satisfied.');
pause; % Waits for any key press, but usually ENTER is used as a convention

% --- 5. Get Final Position and Display ---
final_position = round(h.Position); % Round to nearest integer pixels
fprintf('\n--- Final ROI Coordinates (xmin, ymin, width, height) ---\n');
fprintf('ROI: [%d, %d, %d, %d]\n', ...
        final_position(1), final_position(2), final_position(3), final_position(4));
disp('Use these coordinates in your analysis scripts.');

% --- Clean Up ---
delete(h); % Remove the rectangle from the figure
close(gcf); % Close the figure