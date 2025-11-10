% compare_gabor_3d_interactive.m
% An interactive script to toggle the 3D Gabor responses.

clear; clc; close all;

% --- 1. Setup & Preprocessing ---
disp('Loading images and preprocessing...');
ref_filename = 'ref_camera.png';
real_photo_filename = 'test_note_100_1.jpg';
fake_photo_filename = 'test_note_fake_colour.jpg';

ref_img = imread(ref_filename);
aligned_real_photo = warpImageAfterHomography(real_photo_filename, ref_filename);
aligned_fake_photo = warpImageAfterHomography(fake_photo_filename, ref_filename);
disp('--- Preprocessing Complete ---');

% --- 2. Gabor Filter Analysis ---
disp('Applying Gabor filter to all notes...');
wavelength = 4;
orientation = 90;
g_vert = gabor(wavelength, orientation);

gabor_mag_ref = abs(imfilter(im2double(convertToGrayscale(ref_img)), g_vert.SpatialKernel, 'conv'));
gabor_mag_real = abs(imfilter(im2double(convertToGrayscale(aligned_real_photo)), g_vert.SpatialKernel, 'conv'));
gabor_mag_fake = abs(imfilter(im2double(convertToGrayscale(aligned_fake_photo)), g_vert.SpatialKernel, 'conv'));

% --- 3. Interactive 3D Visualization ---
disp('Generating interactive 3D plot...');
fig = figure('Name', 'Interactive 3D Gabor Comparison', 'WindowState', 'maximized');

% Downsample the data for a cleaner plot
[X, Y] = meshgrid(1:5:size(gabor_mag_ref,2), 1:5:size(gabor_mag_ref,1));
Z_ref = gabor_mag_ref(1:5:end, 1:5:end);
Z_real = gabor_mag_real(1:5:end, 1:5:end);
Z_fake = gabor_mag_fake(1:5:end, 1:5:end);

% Plot the surfaces and get their handles
h_ref = surf(X, Y, Z_ref, 'FaceColor', 'blue', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;
h_real = surf(X, Y, Z_real, 'FaceColor', 'green', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
h_fake = surf(X, Y, Z_fake, 'FaceColor', 'red', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold off;

% Add labels, title, and legend
title('3D Gabor Response: Toggle Surfaces with Checkboxes');
xlabel('Image Width (X)'); ylabel('Image Height (Y)'); zlabel('Gabor Response (Energy)');
legend('Genuine (Reference)', 'Genuine (Real Photo)', 'Fake (Photocopy)');
grid on; axis tight; view(-30, 45);

% --- 4. Add GUI Checkboxes for Toggling ---
uicontrol('Style', 'checkbox', 'String', 'Genuine (Reference)', ...
    'Position', [20 80 150 20], 'Value', 1, ...
    'Callback', @(src, ~) set(h_ref, 'Visible', get(src, 'Value')));

uicontrol('Style', 'checkbox', 'String', 'Genuine (Real Photo)', ...
    'Position', [20 55 150 20], 'Value', 1, ...
    'Callback', @(src, ~) set(h_real, 'Visible', get(src, 'Value')));

uicontrol('Style', 'checkbox', 'String', 'Fake (Photocopy)', ...
    'Position', [20 30 150 20], 'Value', 1, ...
    'Callback', @(src, ~) set(h_fake, 'Visible', get(src, 'Value')));

disp('Analysis complete. Use checkboxes in the figure to toggle plots.');


% --- HELPER FUNCTION for Preprocessing ---
function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    ref_img = imread(ref_filename_str);
    test_img_denoised = applyNoiseFilter(test_filename_str);
    test_img = imrotate(test_img_denoised, 0);
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