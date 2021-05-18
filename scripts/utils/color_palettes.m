%%  Colors for visualization

average_color = [231,  41, 138] / 255;  % average for indiv. plots

% blue - green, arranged along the axes of the grid
channel_colors = [
    224, 243, 219  % ch 1
    123, 204, 196  % ch 2
      8,  64, 129  % ch 3
     78, 179, 211  % ch 4
     43, 140, 190  % ch 5
      8, 104, 172  % ch 6
    204, 235, 197  % ch 7
    168, 221, 181  % ch 8
    ] /  255;

channel_colors = mat2cell(channel_colors, ...
    repmat(1, 1, size(channel_colors, 1)), 3);

% For plotting of OPM vs ERG
opm_color  = [  5,  48,  97] / 255;  % dark blue
opm_color_avg = [ 33, 102, 172] / 255;  % middle blue
erg_color = [214,  96,  77] / 255;  % red

% For plotting of simultaneous vs separate data sets
sep_color_subsamp = [173, 221, 142] / 255;  % light green
sep_color = [ 65, 171,  93] / 255;  % mid green
sim_color = [  0,  69,  41] / 255;  % dark green


