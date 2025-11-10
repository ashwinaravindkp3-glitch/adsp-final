function [score, vis_data] = run_channel_B_withVis(aligned_color_image)
%run_channel_B_withVis Channel B with visualization outputs

    vis_data = struct();
    vis_data.input_image = aligned_color_image;

    % --- METHOD 1: Security Thread ---
    [score_thread, vis_thread] = analyzeSecurityThread_withVis(aligned_color_image);
    vis_data.method1_thread = vis_thread;
    vis_data.score_thread = score_thread;

    % --- METHOD 2: Bleed Lines ---
    [score_lines, vis_lines] = analyzeBleedLines_withVis(aligned_color_image);
    vis_data.method2_lines = vis_lines;
    vis_data.score_lines = score_lines;

    % --- FINAL SCORE ---
    score = (score_thread + score_lines) / 2;
    vis_data.final_score = score;

end

% ========================================================================
% METHOD 1: Security Thread
% ========================================================================
function [score, vis_data] = analyzeSecurityThread_withVis(image)
    vis_data = struct();

    % Extract ROI
    roi_rect = [900, 1, 45, size(image, 1)-1];
    thread_roi = imcrop(image, roi_rect);

    vis_data.roi_location = roi_rect;
    vis_data.roi_image = thread_roi;

    % Convert to L*a*b*
    thread_lab = rgb2lab(thread_roi);
    a_channel = thread_lab(:,:,2);
    L_channel = thread_lab(:,:,1);

    vis_data.lab_L = L_channel;
    vis_data.lab_a = a_channel;

    % Analyze greenness
    avg_a_star = mean(a_channel(:));
    score_green = 1 / (1 + exp(0.5 * (avg_a_star + 15)));

    vis_data.avg_a_star = avg_a_star;
    vis_data.score_green = score_green;

    % Saturation
    thread_hsv = rgb2hsv(thread_roi);
    s_channel = thread_hsv(:,:,2);
    avg_saturation = mean(s_channel(:));
    score_saturation = 1 / (1 + exp(-15 * (avg_saturation - 0.3)));

    vis_data.hsv_saturation = s_channel;
    vis_data.avg_saturation = avg_saturation;
    vis_data.score_saturation = score_saturation;

    % Final score
    score = score_green * score_saturation;
    vis_data.final_score = score;
end

% ========================================================================
% METHOD 2: Bleed Lines
% ========================================================================
function [score, vis_data] = analyzeBleedLines_withVis(image)
    vis_data = struct();

    % Convert to L*a*b*
    image_lab = rgb2lab(image);
    L_channel = image_lab(:,:,1);

    vis_data.L_channel = L_channel;

    % --- LEFT ROI ---
    roi_left = [20, 150, 75, 200];
    left_roi = imcrop(L_channel, roi_left);

    vis_data.roi_left_location = roi_left;
    vis_data.roi_left_image = left_roi;

    [left_count, vis_left] = countBleedLines_withVis(left_roi);
    vis_data.left_count = left_count;
    vis_data.left_analysis = vis_left;

    % --- RIGHT ROI ---
    roi_right = [1572, 234, 95, 126];
    right_roi = imcrop(L_channel, roi_right);

    vis_data.roi_right_location = roi_right;
    vis_data.roi_right_image = right_roi;

    [right_count, vis_right] = countBleedLines_withVis(right_roi);
    vis_data.right_count = right_count;
    vis_data.right_analysis = vis_right;

    % --- SCORE ---
    if left_count == 4 && right_count == 4
        score = 1.0;
    else
        score = 0.0;
    end

    vis_data.final_score = score;
end

% ========================================================================
% Helper: Count Lines
% ========================================================================
function [line_count, vis_data] = countBleedLines_withVis(roi)
    vis_data = struct();

    % Horizontal projection
    projection = mean(roi, 2);
    vis_data.projection = projection;

    % Invert
    projection_inverted = max(projection) - projection;
    vis_data.projection_inverted = projection_inverted;

    % Find peaks
    [pks, locs] = findpeaks(projection_inverted, ...
                           'MinPeakHeight', mean(projection_inverted), ...
                           'MinPeakDistance', 10);

    vis_data.peaks = pks;
    vis_data.peak_locations = locs;

    line_count = length(locs);
    vis_data.line_count = line_count;
end
