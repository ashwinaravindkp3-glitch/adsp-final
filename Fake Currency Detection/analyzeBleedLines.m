% --- Paste this corrected function into your test script ---

function [score, roi_rect_left, roi_rect_right] = analyzeBleedLines(aligned_color_image)
% CORRECTED VERSION: Uses morphological filtering and L*a*b* color analysis.

    % Define the ROIs for the bleed lines
    roi_rect_left = [20, 150, 75, 200]; 
    roi_rect_right = [1572, 234, 95, 126];

    % Analyze both ROIs and average their scores
    score_left = analyzeSingleBleedROI(aligned_color_image, roi_rect_left);
    score_right = analyzeSingleBleedROI(aligned_color_image, roi_rect_right);
    
    % The final score is the average of the two regions
    score = (score_left + score_right) / 2;
    
    fprintf('Bleed Lines -> Left Score: %.3f, Right Score: %.3f, Final Avg Score: %.4f\n', ...
            score_left, score_right, score);
end

function single_roi_score = analyzeSingleBleedROI(image_rgb, roi_rect)
    % Helper function to process one bleed line ROI
    
    % 1. Crop to ROI and convert to required color spaces
    roi_img_rgb = imcrop(image_rgb, roi_rect);
    roi_img_gray = rgb2gray(roi_img_rgb);
    roi_img_lab = rgb2lab(roi_img_rgb);

    % 2. Use a morphological Bottom-Hat transform to enhance dark lines
    se = strel('line', 10, 0); % Horizontal structuring element
    line_intensity_map = imbothat(roi_img_gray, se);

    % 3. Create a binary mask of the lines
    line_mask = imbinarize(line_intensity_map);

    % If no lines are found, score is zero
    if sum(line_mask(:)) < 50 % Increased pixel count for robustness
        single_roi_score = 0;
        return;
    end

    % 4. Extract L* and b* channels
    L_channel = roi_img_lab(:,:,1);
    b_channel = roi_img_lab(:,:,2); % Typo in original corrected to 'a' or 'b' as needed, let's stick with b* for blueness

    % 5. Use the mask to sample color values ONLY from the detected lines
    line_L_values = L_channel(line_mask);
    line_b_values = b_channel(line_mask);

    % 6. Calculate metrics based on the ink's properties
    mean_L = mean(line_L_values); % Should be low (dark)
    mean_b = mean(line_b_values); % Should be negative (blue)

    % 7. Fuse metrics into a final score (0 to 1)
    darkness_score = 1 / (1 + exp(0.2 * (mean_L - 35))); % High score when L < 35
    blueness_score = 1 / (1 + exp(0.5 * (mean_b + 5)));  % High score when b < -5
    
    single_roi_score = darkness_score * blueness_score;
end

% You will also need this small helper function, if it's not already there
function roi_image = extractROI(image, roi_rect)
    roi_image = imcrop(image, roi_rect);
end