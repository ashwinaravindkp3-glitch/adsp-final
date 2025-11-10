function scores_B = run_channel_B(aligned_color_image)
%run_channel_B Executes all detectors for Channel B and returns separate scores.
%
%   Inputs:
%       aligned_color_image - The fully preprocessed, aligned color image.
%
%   Outputs:
%       scores_B            - A struct containing the separate scores for each feature.

    % --- 1. Run Detectors ---
    % These functions must be saved as separate .m files in your project directory.
    
    % Analyze the security thread's color properties
    score_thread = analyzeSecurityThreadColor(aligned_color_image);
    
    % Analyze the bleed lines' color and texture properties
    score_lines = analyzeBleedLines(aligned_color_image);

    % --- 2. Package Scores into a Struct ---
    scores_B.thread = score_thread;
    scores_B.lines = score_lines;
    
    % Display the intermediate scores for this channel during execution
    fprintf('  Channel B Scores -> Thread: %.4f, Bleed Lines: %.4f\n', scores_B.thread, scores_B.lines);
end