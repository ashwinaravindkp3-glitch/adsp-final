function [score, location] = analyzeNCCResult(correlation_map, template_size)
%analyzeNCCResult Finds the peak correlation score and its location.
%
%   Inputs:
%       correlation_map - The 2D map from performNCC.
%       template_size   - The size of the template [height, width].
%
%   Outputs:
%       score           - The maximum value in the correlation map.
%       location        - The [x, y] coordinates of the top-left corner of the match.

    % Find the peak correlation value and its linear index
    [score, max_idx] = max(correlation_map(:));
    
    % Convert the linear index to row/column subscripts
    [ypeak, xpeak] = ind2sub(size(correlation_map), max_idx);
    % Correct for the padding added by normxcorr2 to get the top-left corner
    location = [xpeak - template_size(2) + 1, ypeak - template_size(1) + 1];

end