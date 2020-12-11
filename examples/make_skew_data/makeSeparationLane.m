function separation_lane = makeSeparationLane(lane_width, lane_length, amplitude, mu_x, sigma_x, mu_y, sigma_y, alpha)
%% Header
%
%   This function creates an image of a single lane with a analyte peak.
%   The background is zero and there is no noise.
%
%   Inputs: lane_width: width of the lane in pixels.
%           lane_length: length of the lane in pixels.
%           amplitude: the amplitude of the peak in AFU
%           mu_x: the peak center along the separation axis
%           sigma_x: the standard deviation of the peak along
%                    the separation axis.
%           mu_y: the peak center in the axis perpendicular
% .               to the separation axis
%           sigma_y: the standard deviation of the peak in the
% .                  axis perpendicular to the separation axis
%           alpha: the skew. negative skew has a tail towards the beginning
%                  of the separation axis (i.e., towards the well).
%
%
%   Outputs: 
%           separation_lane: the image of the separation lane with a peak
%                           embedded.

%% define the separation lane image
x = 1:lane_length;
y = 1:lane_width;
[X, Y] = meshgrid(x, y);

%% create the image with the gaussian
separation_lane = amplitude*exp(-((((X-mu_x).^2)/(2*sigma_x .^2)) + (((Y-mu_y).^2)/(2*sigma_y.^2)))) .* normcdf(alpha * (X-mu_x));


end