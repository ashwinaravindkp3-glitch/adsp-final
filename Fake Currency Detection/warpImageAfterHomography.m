function warped_img = warpImageAfterHomography(test_filename_str, ref_filename_str)
%warpImageAfterHomography Performs complete geometric alignment pipeline
%
%   This function implements the preprocessing pipeline that:
%   1. Handles orientation (portrait -> landscape)
%   2. Standardizes scale to match reference height
%   3. Detects ORB features (5000+)
%   4. Matches features and estimates homography
%   5. Warps test image to align with reference
%
%   Inputs:
%       test_filename_str - Path to test image
%       ref_filename_str  - Path to reference image (ref_scanner.png)
%
%   Outputs:
%       warped_img        - Aligned color image ready for channel analysis

    fprintf('\n=== PREPROCESSING PIPELINE ===\n');

    % --- STEP 1: Load Images ---
    ref_img = imread(ref_filename_str);
    test_img = imread(test_filename_str);
    fprintf('Loaded: %s\n', test_filename_str);

    % --- STEP 2: Handle Orientation ---
    [height, width, ~] = size(test_img);
    if height > width
        test_img = imrotate(test_img, -90);
        fprintf('Orientation: Portrait -> Landscape (rotated -90°)\n');
    else
        fprintf('Orientation: Already landscape\n');
    end

    % --- STEP 3: Standardize Scale ---
    ref_height = size(ref_img, 1);
    test_img = imresize(test_img, [ref_height, NaN]);
    fprintf('Scale: Resized to reference height (%d pixels)\n', ref_height);

    % --- STEP 4: Convert to Grayscale for Feature Detection ---
    ref_gray = rgb2gray(ref_img);
    test_gray = rgb2gray(test_img);

    % --- STEP 5: Detect ORB Features (at least 5000) ---
    fprintf('Detecting ORB features...\n');
    ref_points = detectORBFeatures(ref_gray, 'NumLevels', 8, 'ScaleFactor', 1.2);
    test_points = detectORBFeatures(test_gray, 'NumLevels', 8, 'ScaleFactor', 1.2);

    % If not enough features, increase sensitivity
    if ref_points.Count < 5000
        ref_points = detectORBFeatures(ref_gray, 'NumLevels', 10, 'ScaleFactor', 1.1);
    end
    if test_points.Count < 5000
        test_points = detectORBFeatures(test_gray, 'NumLevels', 10, 'ScaleFactor', 1.1);
    end

    fprintf('  Reference: %d features\n', ref_points.Count);
    fprintf('  Test:      %d features\n', test_points.Count);

    % --- STEP 6: Extract Features ---
    [ref_features, ref_valid_points] = extractFeatures(ref_gray, ref_points);
    [test_features, test_valid_points] = extractFeatures(test_gray, test_points);

    % --- STEP 7: Match Features ---
    fprintf('Matching features...\n');
    index_pairs = matchFeatures(test_features, ref_features, ...
                                 'MaxRatio', 0.7, 'Unique', true);

    matched_test = test_valid_points(index_pairs(:, 1));
    matched_ref = ref_valid_points(index_pairs(:, 2));
    fprintf('  Matched: %d feature pairs\n', size(index_pairs, 1));

    % --- STEP 8: Estimate Homography (estimateGeometricTransform2D) ---
    fprintf('Estimating homography...\n');
    if size(index_pairs, 1) < 4
        error('Not enough matched points for homography (need at least 4)');
    end

    [tform, inlier_idx] = estimateGeometricTransform2D(...
        matched_test, matched_ref, 'projective', ...
        'Confidence', 99.9, 'MaxNumTrials', 2000);

    fprintf('  Inliers: %d / %d\n', sum(inlier_idx), length(inlier_idx));

    % --- STEP 9: Warp Image (imwarp) ---
    fprintf('Warping image to align with reference...\n');
    output_view = imref2d(size(ref_img));
    warped_img = imwarp(test_img, tform, 'OutputView', output_view);

    fprintf('=== PREPROCESSING COMPLETE ===\n\n');
end
