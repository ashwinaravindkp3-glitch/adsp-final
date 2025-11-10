function final_score_C = run_channel_C(aligned_test_img, aligned_camera_ref)
% This function runs the Channel C "Watermark Smoothness" test.

    % Get the clutter score for the test image
    clutter_test = analyzeTexturePC_Watermark(aligned_test_img);
    
    % Get the clutter score for the known-good camera reference
    clutter_ref = analyzeTexturePC_Watermark(aligned_camera_ref);
    
    % The final score is based on how close the test note's clutter is to
    % the known-good camera reference's clutter.
    % We use an exponential function to create a similarity score (closer to 1 is better).
    distance = abs(clutter_test - clutter_ref);
    final_score_C = exp(-20 * distance); % The '20' is a sensitivity factor
    
    fprintf('  Channel C Scores -> Test Clutter: %.4f, Ref Clutter: %.4f (Similarity: %.2f)\n', clutter_test, clutter_ref, final_score_C);
end