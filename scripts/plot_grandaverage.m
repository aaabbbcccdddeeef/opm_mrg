%% PLOT GRANDAVERAGES

project_settings;  % imports data paths, subject identifiers
color_palettes;  % color specifications

%% read the MRG data

averages_opm = cell(1, length(subjects));
averages_simul = cell(1, length(subjects));

for ii = 1 : length(subjects)
    
    % get subject configuration using create_subject_conf(), which will update
    % all paths and file names for subj_conf:
    sub = subjects{ii};
    subj_conf = create_subject_conf(sub, proc_dir);
    
    % 1. OPM data
    load(fullfile(proc_dir, sub, 'average_opm.mat'));
    averages_opm{ii} = average;
    
    % 2. Simultaneous data
    load(fullfile(proc_dir, sub, 'average_simul.mat'));
    averages_simul{ii} = average;
end

%% Make grandaverages

grandavg_opm = ft_timelockgrandaverage([], averages_opm{:});
grandavg_simul = ft_timelockgrandaverage([], averages_simul{:});

%% Figure OPMs separate

h = figure;
pl = plot(grandavg_opm.time, grandavg_opm.avg, 'linewidth', 2);
set(pl, {'color'}, channel_colors);
% legend(grandavg_opm.label);
set(gca, 'xlim', [-0.1, 0.3])
set(gca, 'ylim', [-4.5, 4.5]*10^-13);
xlabel('Time [s]')
ylabel('Field Strength [T]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Grandaverages_timelock_sep.pdf');
print_figure('all', h, figure_fname);

%% Figure OPMs simultaneous

h = figure;
pl = plot(grandavg_simul.time, grandavg_simul.avg(2:end, :), 'linewidth', 2);
set(pl, {'color'}, channel_colors);
% legend(grandavg_simul.label{2:end});
set(gca, 'xlim', [-0.1, 0.3])
set(gca, 'ylim', [-4.5, 4.5]*10^-13);
xlabel('Time [s]')
ylabel('Field Strength [T]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Grandaverages_timelock_sim.pdf');
print_figure('all', h, figure_fname);

%% Figure ERG

h = figure;
plot(grandavg_simul.time, grandavg_simul.avg(1, :), 'linewidth', 2, ...
    'color', erg_color);
set(gca, 'xlim', [-0.1, 0.3])
xlabel('Time [s]')
ylabel('Amplitude [V]')

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Grandaverages_timelock_ERG.pdf');
print_figure('all', h, figure_fname);
