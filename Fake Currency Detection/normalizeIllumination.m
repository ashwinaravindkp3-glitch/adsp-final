function normalized_image = normalizeIllumination(image)
%normalizeIllumination Applies homomorphic filtering to correct uneven illumination.
%
%   Inputs:
%       image - A color or grayscale image.
%
%   Outputs:
%       normalized_image - The image with illumination effects reduced.

    % Convert to grayscale if it's a color image
    if size(image, 3) == 3
        image_gray = im2gray(image);
    else
        image_gray = image;
    end

    I = im2double(image_gray);
    I_log = log(1 + I); % Log transform
    I_fft = fft2(I_log); % Go to frequency domain

    % Create a Butterworth High-Pass Filter to suppress illumination
    [M, N] = size(I);
    D0 = 15;  % Cutoff frequency
    n = 2;    % Filter order
    [X, Y] = meshgrid(1:N, 1:M);
    D = sqrt((X - N/2).^2 + (Y - M/2).^2);
    H = 1 ./ (1 + (D0./D).^(2*n)); 
    
    % Apply the filter
    I_fft_filtered = fftshift(I_fft) .* H;

    % Return to spatial domain and reverse log
    I_filtered = real(ifft2(ifftshift(I_fft_filtered)));
    I_exp = exp(I_filtered) - 1;

    % Normalize and convert back to uint8
    normalized_image = im2uint8(mat2gray(I_exp));
end