%% NOISE LEVEL AND  SIGNAL-TO-NOISE RATIO

% Use the simultaneous recording

project_settings;
color_palettes;

% preallocation
psd_erg = cell(length(subjects), 1);
psd_opm = psd_erg;
est_snrs_evoked = zeros(length(subjects), 9);
est_snrs_epochs = est_snrs_evoked;

for jj = 1:length(subjects)
    
    % get subject configuration using create_subject_conf(), which will update
    % all paths and file names for subj_conf:
    sub = subjects{jj};
    subj_conf = create_subject_conf(sub, proc_dir);
    
    %% Load all the data
    
    epochs = cell(1, 2);
    
    for ii = 1:2  % there should be two files, MRG and ERG
        
        % specs
        if ii  == 1
            % MRG file
            data_fname = fullfile(data_path, subj_conf.subfold, sub, ...
                subj_conf.opm_werg_file);
            wear_a_mask = subj_conf.opm_mask;
            use_stim_chan = stim_chan;
        else
            % ERG file (Elekta)
            data_fname = fullfile(data_path, 'OPMerg', ...
                subj_conf.erg_subfold, subj_conf.erg_file);
            wear_a_mask = subj_conf.erg_mask;
            use_stim_chan = stim_chan_erg;
        end
        
        %% Read data
        
        cfg = [];
        cfg.dataset = data_fname;
        data = ft_preprocessing(cfg);

        %% Compute PSD per channel
        
        if ii == 1
            channels = subj_conf.opm_channel;
        else
            % ERG data
            channels = subj_conf.erg_channel;            
        end            
        
        cfg = [];
        cfg.taper = 'hamming';
        cfg.method = 'mtmfft';
        cfg.foi = 1:1:200;
        cfg.channel =  channels;
        pow = ft_freqanalysis(cfg, data);
        
        if ii == 1
            psd_opm{jj} = pow;
        else
            psd_erg{jj} = pow;
        end
        
        %%  Create epochs
        
        flp = 0;
        shift = 0;
        
        % data, tmin, tmax, mask, stim_chan, flip, shift
        trl = read_trigger_values(data, -0.3, 0.5, wear_a_mask, ...
            use_stim_chan, flp, shift);
        
        cfg = [];
        cfg.trl = trl;
        epochs{ii} = ft_redefinetrial(cfg, data);
        
        if jj == 4 | jj == 1
            % light on before the recording ended, this resulted in extra
            % "trials" at the end of the recording.
            cfg = [];
            cfg.trials = 1:400;
            epochs{ii} = ft_selectdata(cfg, epochs{ii});            
        end
        
        if length(epochs{ii}.trial) ~= 400
            error('Did not yield the expected number of trials for subject %s in run %i: got %i', ...
                sub, ii, length(epochs{ii}.trial));
        end
    end

    %% get the data into one structure
    
    erg_chan_idx = find(strcmp(epochs{2}.label, subj_conf.erg_channel));
    opm_stim_idx = find(strcmp(epochs{1}.label, stim_chan));
    
    % let's just do this by hand:
    % we will replace the trigger channel with the ERG data. The trigger
    % channel would be excluded from the data at this point anyway
    
    epochs_simul = epochs{1};
    
    for ii = 1:length(epochs_simul.trial)
        
        epochs_simul.trial{ii}(opm_stim_idx, :) = epochs{2}.trial{ii}(erg_chan_idx, :);
        
    end
    
    epochs_simul.label{opm_stim_idx} = 'ERG';  % update label
    
    %% Reject trials
    
    % load a previously saved configuration
    
    load(subj_conf.werg_trl_1);
    load(subj_conf.werg_trl_2);
    epochs_clean = ft_rejectartifact(cfg_artif, epochs_simul);
    epochs_clean = ft_rejectartifact(cfg_artif2, epochs_clean);
    
    if strcmp(sub, subjects{2}) 
        % subj 2 showed some strong linear trend in 1 channel that was
        % not fixable with detrending. Rejecting some additional
        % trials did the trick:
        reject_extra = [4, 52, 103, 117, 122, 133, 139, 143, 182, ...
            225, 234, 235, 242, 246, 249, 257, 266, 267, 268, 282, ...
            292, 295, 299];
        
        cfg = [];
        cfg.trials = setdiff(1:length(epochs_clean.trialinfo), ...
            reject_extra);
        epochs_clean = ft_selectdata(cfg, epochs_clean);
    end
    
    %% Demeaning and DFT filter
    cfg = [];
    cfg.demean = 'yes';
    % cfg.baselinewindow = [-0.1, 0];
    cfg.dftfilter = 'yes';
    cfg.dftfreq = [50, 100, 150];
    epochs_clean = ft_preprocessing(cfg, epochs_clean);    
    
    %% Calculate SNR
    
    evoked = ft_timelockanalysis([], epochs_clean);
    active = [0.03, 0.1];
    baseline = [-0.1, -0.03];
    
    est_snrs_evoked(jj, :) = estimate_snr_evoked(evoked, active, baseline);
    
    % single trial SNR
    est_snrs_epochs(jj, :) = estimate_snr(epochs_clean, active, baseline);    
    
end

%% Plot SNRs over subjects -- single trials

colors = [erg_color; channel_colors];

h = figure;
hold all
for ch = 1:size(est_snrs_epochs, 2)
    plot(1:length(subjects), est_snrs_epochs(:, ch)', '.-', 'markersize', 20, ...trl
        'linewidth', 2, 'color', colors{ch});   
end

xlabel('Participants')
ylabel('Signal-to-noise ratio [dB]')
% set(gca, 'ylim', [0, 12]) 
set(gca, 'xlim', [0, 9]) 

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'SNR_epochs.pdf');
print_figure('all', h, figure_fname);

%% Plot SNRs over subjects -- evoked

colors = [erg_color; channel_colors];

h = figure;
hold all
for ch = 1:size(est_snrs_evoked, 2)
    plot(1:length(subjects), est_snrs_evoked(:, ch)', '.-', 'markersize', 20, ...
        'linewidth', 2, 'color', colors{ch});   
end

xlabel('Participants')
ylabel('Signal-to-noise ratio [dB]')

set(gca, 'xlim', [0, 9]) 

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'SNR_evoked.pdf');
print_figure('all', h, figure_fname);

%% Combine PSD over subjects

cfg = [];
cfg.keepindividual = 'yes';
psd_grandavg_erg = ft_freqgrandaverage(cfg, psd_erg{:});
psd_grandavg_opm = ft_freqgrandaverage(cfg, psd_opm{:});

%% Plot PSD

h = figure;
set(h, 'defaultAxesColorOrder', [erg_color; opm_color]);
ylims = [10^-31, 10^-8];

% ERG
yyaxis left
plot(psd_grandavg_erg.freq, squeeze(psd_grandavg_erg.powspctrm), '-', ...
              'linewidth', 2, 'color', erg_color);
set(gca, 'YScale', 'log')
set(gca, 'ylim', ylims);
ylabel('Power spectrum [V^{2}/Hz]')

% OPMS
yyaxis right
% mean over channels for OPM
plot(psd_grandavg_opm.freq, squeeze(mean(psd_grandavg_opm.powspctrm, 2)), ...
             '-', 'linewidth', 2, 'color', opm_color);
set(gca, 'YScale', 'log')  
set(gca, 'ylim', ylims);
ylabel('Power spectrum [T^{2}/Hz]')

xlabel('Frequency [Hz]')
legend({'OPM'})

set(gca, 'FontSize', 22)

figure_fname = fullfile(fig_dir, 'Noise_spectrum.pdf');
print_figure('all', h, figure_fname);
