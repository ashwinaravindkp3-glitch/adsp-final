function score = run_channel_B(aligned_color_image)
%run_channel_B Channel B: Ink & Fine Pattern Integrity (Color/Structure)
%
%   Analyzes color and structural features of the currency note.
%
%   Method 1: Security Thread Color Analysis (L*a*b* color space)
%   Method 2: Bleed Lines Detection (L* channel projection + findpeaks)
%
%   Inputs:
%       aligned_color_image - Preprocessed, aligned color image
%
%   Outputs:
%       score - Average score from both methods (0.0 to 1.0)

    fprintf('\n--- Channel B: Color & Structure ---\n');

    % --- METHOD 1: Security Thread Color Analysis ---
    score_thread = analyzeSecurityThread(aligned_color_image);

    % --- METHOD 2: Bleed Lines Detection ---
    score_lines = analyzeBleedLines(aligned_color_image);

    % --- FINAL SCORE: Average of both methods ---
    score = (score_thread + score_lines) / 2;
    fprintf('Channel B Final Score: %.3f\n', score);
end


% ============================================================================
% METHOD 1: Security Thread Color Analysis
% ============================================================================
function score = analyzeSecurityThread(image)
%analyzeSecurityThread Analyzes security thread using L*a*b* color space
%
%   The security thread should be green and saturated.
%   In L*a*b* space, green corresponds to negative a* values.

    fprintf('  Method 1: Security Thread\n');

    % --- Extract ROI for Security Thread ---
    % [x, y, width, height]
    roi_rect = [900, 1, 45, size(image, 1)-1];
    thread_roi = imcrop(image, roi_rect);

    % --- Convert to L*a*b* color space ---
    thread_lab = rgb2lab(thread_roi);
    a_channel = thread_lab(:,:,2);  % a* channel (green-red axis)

    % --- Analyze Greenness ---
    avg_a_star = mean(a_channel(:));

    % Green is negative in a* channel
    % Genuine thread should have a* around -15 to -25
    % Map to 0-1 score using sigmoid
    score_green = 1 / (1 + exp(0.5 * (avg_a_star + 15)));

    % --- Color Saturation Check (optional enhancement) ---
    thread_hsv = rgb2hsv(thread_roi);
    s_channel = thread_hsv(:,:,2);
    avg_saturation = mean(s_channel(:));

    % High saturation expected (> 0.3)
    score_saturation = 1 / (1 + exp(-15 * (avg_saturation - 0.3)));

    % --- Combine Scores ---
    score = score_green * score_saturation;

    fprintf('    a* = %.2f, Saturation = %.2f → Score: %.3f\n', ...
            avg_a_star, avg_saturation, score);
end


% ============================================================================
% METHOD 2: Bleed Lines Detection
% ============================================================================
function score = analyzeBleedLines(image)
%analyzeBleedLines Detects bleed lines using L* channel projection
%
%   The bleed lines should be exactly 4 on each side (left and right).
%   Uses L* (Lightness) channel for better line detection.

    fprintf('  Method 2: Bleed Lines\n');

    % --- Convert to L*a*b* for L* channel ---
    image_lab = rgb2lab(image);
    L_channel = image_lab(:,:,1);

    % --- ROI for LEFT bleed lines ---
    roi_left = [20, 150, 75, 200];  % [x, y, width, height]
    left_roi = imcrop(L_channel, roi_left);

    % --- ROI for RIGHT bleed lines ---
    roi_right = [1572, 234, 95, 126];
    right_roi = imcrop(L_channel, roi_right);

    % --- Analyze Left Lines ---
    left_count = countBleedLines(left_roi);
    fprintf('    Left:  %d lines detected\n', left_count);

    % --- Analyze Right Lines ---
    right_count = countBleedLines(right_roi);
    fprintf('    Right: %d lines detected\n', right_count);

    % --- Score Calculation ---
    % Only score 1.0 if EXACTLY 4 lines on BOTH sides
    if left_count == 4 && right_count == 4
        score = 1.0;
    else
        score = 0.0;
    end

    fprintf('    Bleed Lines Score: %.1f\n', score);
end


% ============================================================================
% HELPER: Count Bleed Lines
% ============================================================================
function line_count = countBleedLines(roi)
%countBleedLines Counts lines in ROI using 1D projection and findpeaks
%
%   1. Create horizontal projection (sum across columns)
%   2. Invert signal (peaks become valleys)
%   3. Use findpeaks to count lines

    % --- Create 1D Horizontal Projection ---
    projection = mean(roi, 2);  % Average across width

    % --- Invert signal (lines are dark, so make them peaks) ---
    projection_inverted = max(projection) - projection;

    % --- Use findpeaks to detect lines ---
    [~, locs] = findpeaks(projection_inverted, ...
                         'MinPeakHeight', mean(projection_inverted), ...
                         'MinPeakDistance', 10);

    line_count = length(locs);
end
