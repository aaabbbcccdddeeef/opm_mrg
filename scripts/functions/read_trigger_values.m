function trl = read_trigger_values(data, tmin, tmax, mask, stim_chan, flip, shift)   

    stim_idx = find(strcmp(data.label, stim_chan));
    
    % get the occurences where the stim channel is bigger than the mask
    if flip
        indices = data.trial{1}(stim_idx, :) >= mask;
        str_indices = num2str(indices,'%-d');
        on_ind = strfind(str_indices, '10');
        on_ind = on_ind;
    else
        indices = data.trial{1}(stim_idx, :) >= mask;
        str_indices = num2str(indices,'%-d');
        on_ind = strfind(str_indices, '01');
        on_ind = on_ind + 1;      
    end
    
    if shift
        on_ind = on_ind + shift;
    end
   
    
    % correct onind for presentation screen at the end
    
    % get tmin and tmax
    tmin_samp = tmin * data.fsample;
    tmax_samp = tmax * data.fsample;

    % Get the trl
    % start end offset
    trl = [on_ind' + tmin_samp  ...
           on_ind' + tmax_samp  ...
           repmat(tmin_samp, ...
                   length(on_ind),1) repmat(1, length(on_ind),1)];
