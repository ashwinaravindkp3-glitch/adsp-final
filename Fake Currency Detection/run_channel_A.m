function final_score_A = run_channel_A(processed_img)
    % This function runs the Channel A template matching logic.

    final_processed_gray = normalizeIllumination(processed_img);
    % Use histogram equalization for better contrast
    final_processed_histeq = histeq(final_processed_gray);

    template_files = {'template_ashoka.jpg','template_devnagari.jpg','template_rbi_seal.jpg','template_small100.jpg'};
    detection_threshold = 0.6; % A reasonably strict threshold
    
    num_found = 0;
    for i = 1:length(template_files)
        try
            template_gray = convertToGrayscale(imread(template_files{i}));
            template_histeq = histeq(template_gray);
            
            correlation_map = performNCC(final_processed_histeq, template_histeq);
            [score, ~] = analyzeNCCResult(correlation_map, size(template_histeq));
            
            if score >= detection_threshold
                num_found = num_found + 1;
            end
        catch
            % If a template file is missing, just skip it.
            warning('Template file %s not found. Skipping.', template_files{i});
        end
    end
    
    % The score is the ratio of templates successfully found.
    final_score_A = num_found / length(template_files);
    fprintf('  Channel A Score -> Templates Found: %d/%d (%.2f)\n', num_found, length(template_files), final_score_A);
end