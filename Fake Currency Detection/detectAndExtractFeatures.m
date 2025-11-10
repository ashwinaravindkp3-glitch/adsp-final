function [points, features] = detectAndExtractFeatures(gray_image)
%detectAndExtractFeatures Detects ORB keypoints and extracts their descriptors.
%
%   Inputs:
%       gray_image - A grayscale image.
%
%   Outputs:
%       points     - An object containing the locations of detected feature points.
%       features   - An object containing the descriptors for each point.

    % Detect ORB feature points
    points = detectORBFeatures(gray_image);

    % Extract feature descriptors for the detected points
    [features, valid_points] = extractFeatures(gray_image, points);
    
    % Update the points list to only include valid points
    points = valid_points;

end