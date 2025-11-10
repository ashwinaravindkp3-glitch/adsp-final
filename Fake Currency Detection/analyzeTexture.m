function total_energy = analyzeTexture(image_color)
%analyzeTexture Calculates the total wavelet texture energy for an image.
%
%   Inputs:
%       image_color - The preprocessed, aligned color image.
%
%   Outputs:
%       total_energy - A single score representing the textural complexity.

    image_gray = convertToGrayscale(image_color);
    
    % Perform single-level 2D wavelet decomposition
    [~, cH, cV, cD] = dwt2(image_gray, 'haar');
    
    % Calculate the energy for each detail coefficient matrix
    energy_H = mean(cH(:).^2); % Horizontal Energy
    energy_V = mean(cV(:).^2); % Vertical Energy
    energy_D = mean(cD(:).^2); % Diagonal Energy
    
    % The final score is the sum of the energies from all three detail channels.
    total_energy = energy_H + energy_V + energy_D;
end