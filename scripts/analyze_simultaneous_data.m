%% PROCESS SIMULTANEOUS ERG AND MRG DATA

project_settings;
color_palettes;

% should data be cleaned by hand or is trl saved?
clean_hands = 'loadcfg';  % can be 'yes', 'loadcfg', or 'no'

% write trial numbers into a txt file:
trial_file = fopen(fullfile(proc_dir, 'trial_numbers_erg.txt'), 'w');
fprintf(trial_file, ...
    ('subjnum\t_trials\n'));

for jj = 1 : length(subjects)
    
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
    
    %% basic preprocessing
    
    cfg = [];
    cfg.dftfilter = 'yes';
    cfg.dftfreq = [50, 100, 150];
    epochs_simul = ft_preprocessing(cfg, epochs_simul);
    
    %% manual cleaning of the data
    
    % We do two passes: one with the ERG channel only, then another one on the
    % leftover data with the OPM channels only. This is done due to different
    % scaling but also sensitivity and different artifact profiles.
    
    switch clean_hands
        case'yes'
            
            % check if the file might already be there and abort
            if(exist(subj_conf.werg_trl_1, 'file') ~= 0)
                error('File already exists, make sure you do not overwrite it.')
            end
            
            cfg = [];
            cfg.channel = 'ERG';
            cfg.preproc.hpfilter = 'yes';  % filtering only for visualization
            cfg.preproc.hpfreq = 2;
            cfg.preproc.demean = 'yes';
            cfg.viewmode = 'butterfly';
            cfg_artif = ft_databrowser(cfg, epochs_simul);            
            epochs_clean = ft_rejectartifact(cfg_artif, epochs_simul);
            
                        
            cfg = [];
            cfg.channel = subj_conf.opm_channel;
            cfg.preproc.hpfilter = 'yes'; 
            cfg.preproc.hpfreq = 2;
            cfg.preproc.demean = 'yes';
            cfg.viewmode = 'butterfly';
            cfg_artif2 = ft_databrowser(cfg, epochs_clean);            
            epochs_clean = ft_rejectartifact(cfg_artif2, epochs_clean);
            
            % save the artifact config structures for later reuse
            save(subj_conf.werg_trl_1, 'cfg_artif');
            save(subj_conf.werg_trl_2, 'cfg_artif2');
            
        case 'loadcfg'
            
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

        otherwise  % This is just a shortcut for quick data checks
            
            warning('You asked not to do any trial rejection on the data.')
            epochs_clean = epochs_simul;
    end
    
    %% filtering
    
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = [-0.1, 0];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = 45;
    cfg.lpfilttype = 'firws';
    cfg.hpfilter = 'yes';
    cfg.hpfreq = 1;
    cfg.hpfilttype = 'firws';
    epochs_filtered = ft_preprocessing(cfg, epochs_clean);
    
    %% get a new average
    
    average = ft_timelockanalysis([], epochs_filtered);
    
    % save the data if trial rejection had been done
    if ~strcmp(clean_hands, 'no')
        save(fullfile(proc_dir, sub, 'epochs_clean_simul.mat'), 'epochs_clean');
        save(fullfile(proc_dir, sub, 'average_simul.mat'), 'average');
        
        % also write out trial numbers
        fprintf(trial_file, '%s\t%i\n', sub, length(epochs_filtered.trial));       
    end
    
    %% plot it
        
    h = figure;
    subplot(2, 1, 1)
    pl = plot(average.time, average.avg(2:end, :), 'linewidth', 2);
    legend(average.label{2:end});
    set(gca, 'xlim', [-0.2, 0.4])
    xlabel('Time [s]')
    ylabel('Field Strength [T]')
    title('MRG channels')
    
    subplot(2, 1, 2)
    plot(average.time, average.avg(1, :), 'linewidth', 2, ...
        'color', erg_color);
    title('ERG channel');
    set(gca, 'xlim', [-0.2, 0.4])
    xlabel('Time [s]')
    ylabel('Amplitude [V]')    
    
    figure_fname = fullfile(fig_dir, ['MRG_ERG_', sub, '.pdf']);
    print_figure(sub, h, figure_fname);    
    
end
