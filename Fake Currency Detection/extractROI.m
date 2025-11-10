function roi_image = extractROI(image, rect)
%extractROI Extracts a rectangular Region of Interest (ROI) from an image.
%
%   Inputs:
%       image - The source image from which to crop.
%       rect  - A 1x4 vector defining the crop rectangle: [xmin, ymin, width, height].
%
%   Outputs:
%       roi_image - The cropped section of the image.

    roi_image = imcrop(image, rect);

end