function [struct] = roiGeneration(filename,horzspacing,vertspacing,struct)
% This function rotates and aligns a raw fluorescent image of a single-cell
% Western blot array and segments the image into regions-of-interest (ROIs)
% for downstream analysis. Each region of interest encompasses single-cell Western blot protein peak(s) in an area
% defined by the horizontal and vertical spacing between microwells in the
% array.

%   Outputs:  
% Struct [structure]: A data structure containing objects:
%   struct.rois: 3D matrix with each ROI contained in a different z.
%   struct.angle: The angle of rotation to straighten the image (number, in degrees).
%   struct.coarse_rotate: The angle of rotation required to display the image with
%   separations running vertically instead of horizontally (number, in
%   degrees).
%   struct.fine_angle_rotate: The angle of rotation to straighten the array
%   of vertical separations.
%   struct.array_bounds: User selected boundaries of the array as a 3x2
%   matrix (rows contain upper left, upper right, and lower left
%   coordinates respectively; first column contains x-coordinates; second column contains y-coordinates). 
%   struct.name: The name of the protein target entered by the user
%   (string).
%   struct.wells_per_row: The number of wells per row based on the user
%   selected array bounds and horizontal well spacing.
%   struct.rows: Number of rows in the array 

%   Inputs:
% filename [string]: A string containing the name of the fluorescence image
%                   to be processed.
% horzspacing [num]: Well-to-well spacing (horizontal, in pixels)
% vertspacing [num]: Well-to-well spacing (vertical, in pixels)
% struct [structure] (optional): A structure containing "angle" and
% "array_bounds" if the same image has already been analyzed by
% roiGeneration. The same ROIs will automatically be generated.
%% versions
% 0.1 (4.1.16): Created
% 0.2 (5.15.16): Updated to apply same transform for ROI generation if user
%                inputs a struct with the fields "angle" and "rotate".
% 0.3 (5.20.16): Added "rows" and "wells per row" fields to structure.
% 0.4 (10.29.20): Revised array bound selection and array straightening
%                approach so user first clicks on wells within a row to
%                straighten the image before selecting
%                left/right/top/bottom-most wells of array.
% 0.5 (12.6.20): User can input 'struct' as an argument to apply
%                previously generated ROIs to the array (struct must 
%                contain 'coarse_angle_rotate', 'fine_angle_rotate' and 
%                'array_bounds').  
%                
%% Check input arguments
switch nargin
    % If the user only provides the image, horizontal and vertical spacing
    case 3
        transform = 0;
    case 4
        transform = 1;
        
        tf = isstruct(struct);
            if tf == 0
                 error('Input argument "struct" is not a structure.');
            
            return
            
            end
            
        % retrieve previously determined coarse angle for transformation of image
        rotate = struct.coarse_rotate;
        
        %retrieve previously determined fine angle for image straightening
        fine_angle_rotate = struct.fine_angle_rotate;
        
        % retrieve previously determined array boundaries
        array_bounds = struct.array_bounds;
        
        % extract the individual x an y coordinates of the array boundaries
        x_leftwell = array_bounds(1, 1);
        x_rightwell = array_bounds(2, 1);

        y_topwell = array_bounds(3, 2);
        y_bottomwell = array_bounds(4, 2);
        
    
    otherwise
        
        error('Invalid number of input arguments');
            
    return
        
end
%% 
% ask the user the name of their protein target
prompt = 'What is the name of your protein target?';
str = input(prompt, 's');
struct.name = str;


% Load the image file in MATLAB
img = imread(filename);

    if transform == 0
        
        % Display more contrasted image in window
        contrasted_img = histeq(img);
        imshow(contrasted_img); 

        % Display a message to the user asking them to look at the array
        title('Take a look at the array and determine if the wells are oriented left of the bands or right of the bands. Then press any key');
        pause()

        % Construct a questdlg to ask the user how the image is currently oriented
        % for coarse rotation
        choice = questdlg('Are the wells currently left of the bands or right of the bands?', ...
        'Current array orientation', ...
        'Wells are left of bands','Wells are right of bands','Wells are right of bands');
       
        % Handle response
        switch choice
            
            case 'Wells are left of bands'; 
                disp([choice 'Okay, the image will be rotated to the right!'])
                rotate = -90;
                
            case 'Wells are right of bands';
                disp([choice 'Okay, the image will be rotated to the left!'])
                rotate = 90;
        end
        
        % Store the coarse rotation angle to orient the array vertically to
        % the struct
        
        struct.coarse_rotate = rotate;
    else
         
        rotate = struct.coarse_rotate;
    end
  
  % Display the coarse-rotated image
  imgrotated = imrotate(img, rotate);
  contrasted_img_r = histeq(imgrotated);
  imshow(contrasted_img_r);
 
  
  if transform == 1
      fine_angle_rotate = struct.fine_angle_rotate;
      % Display the rotated image so the array is aligned
        b = imrotate(imgrotated, fine_angle_rotate, 'nearest','crop');
        b_contrasted = histeq(b);
        imshow(b_contrasted);
        hold on
  end
  
  %If struct was not an input argument (and there is no previous
  %angle/array boundary values to draw from), the user will now manually
  %select the array boundaries.
  
