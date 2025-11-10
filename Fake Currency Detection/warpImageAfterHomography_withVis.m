function [aligned_image, vis_data] = warpImageAfterHomography_withVis(test_filename_str, ref_filename_str)
%warpImageAfterHomography_withVis Preprocessing with visualization outputs
%
%   Returns both the aligned image AND all intermediate visualizations
%   for display in GUI
%
%   Outputs:
%       aligned_image - Final aligned color image
%       vis_data      - Struct containing all intermediate results

    vis_data = struct();

    % --- STEP 1: Load Images ---
    ref_img = imread(ref_filename_str);
    test_img = imread(test_filename_str);

    vis_data.step1_original = test_img;
    vis_data.step1_reference = ref_img;

    % --- STEP 2: Handle Orientation ---
    [height, width, ~] = size(test_img);
    if height > width
        test_img = imrotate(test_img, -90);
        vis_data.step2_rotated = test_img;
        vis_data.rotation_applied = true;
    else
        vis_data.step2_rotated = test_img;
        vis_data.rotation_applied = false;
    end

    % --- STEP 3: Standardize Scale ---
    ref_height = size(ref_img, 1);
    test_img = imresize(test_img, [ref_height, NaN]);
    vis_data.step3_resized = test_img;

    % --- STEP 4: Convert to Grayscale ---
    ref_gray = rgb2gray(ref_img);
    test_gray = rgb2gray(test_img);
    vis_data.step4_gray_test = test_gray;
    vis_data.step4_gray_ref = ref_gray;

    % --- STEP 5: Detect ORB Features ---
    ref_points = detectORBFeatures(ref_gray, 'NumLevels', 8, 'ScaleFactor', 1.2);
    test_points = detectORBFeatures(test_gray, 'NumLevels', 8, 'ScaleFactor', 1.2);

    if ref_points.Count < 5000
        ref_points = detectORBFeatures(ref_gray, 'NumLevels', 10, 'ScaleFactor', 1.1);
    end
    if test_points.Count < 5000
        test_points = detectORBFeatures(test_gray, 'NumLevels', 10, 'ScaleFactor', 1.1);
    end

    vis_data.step5_orb_test = test_points;
    vis_data.step5_orb_ref = ref_points;
    vis_data.step5_feature_count_test = test_points.Count;
    vis_data.step5_feature_count_ref = ref_points.Count;

    % --- STEP 6: Extract Features ---
    [ref_features, ref_valid_points] = extractFeatures(ref_gray, ref_points);
    [test_features, test_valid_points] = extractFeatures(test_gray, test_points);

    % --- STEP 7: Match Features ---
    index_pairs = matchFeatures(test_features, ref_features, ...
                                 'MaxRatio', 0.7, 'Unique', true);

    matched_test = test_valid_points(index_pairs(:, 1));
    matched_ref = ref_valid_points(index_pairs(:, 2));

    vis_data.step7_matched_test = matched_test;
    vis_data.step7_matched_ref = matched_ref;
    vis_data.step7_match_count = size(index_pairs, 1);

    % --- STEP 8: Estimate Homography ---
    if size(index_pairs, 1) < 4
        error('Not enough matched points for homography (need at least 4)');
    end

    [tform, inlier_idx] = estimateGeometricTransform2D(...
        matched_test, matched_ref, 'projective', ...
        'Confidence', 99.9, 'MaxNumTrials', 2000);

    vis_data.step8_tform = tform;
    vis_data.step8_inliers = sum(inlier_idx);
    vis_data.step8_inlier_idx = inlier_idx;

    % --- STEP 9: Warp Image ---
    output_view = imref2d(size(ref_img));
    aligned_image = imwarp(test_img, tform, 'OutputView', output_view);

    vis_data.step9_aligned = aligned_image;

    % Create visualization images
    % Feature matching visualization
    vis_data.vis_feature_matching = createMatchingVis(test_gray, ref_gray, ...
                                                      matched_test, matched_ref, inlier_idx);

end

function vis_img = createMatchingVis(img1, img2, pts1, pts2, inliers)
    % Create side-by-side visualization with matched features
    vis_img = cat(2, img1, img2);
    vis_img = cat(3, vis_img, vis_img, vis_img); % Convert to RGB

    % This is a placeholder - actual visualization done in GUI
end
