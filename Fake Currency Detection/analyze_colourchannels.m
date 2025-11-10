% compare_ref_vs_fake_visuals.m
% A comprehensive script to visually compare the reference and fake notes
% across a wide variety of image processing techniques.

clear; clc; close all;

% --- 1. Setup ---
disp('--- Starting Full Visual Comparison ---');
ref_filename = 'reference_note_10.png';
fake_photo_filename = 'test_note_100_1.jpg';

% --- 2. Preprocessing ---
disp('Loading and preprocessing images...');
ref_img = imread(ref_filename);
% Preprocess the fake note to align it with the reference
aligned_fake_photo = warpImageAfterHomography(fake_photo_filename, ref_filename);
disp('--- Preprocessing Complete ---');

% --- 3. Run Analyses for Both Images ---
disp('Generating visualizations for Reference Note...');
generate_visual_analysis(ref_img, 'Reference Note Analysis');

disp('Generating visualizations for Fake Note...');
generate_visual_analysis(aligned_fake_photo, 'Fake Note Analysis');

disp('--- Analysis Complete ---');


% --- HELPER FUNCTION TO GENERATE ALL PLOTS ---
function generate_visual_analysis(image_color, figure_name)
    
    image_gray = convertToGrayscale(image_color);

    % Create a new figure for this image
    figure('Name', figure_name, 'WindowState', 'maximized');
    sgtitle(figure_name);

    % a) Original and Grayscale
    subplot(3, 4, 1); imshow(image_color); title('Original Color');
    subplot(3, 4, 2); imshow(image_gray); title('Grayscale');

    % b) HSV Channels
    img_hsv = rgb2hsv(image_color);
    subplot(3, 4, 3); imshow(img_hsv(:,:,1)); title('Hue Channel');
    subplot(3, 4, 4); imshow(img_hsv(:,:,2)); title('Saturation Channel');

    % c) L*a*b* Channels
    lab = rgb2lab(image_color);
    subplot(3, 4, 5); imshow(lab(:,:,1), []); title('L* Channel (Lightness)');
    subplot(3, 4, 6); imshow(lab(:,:,2), []); title('a* Channel (Green-Red)');
    subplot(3, 4, 7); imshow(lab(:,:,3), []); title('b* Channel (Blue-Yellow)');

    % d) Contrast and Negative
    img_negative = imcomplement(image_color);
    subplot(3, 4, 8); imshow(img_negative); title('Negative Image');
    
    img_clahe = adapthisteq(image_gray);
    subplot(3, 4, 9); imshow(img_clahe); title('CLAHE (Adaptive Contrast)');

    % e) Filters and Edges
    img_edges = edge(image_gray, 'canny');
    subplot(3, 4, 10); imshow(img_edges); title('Canny Edges');
    
    emboss_filter = [-2 -1 0; -1 1 1; 0 1 2];
    img_emboss = imfilter(image_gray, emboss_filter);
    subplot(3, 4, 11); imshow(img_emboss, []); title('Emboss Filter');
    
    % f) Gabor Filter (Vertical)
    g_vert = gabor(4, 90);
    gabor_mag_vert = abs(imfilter(im2double(image_gray), g_vert.SpatialKernel, 'conv'));
    subplot(3, 4, 12); imshow(gabor_mag_vert, []); title('Vertical Gabor Filter');
end


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