while transform == 0
  test = 1;
  straighten_test = 1;
  while test == 1
       % Prompt user to zoom in on any row. 
   while straighten_test == 1
       title('Please zoom in on a row (about 10 wells in view) and press any key.');
        % use mouse button to zoom in or out
        zoom on;   
        pause()
        zoom off;
        % preallocate straighten matrix
        straighten_mat = zeros(2, 2);
        % prompt user to click on the two wells
        title('To straighten your image, please click on the center of a well and then the center of another well about 10 wells to the right in the same row.');
        [x_click,y_click] = ginput(2);
        straighten_mat(1,:) = [x_click(1), y_click(1)];
        straighten_mat(2,:) = [x_click(2), y_click(2)];
        hold on 

        plot(x_click(1),y_click(1),'r+','MarkerSize',10);
        plot(x_click(2),y_click(2),'r+','MarkerSize',10);
         % Construct a questdlg to ask the user if they are happy with their
         % well selection
        choice = questdlg('Are you happy with your well selections?', ...
        'Well selections to straighten image', ...
        'Yes','No','Yes');
        
        % Handle response
        switch choice
            
            case 'Yes';
                disp([choice 'Great, let''s keep going then!'])
                straighten_test = 0;
           
            case 'No';
                disp([choice 'That''s okay, try again!'])
                straighten_test = 1;
        end
   end
        % store the coordinates of the vector that extends from the
        % left well straight to the right well (if each well had the same y
        % coordinate)
    rotate_vector1 = [straighten_mat(2,1),straighten_mat(1,2)] - [straighten_mat(1,1),straighten_mat(1,2)];

    % store the coordinates of the vector that connects the two wells directly 
    rotate_vector2 = [straighten_mat(2,1),straighten_mat(2,2)] - [straighten_mat(1,1),straighten_mat(1,2)];

    % Find angle between the two vectors [angle in degrees]
    cosfine_angle_rotate = dot(rotate_vector1, rotate_vector2) / (norm(rotate_vector1) * norm(rotate_vector2));
    fine_angle_rotate = acosd(cosfine_angle_rotate);
    
        if (straighten_mat(2,2)<straighten_mat(1,2))
            fine_angle_rotate=-fine_angle_rotate;
        end
        
        struct.fine_angle_rotate = fine_angle_rotate;
        % Display the rotated image so the array is aligned
        b = imrotate(imgrotated, fine_angle_rotate, 'nearest','crop');
        b_contrasted = histeq(b);
        imshow(b_contrasted);
        hold on
        
         
        % Prompt user to select the left-most well of the array.
        title('Please zoom in on the the left-most well of the array (spaced at least one column away from the edge of the image)and press any key.');
        
        % use mouse button to zoom in or out
        zoom on;   
        pause()
        zoom off;
        
        % preallocate array bounds matrix
        array_bounds = zeros(4, 2);
        
        % prompt user to click on the center of the upper left well
        title('Please click on the center of the left-most well of the array.');
        
        [x_click,y_click] = ginput(1);
        plot(x_click(1),y_click(1),'r+','MarkerSize',10);
        hold on
        % store the coordinates the user selected for the upper left well
        x_leftwell = x_click;
        y_leftwell = y_click;
        zoom out;
        
        array_bounds(1,:) = [x_leftwell, y_leftwell];
        
        % Change message displayed in figure window to indicate the user should zoom in on the
        % right-most well
        title('Please zoom in on the the right-most well of the array (spaced at least one column away from the edge of the image) and press any key.')
        
        % use mouse button to zoom in or out
        zoom on;   
        pause()
    
        zoom off;
        
        % prompt user to click on the center of the right-most well
        title('Please click on the center of the right-most well of the array.');
        
        [x_click,y_click] = ginput(1);
        plot(x_click(1),y_click(1),'r+','MarkerSize',10);
        
        % store the coordinates of the user-selected upper right well
        x_rightwell = x_click;
        y_rightwell = y_click;
        zoom out;
        
        array_bounds(2,:) = [x_rightwell, y_rightwell];
        
        % Change display in imaged window to indicate user should zoom in
        % on the top-most well
        title('Please zoom in on the the top-most row of the array and press any key.')
        
        % use mouse button to zoom in or out
        zoom on;   
        pause()
        zoom off;
    
        % prompt user to click on the center of the top-most well
        title('Please click on the center of a well in top row of the array.');
        
        [x_click,y_click] = ginput(1);
        plot(x_click(1),y_click(1),'r+','MarkerSize',10);
        % store the user-selected coordinates of the lower right well
        x_topwell = x_click;
        y_topwell = y_click;
        
        zoom out
        array_bounds(3,:) = [x_topwell, y_topwell];
        
        
        
        % Change display in imaged window to indicate user should zoom in
        % on the bottom-most well
        title('Please zoom in on the the bottom-most row of the array (spaced at least one column from the edge of the image) and press any key.')
        
        % use mouse button to zoom in or out
        zoom on;   
        pause()
        zoom off;
    
        % prompt user to click on the center of the bottom-most well
        title('Please click on the center of a well in the bottom-most row of the array.');
        
        [x_click,y_click] = ginput(1);
        plot(x_click(1),y_click(1),'r+','MarkerSize',10);
        
        % store the user-selected coordinates of the lower right well
        x_bottomwell = x_click;
        y_bottomwell = y_click;
        
        zoom out
        array_bounds(4,:) = [x_bottomwell, y_bottomwell];
        
        % store all of the coordinates of the array bounds to the struct
        struct.array_bounds = array_bounds;
        
        
        % Construct a questdlg to ask the user if they are happy with their
         % well selection
        choice = questdlg('Are you happy with your well selections?', ...
        'Well selections for array boundaries', ...
        'Yes','No','Yes');
        
        % Handle response
        switch choice
            
            case 'Yes';
                disp([choice 'Great, let''s keep going then!'])
            
            case 'No';
                disp([choice 'That''s okay, try again!'])
                test = 1;
        end
     
    % check whether the user selected array boundaries are correct    
    if (x_rightwell<x_leftwell || y_bottomwell<y_topwell)        
        test = 1;
        
        title('Oh no! We detected you selected the wells in the wrong order. Please try again. Press any key to continue')
        pause()
    else
        test = 0;
    end
  end
    transform=1;
