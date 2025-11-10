function [matched_points_test, matched_points_ref, status] = matchFeaturesBetweenImages(points_test, features_test, points_ref, features_ref)
%matchFeaturesBetweenImages Finds corresponding feature points between two images.
%
%   Inputs:
%       points_test      - Feature points from the test image.
%       features_test    - Feature descriptors from the test image.
%       points_ref       - Feature points from the reference image.
%       features_ref     - Feature descriptors from the reference image.
%
%   Outputs:
%       matched_points_test - The coordinates of the matched points in the test image.
%       matched_points_ref  - The coordinates of the matched points in the reference image.
%       status              - A struct with a success flag and match count.

    % --- 1. Match Features using their Descriptors ---
    % 'MaxRatio' is a key parameter. It performs a ratio test to select
    % only the most confident matches, rejecting ambiguous ones. A value
    % between 0.6 and 0.7 is standard.
    index_pairs = matchFeatures(features_test, features_ref, 'MaxRatio', 0.7, 'Unique', true);
    
    % --- 2. Extract the Location of the Matched Points ---
    matched_points_test = points_test(index_pairs(:, 1), :);
    matched_points_ref = points_ref(index_pairs(:, 2), :);
    
    % --- 3. Report Status ---
    status.matches = size(matched_points_test, 1);
    if status.matches > 0
        status.success = true;
    else
        status.success = false;
    end

end