function clutter_score = analyzeTexturePC_Watermark(image_color)
%analyzeTexturePC_Watermark Calculates the "clutter score" of the watermark area.

    % Define the ROI for the clean watermark area.
    roi_rect = [1100, 150, 200, 400]; % [xmin, ymin, width, height]
    NOISE_THRESHOLD = 0.1; % Our validated threshold for what counts as a "feature"

    image_gray = convertToGrayscale(image_color);
    
    % Extract the specified ROI
    roi = extractROI(image_gray, roi_rect);
    
    % Calculate phase congruency for the ROI
    [pc, ~] = phasecong3(roi);
    
    % Calculate the percentage of pixels with a value above our noise threshold.
    clutter_pixels = sum(pc(:) > NOISE_THRESHOLD);
    total_pixels = numel(pc);
    clutter_score = (clutter_pixels / total_pixels); % Score is a ratio from 0 to 1
end