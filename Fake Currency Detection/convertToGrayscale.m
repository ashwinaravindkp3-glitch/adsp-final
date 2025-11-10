function gray_image = convertToGrayscale(color_image)
%convertToGrayscale Converts an RGB color image to a grayscale image.
%
%   gray_image = convertToGrayscale(color_image)
%
%   Inputs:
%       color_image - An M-by-N-by-3 uint8 or double matrix representing a color image.
%
%   Outputs:
%       gray_image  - An M-by-N matrix representing the grayscale image.

    % Use MATLAB's built-in im2gray function, which uses a standard
    % luminance-preserving formula (per ITU-R BT.601).
    gray_image = im2gray(color_image);

end