end


% Determine number of wells per row
wells_per_row = round((array_bounds(2,1) - array_bounds(1,1)) / horzspacing)+1;
struct.wells_per_row = wells_per_row;

% Determine number of rows
rows = round((array_bounds(4,2)-array_bounds(3,2)) / vertspacing)+1;

struct.rows = rows;

% Determine total number of wells
total_wells = wells_per_row * rows;


% for loop to fill in the 3D matrix with ROIs from the image (proceeds row by row of the microwell array from left to right)
% pre-allocate 3D matrix with zeros
mat = zeros(vertspacing, horzspacing, total_wells);

for i = 1:rows
    for j = 1:wells_per_row
        
        % determine z-coordinate for the current ROI
        z = (wells_per_row) * (i-1)+j;
        
        % set row start and end boundaries 
        row_start = (round(array_bounds(1,1)) - horzspacing/2) + ((j-1)*horzspacing);
        row_end = row_start + horzspacing;
        
        % set column start and end boundaries
        col_start = (round(array_bounds(3,2)) + ((i-1)*vertspacing));
        col_end = col_start + vertspacing;
        
        %generate lines that span the x and y coordinates of all the ROIs
        %to overlay over image to show the ROIs
        x = row_start:1:(row_end - 1);
        y = repmat(col_start, 1, length(x));
        y2 = col_start:1:(col_end);
        x2 = repmat((row_end), 1, length(y2));
        
        % fill the matrix with the image pixels within the current ROI
        % boundaries
        mat(: ,: ,z) = b(col_start:(col_end - 1), row_start:(row_end - 1));
        
        % plot the ROI grid overlay on the image
        plot(x', y', 'Color', 'r', 'LineStyle','-');
        plot(x', y', 'Color', 'r', 'LineStyle',':');
        plot(x2', y2', 'Color', 'r', 'LineStyle','-');
        plot(x2', y2', 'Color', 'r', 'LineStyle',':');
    end
end

% store the 3D matrix of ROIs to the struct
struct.rois = mat;
end

