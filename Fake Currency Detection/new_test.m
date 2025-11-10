% compare_gabor_3d_three_notes.m
% A script to compare the 3D Gabor responses of a reference, a real photo, and a fake note.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
ref_filename = 'ref_scanner.png';
real_photo_filename = 'test_note_100_1.jpg';
fake_photo_filename = 'test_note_fake_colour.jpg';

ref_img = imread(ref_filename);

% --- 2. Preprocessing ---
disp('Preprocessing real photo...');
aligned_real_photo = warpImageAfterHomography(real_photo_filename, ref_filename);
disp('Preprocessing fake photo...');
aligned_fake_photo = warpImageAfterHomography(fake_photo_filename, ref_filename);
disp('--- Preprocessing Complete ---');

% --- 3. Gabor Filter Analysis ---
% Define the vertical Gabor filter
wavelength = 4;
orientation = 90;
g_vert = gabor(wavelength, orientation);

% Apply filter to the REFERENCE note
disp('Applying Gabor filter to Reference Note...');
ref_gray = convertToGrayscale(ref_img);
gabor_mag_ref = abs(imfilter(im2double(ref_gray), g_vert.SpatialKernel, 'conv'));

% Apply filter to the REAL PHOTO
disp('Applying Gabor filter to Real Photo...');
real_gray = convertToGrayscale(aligned_real_photo);
gabor_mag_real = abs(imfilter(im2double(real_gray), g_vert.SpatialKernel, 'conv'));

% Apply filter to the FAKE note
disp('Applying Gabor filter to Fake Note...');
fake_gray = convertToGrayscale(aligned_fake_photo);
gabor_mag_fake = abs(imfilter(im2double(fake_gray), g_vert.SpatialKernel, 'conv'));

% --- 4. 3D Visualization ---
disp('Generating 3D comparison plot...');
figure('Name', '3D Gabor Response Comparison', 'WindowState', 'maximized');

% Downsample the data for a cleaner plot
[X, Y] = meshgrid(1:5:size(gabor_mag_ref,2), 1:5:size(gabor_mag_ref,1));
Z_ref = gabor_mag_ref(1:5:end, 1:5:end);
Z_real = gabor_mag_real(1:5:end, 1:5:end);
Z_fake = gabor_mag_fake(1:5:end, 1:5:end);

% Plot the REFERENCE note's response as a blue surface
surf(X, Y, Z_ref, 'FaceColor', 'blue', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on; % Hold the plot to add the other surfaces

% Plot the REAL PHOTO's response as a green surface
surf(X, Y, Z_real, 'FaceColor', 'green', 'EdgeColor', 'none', 'FaceAlpha', 0.6);

% Plot the FAKE note's response as a red surface
surf(X, Y, Z_fake, 'FaceColor', 'red', 'EdgeColor', 'none', 'FaceAlpha', 0.6);

hold off; % Release the plot

% Add labels, title, and legend
title('3D Gabor Response: Genuine (Blue/Green) vs. Fake (Red)');
xlabel('Image Width (X)');
ylabel('Image Height (Y)');
zlabel('Gabor Response (Energy)');
legend('Genuine (Reference)', 'Genuine (Real Photo)', 'Fake (Photocopy)');
grid on;
axis tight;
view(-30, 45); % Set a good viewing angle

disp('Analysis complete.');


% --- HELPER FUNCTION for Preprocessing ---
function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
    ref_img = imread(ref_filename_str);
    test_img_denoised = applyNoiseFilter(test_filename_str);
    test_img = imrotate(test_img_denoised, -90);
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