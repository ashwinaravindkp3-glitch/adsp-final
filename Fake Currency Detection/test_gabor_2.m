% compare_gabor_peaks.m
% A script to count significant Gabor peaks above an average-value plane.

clear; clc; close all;

% --- 1. Setup & Preprocessing ---
disp('Loading images and preprocessing...');
ref_filename = 'ref_camera.png';
fake_photo_filename = 'test_note_fake_colour.jpg';

ref_img = imread(ref_filename);
aligned_fake_photo = warpImageAfterHomography(fake_photo_filename, ref_filename);
disp('--- Preprocessing Complete ---');

% --- 2. Gabor Filter Analysis ---
disp('Applying Gabor filter to both notes...');
wavelength = 4;
orientation = 90; % Vertical
g_vert = gabor(wavelength, orientation);

% Apply filter to the REFERENCE note
ref_gray = convertToGrayscale(ref_img);
gabor_mag_ref = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));

% Apply filter to the FAKE note
fake_gray = convertToGrayscale(aligned_fake_photo);
gabor_mag_fake = abs(imfilter(im2double(fake_gray), g_vert.SpatialKernel, 'conv'));

% --- 3. Peak Analysis ---
disp('Analyzing peaks...');
% Calculate the average response of the REFERENCE note. This is our threshold plane.
average_plane_height = mean(gabor_mag_ref(:));

% Find all local maxima (peaks) in both response images.
peaks_ref = imregionalmax(gabor_mag_ref);
peaks_fake = imregionalmax(gabor_mag_fake);

% Count only the peaks that are ABOVE the average plane height.
significant_peaks_ref = gabor_mag_ref(peaks_ref) > average_plane_height;
count_ref = sum(significant_peaks_ref);

significant_peaks_fake = gabor_mag_fake(peaks_fake) > average_plane_height;
count_fake = sum(significant_peaks_fake);

% --- 4. 3D Visualization ---
disp('Generating 3D comparison plot...');
figure('Name', '3D Gabor Peak Analysis', 'WindowState', 'maximized');

% Downsample the data for a cleaner plot
[X, Y] = meshgrid(1:5:size(gabor_mag_ref,2), 1:5:size(gabor_mag_ref,1));
Z_ref = gabor_mag_ref(1:5:end, 1:5:end);
Z_fake = gabor_mag_fake(1:5:end, 1:5:end);

% Plot the surfaces
surf(X, Y, Z_ref, 'FaceColor', 'blue', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;
surf(X, Y, Z_fake, 'FaceColor', 'red', 'EdgeColor', 'none', 'FaceAlpha', 0.6);

% Create and plot the average plane
[planeX, planeY] = meshgrid(1:size(gabor_mag_ref,2), 1:size(gabor_mag_ref,1));
planeZ = ones(size(planeX)) * average_plane_height;
surf(planeX, planeY, planeZ, 'FaceColor', 'yellow', 'EdgeColor', 'none', 'FaceAlpha', 0.3);

hold off;

% Add labels, title, and legend
title('Significant Peaks Above Average Plane (Yellow)');
xlabel('Image Width (X)'); ylabel('Image Height (Y)'); zlabel('Gabor Response (Energy)');
legend('Genuine Note', 'Fake Note', 'Average Plane');
grid on; axis tight; view(-30, 45);

% --- 5. Print Final Counts ---
fprintf('\n--- SIGNIFICANT PEAK COUNT ---\n');
fprintf('Average Plane Height (from Reference): %.4f\n\n', average_plane_height);
fprintf('Genuine Note: Found %d peaks above the average plane.\n', count_ref);
fprintf('Fake Note:    Found %d peaks above the average plane.\n', count_fake);
fprintf('------------------------------------\n');

disp('Analysis complete.');


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