function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
%warpImageAfterHomography Performs the full geometric alignment pipeline.
%
%   Inputs:
%       test_filename_str - Filename of the test image (e.g., a photo).
%       ref_filename_str  - Filename of the reference image (the golden standard).
%
%   Outputs:
%       warped_img        - The test image, geometrically aligned to the reference.

    % --- 1. Load Images ---
    ref_img = imread(ref_filename_str);
    
    % --- 2. Denoise and Standardize Scale ---
    % Denoise the test image first using its filename.
    test_img_denoised = applyNoiseFilter(test_filename_str);
    
    % Standardize the scale by resizing the test image to match the reference's height.
    % Note: The unnecessary imrotate step has been permanently removed.
    ref_height = size(ref_img, 1);
    test_img = imresize(test_img_denoised, [ref_height, NaN]);
    
    % --- 3. Perform Homography Estimation ---
    % Convert images to grayscale for feature detection.
    ref_gray = convertToGrayscale(ref_img);
    test_gray = convertToGrayscale(test_img);
    
    % Detect, extract, and match features.
    [ref_points, ref_features] = detectAndExtractFeatures(ref_gray);
    [test_points, test_features] = detectAndExtractFeatures(test_gray);
    [matched_points_test, matched_points_ref, ~] = ...
        matchFeaturesBetweenImages(test_points, test_features, ref_points, ref_features);
    
    % Estimate the perspective transformation.
    [tform, ~] = estimateHomography(matched_points_test, matched_points_ref);
    
    % --- 4. Warp the Color Image ---
    % Apply the calculated transformation to the color version of the test image.
    warped_img = warpImage(test_img, ref_img, tform);
end