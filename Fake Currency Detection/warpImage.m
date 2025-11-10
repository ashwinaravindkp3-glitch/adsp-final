function aligned_image = warpImage(image_to_warp, ref_image, tform)
%warpImage Applies a projective transformation to an image.
%
%   Inputs:
%       image_to_warp - The image to be transformed.
%       ref_image     - The reference image, used to define the output size.
%       tform         - The projective2d transformation object from estimateHomography.
%
%   Outputs:
%       aligned_image - The geometrically corrected image.

    % Define the output view to match the reference image dimensions
    output_view = imref2d(size(ref_image));
    
    % Warp the input image using the provided transformation
    aligned_image = imwarp(image_to_warp, tform, 'OutputView', output_view);

end