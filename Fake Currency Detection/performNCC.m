function correlation_map = performNCC(image_gray, template_gray)
%performNCC Performs normalized cross-correlation to find a template in an image.
%
%   Inputs:
%       image_gray    - The larger grayscale image to be searched.
%       template_gray - The smaller grayscale template image to search for.
%
%   Outputs:
%       correlation_map - A 2D matrix where each pixel's value (from -1 to 1)
%                         represents the correlation score at that location. The
%                         brightest pixel indicates the best match.

    % normxcorr2 is MATLAB's built-in function for normalized cross-correlation.
    % It is robust to changes in brightness and contrast.
    correlation_map = normxcorr2(template_gray, image_gray);

end