function score = analyzeSecurityThreadColor(aligned_color_image)
%analyzeSecurityThreadColor Analyzes the security thread based on color properties.
%
%   Inputs:
%       aligned_color_image - The fully preprocessed, aligned color image.
%
%   Outputs:
%       score               - A final score (0 to 1) indicating the confidence
%                             in the authenticity of the security thread.

    % --- 1. Extract ROI ---
    % Define and extract the fixed ROI for the security thread
    roi_rect = [900, 1, 45, size(aligned_color_image, 1)-1]; 
    thread_roi_color = extractROI(aligned_color_image, roi_rect);

    % --- 2. Convert to L*a*b* and HSV ---
    thread_lab = rgb2lab(thread_roi_color);
    thread_hsv = rgb2hsv(thread_roi_color);

    % --- 3. Analyze Color Properties ---
    a_channel = thread_lab(:,:,2) % a* channel (green-red)
    s_channel = thread_hsv(:,:,2) % Saturation channel
    
    % Calculate the average values within the ROI
    avg_a_star = mean(a_channel(:))
    avg_saturation = mean(s_channel(:))

    % --- 4. Calculate Scores ---
    % Score for "Greenness". In L*a*b*, green is negative. A strong green
    % will be around -20 or lower. We can map this to a 0-1 score.
    % A simple sigmoid-like mapping function.
    score_green = 1 / (1 + exp(0.5 * (avg_a_star + 15))) % Scaled to be sensitive around a*=-15

    % Score for "Saturation". A good thread is highly saturated (e.g., > 0.4).
    score_saturation = 1 / (1 + exp(-15 * (avg_saturation - 0.4))) % Scaled to be sensitive around S=0.4
    
    % --- 5. Final Score ---
    % The final score is the product of the individual scores.
    % The thread must be BOTH green AND saturated to get a high score.
    score = score_green * score_saturation;

end