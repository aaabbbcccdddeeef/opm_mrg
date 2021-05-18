%% PROCESS MRG DATA

project_settings;  % imports data paths, subject identifiers
color_palettes;  % imports color palette

% should data be cleaned by hand or is trl saved?
clean_hands = 'loadcfg';  % can be 'yes', 'loadcfg', or 'no'

% write trial numbers into a txt file:
trial_file = fopen(fullfile(proc_dir, 'trial_numbers_opm.txt'), 'w');
fprintf(trial_file, ...
    ('subjnum\t_trials\n'));

%% read the MRG data

for ii = 1: length(subjects)
    
    % get subject configuration using create_subject_conf(), which will update
    % all paths and file names for subj_conf:
    sub = subjects{ii};
    subj_conf = create_subject_conf(sub, proc_dir);
    
    %% Load data
    
    full_data_path = fullfile(data_path, subj_conf.subfold, sub, ...
        subj_conf.opm_file);
    
    cfg = [];
    cfg.dataset = full_data_path;
    data = ft_preprocessing(cfg);    
     
    %% Create epochs.
    
    flp = 0;
    shift = 0;
    
    % data, tmin, tmax, mask, stim_chan, flip, shift
    trl = read_trigger_values(data, -0.3, 0.5, subj_conf.opm_mask, ...
        stim_chan, flp, shift);
    
    cfg = [];
    cfg.trl = trl;
    epochs = ft_redefinetrial(cfg, data);        
    
    %% Basic preprocessing

    cfg = [];
    cfg.dftfilter = 'yes';
    cfg.dftfreq = [50, 100, 150];
    epochs = ft_preprocessing(cfg, epochs);
    
    cfg = [];
    cfg.channel = subj_conf.opm_channel;
    epochs = ft_selectdata(cfg, epochs);
    
    %% Trial selection
    
    % We do two passes: one with the ERG channel only, then another one on the
    % leftover data with the OPM channels only. This is done due to different
    % scaling but also sensitivity and different artifact profiles.
    switch clean_hands
        case 'yes'
            
            % check if the file might already be there and abort
            if(exist(subj_conf.mrg_trl, 'file') ~= 0)
                error('File already exists, make sure you do not overwrite it.')
            end
            
            % do manual trial selection
            cfg = [];
            cfg.preproc.hpfilter = 'yes';  % filtering only for visualization
            cfg.preproc.hpfreq = 2;
            cfg.preproc.demean = 'yes';
            cfg.viewmode = 'butterfly';
            cfg_artif = ft_databrowser(cfg, epochs);
            
            epochs_clean = ft_rejectartifact(cfg_artif, epochs);
            
            % save the artifact config structures for later reuse
            save(subj_conf.mrg_trl, 'cfg_artif');
            
        case 'loadcfg'            
            
            % load a previously saved configuration
            artif = load(subj_conf.mrg_trl);
            
            epochs_clean = ft_rejectartifact(artif.cfg_artif, epochs);
            
        otherwise  % This is just a shortcut for quick data checks
            warning('You asked not to do any trial rejection on the data.')
            epochs_clean = epochs;
    end

    % save these data
    save(fullfile(proc_dir, sub, 'epochs_clean.mat'), 'epochs_clean');
    
    %% Filter the data
    
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
    
    % save these data
    save(fullfile(proc_dir, sub, 'epochs_filtered.mat'), 'epochs_filtered');
  
    %% Average the data
    
    average = ft_timelockanalysis([], epochs_filtered);
     
    % save the data if trial rejection had been done
    if ~strcmp(clean_hands, 'no')
        save(fullfile(proc_dir, sub, 'epochs_clean_opm.mat'), 'epochs_filtered');
        save(fullfile(proc_dir, sub, 'average_opm.mat'), 'average');
        
        % also write out trial numbers
         fprintf(trial_file, '%s\t%i\n', sub, length(epochs_filtered.trial));       
    end       
    
    %% Plotting
    
    h = figure;
    
    pl = plot(average.time, average.avg, 'linewidth', 2);
    % legend(average.label, 'location', 'northeast');
    set(gca, 'xlim', [-0.1, 0.25])
    set(gca, 'fontsize', 18)
    xlabel('Time [s]')
    ylabel('Field Strength [T]')
    set(pl, {'color'}, channel_colors);
    title(['MRG channels, subj # ', sub(1:4)])  
    
    hold on
    plot(average.time, mean(average.avg), 'linewidth', 3, ...
        'color', average_color);
        
    figure_fname = fullfile(fig_dir, ['MRG_', sub, '.pdf']);
    print_figure(sub, h, figure_fname);    
 
end
