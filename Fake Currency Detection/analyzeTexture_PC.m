function texture_score = analyzeTexture_PC(image_color)
%analyzeTexture_PC Calculates a texture score based on Phase Congruency.

    % Define the ROI for the clean watermark area.
    roi_rect = [1, 1, 100, 100]; % <<< Use your validated coordinates here

    image_gray = convertToGrayscale(image_color);
    
    % Extract the specified ROI
    roi = extractROI(image_gray, roi_rect);
    
    % Calculate phase congruency for the ROI
    [pc, ~] = phasecong3(roi);
    
    % The texture score is the standard deviation of the phase congruency map.
    % A higher value indicates a more complex texture (genuine).
    texture_score = std(pc(:));
end