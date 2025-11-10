function [tform, status] = estimateHomography(matched_points_test, matched_points_ref)
%estimateHomography Estimates the projective transformation from matched points.
%
%   Inputs:
%       matched_points_test - Matched point coordinates from the test image.
%       matched_points_ref  - Matched point coordinates from the reference image.
%
%   Outputs:
%       tform               - A projective2d object containing the transformation.
%       status              - A struct with a success flag and inlier count.

    % We need at least 4 matched points to compute a homography.
    if size(matched_points_test, 1) < 4
        warning('Not enough matched points to compute homography. Need at least 4.');
        tform = [];
        status.success = false;
        status.inlier_count = 0;
        return;
    end

    % Use M-SAC (a variant of RANSAC) to robustly estimate the transform.
    % This algorithm is excellent at ignoring outlier (incorrect) matches.
    [tform, inlier_idx] = estimateGeometricTransform2D(...
        matched_points_test, matched_points_ref, 'projective', ...
        'Confidence', 99.9, 'MaxNumTrials', 2000);
        
    status.success = true;
    status.inlier_count = sum(inlier_idx);

end