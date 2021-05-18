%% COMPARE ERG AND MRG DATA

project_settings;  % imports data paths, subject identifiers
color_palettes;

% write trial numbers into a txt file:
stats_file = fopen(fullfile(proc_dir, 'mi_stat.txt'), 'w');
fprintf(stats_file, ...
    ('subjnum\tkind\tchan\tMI\tperm_pval_bonf\tentropy_erg\tentropy_opm\tentropy_joint\tbins\n'));

%% bins for MI
% set bins to [] for free computation. The number of bins will be printed
% to the output file. From there, an average number across subjects and
% conditons can be computed and set for all subjects/conditions.

bins = 9; % median=9.0, average=8.94 in free computation

%% read the MRG data

% preallocation
mi_simul = zeros(length(subjects), 1);
mi_separ = mi_simul;
mi_separ_subsamp = mi_simul;
average_sep = cell(length(subjects), 1);
average_sim = average_sep;
average_sim_full = average_sep;

for ii = 1 : length(subjects)
    
    % get subject configuration using create_subject_conf(), which will update
    % all paths and file names for subj_conf:
    sub = subjects{ii};
    subj_conf = create_subject_conf(sub, proc_dir);
    
    %% Load the OPM (separate) data

    load(fullfile(proc_dir, sub, 'average_opm.mat'));
    
    % we need the right time window to find max channel
    max_start = dsearchn(average.time', 0);
    max_stop = dsearchn(average.time', 0.1);
 
    % time window to look at correlation
    corr_start = dsearchn(average.time', -0.05);
    corr_stop = dsearchn(average.time', 0.15);
    
    % find max. channel @ b-wave and choose data
    [~, max_idx] = max(average.avg(:, max_start:max_stop), [], 'all', 'linear');
    [max_ch, ~] = ind2sub(size(average.avg(:, max_start:max_stop)), max_idx);    
    opm_alone_avg = average.avg(max_ch(1), corr_start:corr_stop);
    opm_alone_chan = average.label{max_ch(1)};
    
    % Afterthought:
    % select channels properly to be able to use grandaverage later    
    cfg = [];
    cfg.channel = max_ch(1);  % best channel
    average_sep{ii} = ft_selectdata(cfg, average); 
    average_sep{ii}.label{1} = 'bestchan';  % we want to average across diff chans
      
    %% Load the simultaneous data
    
    load(fullfile(proc_dir, sub, 'average_simul.mat'));
    average_sim_full{ii} = average;  % keep for plotting
    
    % find max. channel @ b-wave and choose data for OPMs
    [~, max_idx] = max(average.avg(2:end, max_start:max_stop), ...
        [], 'all', 'linear');  % first is ERG, thus 2:end
    [max_ch, ~] = ind2sub(size(average.avg(2:end, max_start:max_stop)), max_idx);    
    opm_simul_avg = average.avg(max_ch(1) + 1, corr_start:corr_stop);  % because first one is ERG
    opm_simul_chan = average.label{max_ch(1) + 1};
    
    % ERG
    erg_simul_avg = average.avg(1, corr_start:corr_stop);  % simply the first channel
  
    % Afterthought:
    % select channels properly to be able to use grandaverage later    
    cfg = [];
    cfg.channel = [1, max_ch(1) + 1];  % ERG and best channel
    average_sim{ii} = ft_selectdata(cfg, average); 
    average_sim{ii}.label{2} = 'bestchan';  % we want to average across diff chans
    
    % keep the number of trials:
    sim_trials_n = average.dof(1);
    
    %% Recompute the seperate data set average from adjusted trial number
    
    % compute a third average that is based on the separate data but
    % adjusts the number of trials to the number of trials in the
    % simulateneous data set to prevent SNR effects.
    % For this, we have to reload the original data and downsample the
    % trials before computing the average.
    
    % this is exactly the data we subsequently compute the average on in the 
    % script analyze_mrg_data.m
     
    load(fullfile(proc_dir, sub, 'epochs_filtered.mat'));
    
    % downsample
    rng(11021822 + ii);  % control the random number stream
    
    if ii == 2
        % participant 2 is the only one that has (slightly) more trials in
        % the simultaneous condition, so we just keep all trials.
       trials = 'all'
    else
       trials = randsample(length(epochs_filtered.trial), sim_trials_n, false);      
    end
    
    % select trials and compute average
    cfg = [];
    cfg.trials = trials;
    cfg.channel = opm_alone_chan;  % use exactly same channel as before
    epochs_subsamp = ft_selectdata(cfg, epochs_filtered);
    
    average = ft_timelockanalysis([], epochs_subsamp);
    
    % select the right time
    opm_alone_subsamp_avg = average.avg(:, corr_start:corr_stop);
    
    %% Compute MI and correlation, and plot the data
    
    % Note: Mutual information is computed using the code that accompanies
    % the book Analyzing neural time series data (2014) by Mike X. Cohen. This
    % code can be found here (retrieved Nov. 19th, 2020): 
    % https://github.com/mikexcohen/AnalyzingNeuralTimeSeries/blob/main/mutualinformationx.m
    % The number of permutations has been raised from 500 to 5000 in the
    % code. And the code has been changed to give back the MI of the permuations.
    
    % SIMULTANEOUS DATASET
    [mi, entropy, fd_bins, permi] = mutualinformationx(erg_simul_avg, ...
        opm_simul_avg, bins, true);
    % compute the p-value by hand
    p_val = sum(permi >= mi)/5000;
     p_val = p_val/(length(subjects) * 2);  % Bonferroni correct for 16 tests
    
    % print it out
    fprintf(stats_file, '%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n', ...
        sub, 'simul', opm_simul_chan, mi, p_val, ...
        entropy(1), entropy(2), entropy(3), fd_bins);

    % save for plotting
    mi_simul(ii) = mi;
    
    h = figure; 
    set(h, 'defaultAxesColorOrder', [erg_color; opm_color]);
    yyaxis left
    plot(average.time(corr_start:corr_stop), erg_simul_avg, ...
        'linewidth', 2);
    ylabel('Amplitude [V]')
    yyaxis right
    plot(average.time(corr_start:corr_stop), opm_simul_avg, ...
        'linewidth', 2); hold on
    ylabel('Field Strength [T]')
    
    % SEPARATE DATASET
    [mi, entropy, fd_bins, permi] = mutualinformationx(erg_simul_avg, ...
        opm_alone_avg, bins, true);   
    % compute the p-value by hand
    p_val = sum(permi >= mi)/5000;
    p_val = p_val/(length(subjects) * 2);  % Bonferroni correct for 16 tests
    
    % print it out 
    fprintf(stats_file, '%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n', ...
        sub, 'separate', opm_alone_chan, mi, p_val, ...
        entropy(1), entropy(2), entropy(3), fd_bins); 
    
    fprintf('Saved statistics for participant %s. \n', sub);
    
    % save for plotting
    mi_separ(ii) = mi;
    
    yyaxis right
    plot(average.time(corr_start:corr_stop), opm_alone_avg, ...
        'linewidth', 2);   
    xlabel('Time [s]')   
    legend({'ERG', 'OPM simultaneous dataset', 'OPM separate dataset'})
    
    % define min and max of the y-axes, to ensure that 0 lines up
    y_lim_left = max(abs(erg_simul_avg)) * 1.1;
    y_lim_right = max([max(abs(opm_simul_avg)), max(abs(opm_alone_avg))]) * 1.1;
    
    yyaxis left
    set(gca, 'ylim', [-y_lim_left, y_lim_left]);
    yyaxis right
    set(gca, 'ylim', [-y_lim_right, y_lim_right]);
    
    figure_fname = fullfile(fig_dir, ['Corr_', sub, '.pdf']);
    print_figure(sub, h, figure_fname);  
    
    % ADJUSTED SEPARATE DATASET
    [mi, entropy, fd_bins, permi] = mutualinformationx(erg_simul_avg, ...
        opm_alone_subsamp_avg, bins, true);   
    % compute the p-value by hand
    p_val = sum(permi >= mi)/5000;
    p_val = p_val/(length(subjects) * 2);  % Bonferroni correct for 16 tests
    
    % print it out 
    fprintf(stats_file, '%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n', ...
        sub, 'sep_subsamp', opm_alone_chan, mi, p_val, ...
        entropy(1), entropy(2), entropy(3), fd_bins); 
    
    fprintf('Saved statistics for participant %s. \n', sub);
    
    % save for plotting
    mi_separ_subsamp(ii) = mi;    
    
end

%% Plot all ERG channels

h = figure;
hold all
for ii = 1:length(average_sim)
    plot(average_sim{ii}.time, average_sim{ii}.avg(1, :), ...
        'color', erg_color, 'linewidth', 2);
end
set(gca, 'xlim', [-0.1, 0.3])
set(gca, 'ylim', [-10, 10]*10^-5)
ylabel('Amplitude [V]')
xlabel('Time [s]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Subjects_ERG.pdf');
print_figure('all', h, figure_fname);

%% Plot all OPM best channels

h = figure;
hold all
for ii = 1:length(average_sim)
    plot(average_sim{ii}.time, average_sim{ii}.avg(2, :), ...
        'color', opm_color, 'linewidth', 2);
end
set(gca, 'ylim', [-1.8 1.8]*10^-12)
set(gca, 'xlim', [-0.1, 0.3])
ylabel('Field Strength [T]')
xlabel('Time [s]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Subjects_bestchan.pdf');
print_figure('all', h, figure_fname);

%% Plot OPM averages across all channels

h = figure;
hold all
for ii = 1:length(average_sim_full)
    plot(average_sim_full{ii}.time, ...
        mean(average_sim_full{ii}.avg(2:end, :), 1), ...
        'color', opm_color_avg, 'linewidth', 2);
end
set(gca, 'ylim', [-6.5 6.5]*10^-13)
set(gca, 'xlim', [-0.1, 0.3])
ylabel('Field Strength [T]')
xlabel('Time [s]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Subjects_OPM_avg.pdf');
print_figure('all', h, figure_fname);

%% Make grandaverages

grandavg_sep = ft_timelockgrandaverage([], average_sep{:});
grandavg_sim = ft_timelockgrandaverage([], average_sim{:});



%% Plot grandaverage of best channels 

h = figure;
set(h, 'defaultAxesColorOrder', [erg_color; opm_color]);
yyaxis left
plot(grandavg_sim.time, grandavg_sim.avg(1, :), 'linewidth', 2);
ylabel('Amplitude [V]')
set(gca, 'ylim', [-5.5, 5.5]*10^-5);

yyaxis right
plot(grandavg_sim.time, grandavg_sim.avg(2, :), 'linewidth', 2); hold on
plot(grandavg_sep.time, grandavg_sep.avg, 'linewidth', 2); hold on
ylabel('Field Strength [T]')
set(gca, 'ylim', [-5.5 5.5]*10^-13);

set(gca, 'xlim', [-0.1, 0.3]);
legend({'ERG', 'MRG simultaneous dataset', 'MRG separate dataset'});
xlabel('Time [s]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Grandaverages_bestchan.pdf');
print_figure('all', h, figure_fname);

%% Plot Mutual information

h = figure;
% simultaneous data set MI
b = bar((1:3:length(subjects) * 3), mi_simul, 0.4); hold all
set(b, 'facecolor', sim_color, 'edgecolor', sim_color);

% separate data set MI
c = bar((2:3:length(subjects) * 3), mi_separ, 0.4); hold all
set(c, 'facecolor', sep_color, 'edgecolor', sep_color)

xticks(1.5:3:length(subjects) * 3);
xticklabels(1:length(subjects));
xlabel('Participants')
ylabel('Mututal information (bits)')

set(gca, 'FontSize', 22)
set(gca, 'ylim', [0, 2.2])

legend({'Simultaneous dataset', 'Separate datasets'}, 'location', 'northwest')

figure_fname = fullfile(fig_dir, 'MI_bar.pdf');
print_figure('all', h, figure_fname);

%% Plot Mutual information (supplementary)

h = figure;
% simultaneous data set MI
b = bar((1:4:length(subjects) * 4), mi_simul, 0.4); hold all
set(b, 'facecolor', sim_color, 'edgecolor', sim_color);

% separate data set MI
c = bar((2:4:length(subjects) * 4), mi_separ, 0.4); hold all
set(c, 'facecolor', sep_color, 'edgecolor', sep_color)

% separate data set MI with adjusted trials
c = bar((3:4:length(subjects) * 4), mi_separ_subsamp, 0.4); hold all
set(c, 'facecolor', sep_color_subsamp, 'edgecolor', sep_color_subsamp)

xticks(1.5:4:length(subjects) * 4);
xticklabels(1:length(subjects));
xlabel('Participants')
ylabel('Mututal information (bits)')

set(gca, 'FontSize', 22)
set(gca, 'ylim', [0, 2.2])

legend({'Simultaneous dataset', 'Separate datasets', ...
    'Separate datasets, equal n'}, 'location', 'northwest')

figure_fname = fullfile(fig_dir, 'MI_bar_suppl.pdf');
print_figure('all', h, figure_fname);
