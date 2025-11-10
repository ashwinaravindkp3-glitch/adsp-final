function denoised_image = applyNoiseFilter(image_path)
%applyNoiseFilter Loads an image and applies a bilateral filter for noise reduction.
%
%   denoised_image = applyNoiseFilter(image_path)
%
%   Inputs:
%       image_path - A string containing the file path to the image.
%
%   Outputs:
%       denoised_image - The resulting color image (uint8), with noise reduced
%                        while preserving edges.
%
%   This function serves as the first step in the image preprocessing
%   pipeline, preparing the image for further analysis by cleaning sensor noise.

    % --- 1. Load the Image ---
    % Use a try-catch block for robust error handling in case the file is not found.
    try
        original_image = imread(image_path);
    catch ME
        error('Failed to read image from path: %s. Error: %s', image_path, ME.message);
    end

    % --- 2. Apply the Bilateral Filter ---
    % The bilateral filter is an edge-preserving smoothing filter. It takes
    % two main parameters:
    %   - DegreeOfSmoothing: Controls the intensity smoothing. A higher value
    %     means more dissimilar pixel values will be averaged together.
    %   - SpatialSigma: Controls the influence of neighboring pixels based on
    %     distance. It's roughly the standard deviation of the Gaussian filter.
    %
    % We will start with moderate values and can tune them later.
    
    % The imbilatfilt function can be sensitive to the input image's data type
    % and range. It works well with single or double types between [0, 1].
    if ~isfloat(original_image)
        original_image = im2double(original_image);
    end
    
    denoised_image_double = imbilatfilt(original_image, 'DegreeOfSmoothing', 0.1, 'SpatialSigma', 2);
    
    % Convert the image back to the standard uint8 format for display and
    % further processing.
    denoised_image = im2uint8(denoised_image_double);
    
end