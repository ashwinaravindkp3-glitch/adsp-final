function [score, spectrum_vis] = analyzeFrequencySpectrum(roi_gray)
%analyzeFrequencySpectrum Computes 2D FFT and scores the presence of a horizontal line signature.
%
%   Inputs:
%       roi_gray - A grayscale image of the Region of Interest.
%
%   Outputs:
%       score        - A score indicating the strength of the horizontal signature.
%       spectrum_vis - The log-magnitude spectrum for visualization.

    % --- 1. Compute the 2D FFT Spectrum ---
    F = fft2(im2double(roi_gray));
    F_shifted = fftshift(F);
    spectrum_mag = abs(F_shifted);
    spectrum_vis = log(1 + spectrum_mag); % For visualization

    % --- 2. Calculate the Score ---
    % The score is the ratio of energy in a narrow horizontal band at the
    % center versus the total energy in the spectrum.
    [rows, cols] = size(spectrum_mag);
    center_row = round(rows / 2);
    
    % Define a narrow band (e.g., 3 pixels high) around the horizontal centerline
    band_height = 1; 
    y_start = center_row - band_height;
    y_end = center_row + band_height;
    
    % Sum the energy within the band
    horizontal_band_energy = sum(sum(spectrum_mag(y_start:y_end, :)));
    
    % Sum the total energy in the entire spectrum
    total_energy = sum(spectrum_mag(:));
    
    % The score is the ratio. A higher score means more energy is concentrated
    % in that horizontal line, indicating a strong vertical feature.
    if total_energy > 0
        score = horizontal_band_energy / total_energy;
    else
        score = 0;
    end
end