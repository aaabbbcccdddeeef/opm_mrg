function est_snr = estimate_snr_evoked(data, active, baseline)
    % Compute effective SNR of the data.
    
    % from time point to index
    signal_idx = dsearchn(data.time', active');
    noise_idx = dsearchn(data.time', baseline');
    
    % get a matrix of sensors x time
    signal = data.avg(:, signal_idx(1):signal_idx(2));
    noise = data.avg(:, noise_idx(1):noise_idx(2));        
    
    rms_signal = sqrt(mean(signal.^2, 2));
    rms_noise = sqrt(mean(noise.^2, 2));

    % mean over trials
    est_snr = rms_signal ./ (rms_noise);

    est_snr = 10 * log10(est_snr);