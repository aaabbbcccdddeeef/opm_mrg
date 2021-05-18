%% TEST SENSITIVITY PROFILE

project_settings;  % imports data paths, subject identifiers
color_palettes;

%% bins for MI
% set bins to [] for free computation. The number of bins will be printed
% to the output file. From there, an average number across subjects and
% conditons can be computed and set for all subjects/conditions.

bins = 9;  % median=9, mean=8.94 in free computation

%% Loop over subjects

for ii = 1 : length(subjects)
    
    % get subject configuration:
    sub = subjects{ii};
    subj_conf = create_subject_conf(sub, proc_dir);    
         
    %% Load the simultaneous data
    load(fullfile(proc_dir, sub, 'average_simul.mat'));
    % average_sim_full{ii} = average;  % keep for plotting
 
    % time windows to look at MI
    mi_start = dsearchn(average.time', -0.05);
    mi_stop = dsearchn(average.time', 0.15);    

    % ERG
    erg_simul_mi = average.avg(1, mi_start:mi_stop);  % simply first channel
    
    %% Compute MI 
    
    % Note: Mutual information is computed using the code that accompanies
    % the book Analyzing neural time series data (2014) by Mike X. Cohen. This
    % code can be found here (retrieved Nov. 19th, 2020): 
    % https://github.com/mikexcohen/AnalyzingNeuralTimeSeries/blob/main/mutualinformationx.m
    % The number of permutations has been raised from 500 to 5000 in the
    % code.
    
    % Loop across channels
    for ch = 2:9  % first channel is ERG
        % a-wave
        opm_simul_avg = average.avg(ch, mi_start:mi_stop);
        [mi, entropy, fd_bins] = mutualinformationx(...
            erg_simul_mi, opm_simul_avg, ...
            bins);
        mi_all(ii, ch-1) = mi;
        % bins_all(ii, ch-1) = fd_bins;  % useful if free computation
             
    end     
end

%% Plot with representation of precision

% channel plotting values
x_axis = [3, 4, 2, 1, 2, 1, 4, 3];
y_axis = [4, 1, 1, 4, 3, 2, 3, 2];

plot_color = mean(mi_all, 1);
plot_size = std(mi_all, [], 1);
plot_size = 1 ./ (plot_size * 13^-3);

figure;
scatter(x_axis, y_axis, plot_size, plot_color, 'filled'); 
caxis([1.0, 1.5]);

colorbar
set(gca, 'xlim', [0, 5])
set(gca,'visible','off')
set(gca,'xtick',[])
colormap(cmocean('algae'))

set(gca, 'FontSize', 22)

% remember to change print_figure
figure_fname = fullfile(fig_dir, ['Sensitivity_MI.eps']);
print_figure('all', gcf, figure_fname); 
