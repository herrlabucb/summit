%% Properties of the image

% dimensions of the image in pixels
im_width = 2200;
im_height = 2200;

% background level in the image
im_background = 10000;

% standard deviation of the gaussian noise applied uniformly
% to the image.
im_noise = 1000;

% pixel size in length units (µm/px)
pix_conversion = 5;

% bit depth of the image
n_bits = 16;

%% Properties of the separation lane array

% dimensions of the array
n_rows = 10;
n_cols = 40;

% well size in pixels
well_radius = 6;

% position of the upper left corner of the upper left separation array
upper_left_corner_x = 100;
upper_left_corner_y = 100;


% length and width of a separation lane in pixels
lane_width = 50;
lane_length = 200;

% Parameters defining the peaks
% amplitude of the peak
amplitude_mean = 30000;
amplitude_stdev = 500;

% center and standard deviation of the peak in the axis in the direction
% of the separation
mu_x_mean = 125;
mu_x_stdev = 0.5;
sigma_x_mean = 10;
sigma_x_stdev= 0.3;

% center and standard deviation of the peak in the axis normal to
% the separation
mu_y_mean = 25;
mu_y_stdev = 0.5;

sigma_y_mean = 5;
sigma_y_stdev = 0;

% skew factor for the peaks
alpha_mean = -0.95;
alpha_stdev = 0.001;

%% Make the base image
% here we make the image with the background and noise specified above

% first make a blank image
base_image_empty = zeros(im_height, im_width, 'uint16');

max_intensity_value = 2^16 - 1;

% add some noise and background. note that we rescale the noise parameters
% to the range [0, 1]. See the MATLAB imnoise docs for details.
im_noise_scaled = im_noise / max_intensity_value;
noise_variance = im_noise_scaled^2;
im_background_scaled = im_background / max_intensity_value;
base_image = imnoise(base_image_empty, 'gaussian', im_background_scaled, noise_variance);

imwrite(base_image, 'base.tif');

%% make the array of peaks

lane_array = zeros(im_height, im_width, 'uint16');

% get the coordinates of all pixels in the image
[im_cols, im_rows] = meshgrid(1:im_width, 1:im_height);

% Get the indices of the last row and column
upper_right_corner_x = upper_left_corner_x + ((n_cols - 1) * lane_width);
lower_left_corner_y = upper_left_corner_y + ((n_rows - 1) * lane_length);

% create the data object and preallocate the properties
data_struct = struct;
n_lanes = n_cols * n_rows;
rois = zeros(lane_length, lane_width, n_lanes);

peak_params = zeros(1, 4, n_lanes);

lane_index = 1;
for lane_x_i = upper_left_corner_x:lane_width:upper_right_corner_x
    for lane_y_i = upper_left_corner_y:lane_length:lower_left_corner_y

        lane_x_f = lane_x_i + lane_width - 1;
        lane_y_f = lane_y_i + lane_length - 1;
        
        % amplitude of the peak
        amplitude = normrnd(amplitude_mean, amplitude_stdev);

        % center and standard deviation of the peak in the axis in the
        % direction of the separation
        mu_x = normrnd(mu_x_mean, mu_x_stdev);
        sigma_x = normrnd(sigma_x_mean, sigma_x_stdev);

        % center and standard deviation of the peak in the axis normal to
        % the separation
        mu_y = normrnd(mu_y_mean, mu_y_stdev);
        sigma_y = normrnd(sigma_y_mean, sigma_y_stdev);

        % skew factor for the peaks
        alpha = normrnd(alpha_mean, alpha_stdev);


        peak_image = makeSeparationLane(lane_width, lane_length,...
            amplitude, mu_x, sigma_x, mu_y, sigma_y, alpha);
        lane_array(lane_y_i:lane_y_f, lane_x_i:lane_x_f) = transpose(peak_image);
        
        % save the ROI and peak parameters
        rois(:, :, lane_index) = transpose(peak_image);
        peak_params(1, :, lane_index) = [amplitude, mu_x, sigma_x, alpha];
        
        % make the well in the base image by setting the pixel values
        % in the well location to zero in the base image
        well_center_y = lane_y_i;
        well_center_x = (lane_x_i + lane_x_f) / 2;
        circle_mask = makeCircleMask(im_rows, im_cols, well_center_y,...
            well_center_x, well_radius);
        base_image(circle_mask) = 0;
        
        
        lane_index = lane_index + 1;
    end
    
end

% add the lane data to the data_struct
data_struct.rois = rois;
data_struct.fit_coefficients = peak_params;

%% combine the base with the spots

simulated_image = base_image + lane_array;

%% extract the intensity profiles

int_profs = zeros(lane_length, 2, n_lanes);

lane_index = 1;
for lane_x_i = upper_left_corner_x:lane_width:upper_right_corner_x
    for lane_y_i = upper_left_corner_y:lane_length:lower_left_corner_y

        lane_x_f = lane_x_i + lane_width - 1;
        lane_y_f = lane_y_i + lane_length - 1;
        
        roi = simulated_image(lane_y_i:lane_y_f, lane_x_i:lane_x_f);
        
        % get the coordinates in real units
        dist = (0:pix_conversion:pix_conversion*(lane_length-1));
        
        int_prof = sum(roi,2);
        avg_int_prof = int_prof / (lane_width);
        
        % background subtract based on the defined image properties
        bsub_int_prof = avg_int_prof - im_background;
        
        % Create a matrix with one column containing the x-coordinates and a
        % second column containing the background subtracted intensity profile
        lane_profile=[dist',bsub_int_prof];

        % Add the intensity profile to the matrix of intensity profiles
        int_profs(:,:,lane_index) = lane_profile;
        
        lane_index = lane_index + 1;
    end
    
end

% save the intensity profiles
data_struct.int_prof = int_profs;

%% Rotate and write the final image
imwrite(imrotate(simulated_image, 90), 'skew_sim_data.tif')


save('sim_data_struct.mat', 'data_struct');
