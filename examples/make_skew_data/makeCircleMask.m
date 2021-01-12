function circle_mask = makeCircleMask(rows, cols, center_y, center_x, radius)
%% Header
%
%   This makes a boolean mask for a circle in the specified location.
%
%   Inputs:
%           rows: the rows in the full image
%                 (this should be the output of meshgrid).
%           cols: the rows in the full image
%                 (this should be the output of meshgrid).
%           amplitude: the amplitude of the peak in AFU
%           center_y: the center of the well in the y axis (rows).
%           center_x: the center of the well in the y axis (cols).
%           radius: the radius of the well in pixels
%
%
%   Outputs: 
%           circle_mask: a boolean mask where the pixels in the circle 
%                        have the value True.
%
%% make the cirlce mask
    circle_mask = (rows - center_y).^2 ...
    + (cols - center_x).^2 <= radius.^2;
end