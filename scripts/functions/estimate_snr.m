function est_snr = estimate_snr(data, active, baseline)
    % Compute effective SNR of the data.
    
    % from time point to index
    signal_idx = dsearchn(data.time{1}', active');
    noise_idx = dsearchn(data.time{1}', baseline');
    
    % pre-allocation
    signal = zeros(numel(data.trialinfo), numel(data.label), ...
        diff(signal_idx) + 1);
    noise = zeros(numel(data.trialinfo), numel(data.label), ...
        diff(noise_idx) + 1);
    
    % get a matrix of trials x sensors x time
    for ii = 1:numel(data.trialinfo)
        signal(ii, :, :) = data.trial{ii}(:, signal_idx(1):signal_idx(2));
        noise(ii, :, :) = data.trial{ii}(:, noise_idx(1):noise_idx(2));        
    end
    
    
    rms_signal = sqrt(mean(signal.^2, 3));
    rms_noise = sqrt(mean(noise.^2, 3));

    % mean over trials
    est_snr = mean(rms_signal, 1) ./ mean(rms_noise, 1);

    est_snr = 10 * log10(est_snr);