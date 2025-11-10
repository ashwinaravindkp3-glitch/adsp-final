function [points, features] = detectAndExtractFeatures(gray_image)
%detectAndExtractFeatures Detects ORB keypoints and extracts their descriptors.
%
%   Inputs:
%       gray_image - A grayscale image.
%
%   Outputs:
%       points     - An object containing the locations of detected feature points.
%       features   - An object containing the descriptors for each point.

    % Detect ORB feature points with at least 5000 features as required
    points = detectORBFeatures(gray_image, 'NumLevels', 8, 'ScaleFactor', 1.2);

    % If we don't have enough features, try with higher sensitivity
    if points.Count < 5000
        points = detectORBFeatures(gray_image, 'NumLevels', 10, 'ScaleFactor', 1.1);
    end

    % Extract feature descriptors for the detected points
    [features, valid_points] = extractFeatures(gray_image, points);

    % Update the points list to only include valid points
    points = valid_points;

end