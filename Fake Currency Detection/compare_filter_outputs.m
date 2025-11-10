% comprehensive_comparator.m
% Applies advanced signal processing techniques to a genuine reference note and
% a fake note, displaying the results side-by-side for direct comparison.

clear; clc; close all;

% --- 1. Setup ---
disp('Loading images...');
% !!! IMPORTANT: Set your filenames here !!!
ref_filename = 'reference_note_100.png';    % High-quality scan of a genuine note
fake_filename = 'test_note_fake_colour.jpg'; % The counterfeit note to analyze

ref_img = imread(ref_filename);
fake_img = imread(fake_filename);

% --- 2. Preprocessing: Align the Fake Note to the Reference ---
disp('Aligning fake note to reference perspective...');
% This step is CRITICAL for a meaningful comparison.
aligned_fake_img = align_image_to_reference(fake_img, ref_img);

% Prepare grayscale versions for filters that need them
ref_gray = rgb2gray(ref_img);
fake_gray_aligned = rgb2gray(aligned_fake_img);

disp('Starting analysis... Each technique will open in a new comparison window.');

% --- 3. Run All Analyses ---

%% 1. Edge / Line Detection
disp('Running Edge / Line Detection...');
% Canny edge detection
canny_ref = edge(ref_gray, 'canny');
canny_fake = edge(fake_gray_aligned, 'canny');
figure('Name','1: Canny Edge Detection Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(canny_ref); title('Reference: Canny Edges');
subplot(1, 2, 2); imshow(canny_fake); title('Fake: Canny Edges');

%% 2. Morphological Filtering (Black-Hat)
disp('Running Morphological Filtering...');
se = strel('disk', 3);
% Black-hat is great for finding fine, dark print details.
blackhat_ref = imbothat(ref_gray, se);
blackhat_fake = imbothat(fake_gray_aligned, se);
figure('Name','2: Black-Hat Filter Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(blackhat_ref); title('Reference: Black-Hat (Fine Dark Lines)');
subplot(1, 2, 2); imshow(blackhat_fake); title('Fake: Black-Hat (Fine Dark Lines)');

%% 3. Frequency-Domain Filtering
disp('Running Frequency-Domain Filtering...');
F_ref = fftshift(fft2(im2double(ref_gray)));
spectrum_ref = log(1 + abs(F_ref));
F_fake = fftshift(fft2(im2double(fake_gray_aligned)));
spectrum_fake = log(1 + abs(F_fake));
figure('Name','3: 2D FFT Spectrum Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(spectrum_ref, []); title('Reference: 2D FFT Spectrum');
subplot(1, 2, 2); imshow(spectrum_fake, []); title('Fake: 2D FFT Spectrum');

%% 4. Color Channel Analysis (a* Green-Red)
disp('Running Color Analysis...');
% The a* channel is excellent for finding specific green security inks.
lab_ref = rgb2lab(ref_img);
a_channel_ref = lab_ref(:,:,2);
lab_fake = rgb2lab(aligned_fake_img);
a_channel_fake = lab_fake(:,:,2);
figure('Name','4: a* Channel (Green-Red) Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(a_channel_ref, []); title('Reference: a* Channel');
subplot(1, 2, 2); imshow(a_channel_fake, []); title('Fake: a* Channel');

%% 5. Local Contrast (Difference of Gaussians)
disp('Running Local Contrast Enhancement...');
% DoG is effective for finding microprint and detailed textures.
dog_ref = imgaussfilt(ref_gray, 1) - imgaussfilt(ref_gray, 3);
dog_fake = imgaussfilt(fake_gray_aligned, 1) - imgaussfilt(fake_gray_aligned, 3);
figure('Name','5: Difference of Gaussians Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(dog_ref, []); title('Reference: Difference of Gaussians');
subplot(1, 2, 2); imshow(dog_fake, []); title('Fake: Difference of Gaussians');

%% 6. Directional Filtering (Horizontal Gabor)
disp('Running Directional Filtering...');
g_horiz = gabor(4, 0);
gabor_ref = abs(imfilter(im2double(ref_gray), g_horiz.SpatialKernel, 'conv'));
gabor_fake = abs(imfilter(im2double(fake_gray_aligned), g_horiz.SpatialKernel, 'conv'));
figure('Name','6: Horizontal Gabor Filter Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(gabor_ref, []); title('Reference: Horizontal Gabor Response');
subplot(1, 2, 2); imshow(gabor_fake, []); title('Fake: Horizontal Gabor Response');

%% 7. Simulated Angled Light (Emboss)
disp('Running Simulated Light Analysis...');
% The emboss filter is a proxy for detecting the raised intaglio ink texture.
emboss_filter = [-2 -1 0; -1 1 1; 0 1 2];
emboss_ref = imfilter(ref_gray, emboss_filter);
emboss_fake = imfilter(fake_gray_aligned, emboss_filter);
figure('Name','7: Emboss Filter Comparison','WindowState','maximized');
subplot(1, 2, 1); imshow(emboss_ref, []); title('Reference: Emboss Filter (Texture)');
subplot(1, 2, 2); imshow(emboss_fake, []); title('Fake: Emboss Filter (Texture)');

disp('--- Comprehensive Comparison Complete ---');

%% --- HELPER FUNCTION FOR IMAGE ALIGNMENT (CORRECTED VERSION) ---
function warped_img = align_image_to_reference(test_img, ref_img)
    % Aligns test_img to the perspective of ref_img using feature-based homography.
    
    % Ensure images are grayscale for feature detection
    ref_gray = rgb2gray(ref_img);
    test_gray = rgb2gray(test_img);
    
    % Detect ORB features (fast and effective)
    ref_points_all = detectORBFeatures(ref_gray);
    test_points_all = detectORBFeatures(test_gray);
    
    %% --- MODIFICATION START: Limit the number of features to prevent memory errors ---
    max_features = 5000; % Use the 5000 strongest features
    ref_points = ref_points_all.selectStrongest(max_features);
    test_points = test_points_all.selectStrongest(max_features);
    %% --- MODIFICATION END ---
    
    % Extract feature descriptors from the selected points
    [ref_features, ref_valid_points] = extractFeatures(ref_gray, ref_points);
    [test_features, test_valid_points] = extractFeatures(test_gray, test_points);
    
    % Match features
    index_pairs = matchFeatures(ref_features, test_features, 'MaxRatio', 0.7, 'Unique', true);
    
    matched_ref_points = ref_valid_points(index_pairs(:, 1), :);
    matched_test_points = test_valid_points(index_pairs(:, 2), :);
    
    % Check if enough matches were found
    if size(matched_ref_points, 1) < 10 % Need at least 10 matches for a stable result
        warning('Not enough strong matches found to compute homography. Returning unaligned image.');
        warped_img = test_img;
        return;
    end
    
    % Estimate the geometric transformation (homography)
    try
        [tform, ~] = estimateGeometricTransform2D(matched_test_points, matched_ref_points, 'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
    catch
        warning('Could not compute homography. Returning unaligned image.');
        warped_img = test_img;
        return;
    end
    
    % Warp the test image to align with the reference
    output_view = imref2d(size(ref_img));
    warped_img = imwarp(test_img, tform, 'OutputView', output_view);
end