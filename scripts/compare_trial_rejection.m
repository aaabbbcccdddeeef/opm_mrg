%% COMPARE ERG AND MRG TRIAL REJECTIONS

project_settings;
color_palettes;

% write trial numbers into a txt file:
trial_file = fopen(fullfile(proc_dir, 'trial_numbers_compared.txt'), 'w');
fprintf(trial_file, ...
    ('subjnum\ttrials_opm\ttrials_erg\ttrials_both\n'));

%% read the trial info

for ii = 1 : length(subjects)
    
    % get subject configuration using create_subject_conf(), which will update
    % all paths and file names for subj_conf:    
    sub = subjects{ii};
    subj_conf = create_subject_conf(sub, proc_dir);
    
    artif_opm = load(subj_conf.mrg_trl);
    artif_sim_erg = load(subj_conf.werg_trl_1);
    artif_sim_opm = load(subj_conf.werg_trl_2);
    
    trials_opm(ii) = length(artif_opm.cfg_artif.artfctdef.visual.artifact);
    trials_sim_erg(ii) = length(artif_sim_erg.cfg_artif.artfctdef.visual.artifact);
    trials_sim_opm(ii) = length(artif_sim_opm.cfg_artif2.artfctdef.visual.artifact);
    
    if ii == 2
       % we rejected extra trials for this participant
       % below is copied over from analyze_simultaneous_data.m
       reject_extra = [4, 52, 103, 117, 122, 133, 139, 143, 182, ...
                    225, 234, 235, 242, 246, 249, 257, 266, 267, 268, 282, ...
                    292, 295, 299];
       trials_sim_opm(ii) = trials_sim_opm(ii) + length(reject_extra);  
    end
    
    %% write to file
    fprintf(trial_file, '%s\t%i\t%i\t%i\n', sub, trials_opm(ii), ...
        trials_sim_erg(ii), trials_sim_opm(ii));
    
end

%% plot the results OPM vs ERG

h = figure;
% simultaneous data set MI
b = bar((1:3:length(subjects) * 3), trials_opm, 0.4); hold all
set(b, 'facecolor', sim_color, 'edgecolor', sim_color);

% separate data set MI
c = bar((2:3:length(subjects) * 3), trials_sim_erg, 0.4); hold all
set(c, 'facecolor', sep_color, 'edgecolor', sep_color)

xticks(1.5:3:length(subjects) * 3);
xticklabels(1:length(subjects));
xlabel('Participants')
ylabel('Rejected trials')

legend({'OPM data', 'ERG data'}, 'location', 'northwest')
