% 내가 한 Pre-processing된 EEG 데이터를 불러오기!!
EEG_cleaned = pop_loadset('after_ICA_Final.set');  


n_channels = size(EEG_cleaned.data, 1);  
n_points = size(EEG_cleaned.data, 2);    
sampling_rate = EEG_cleaned.srate;     
window_size = 2 * sampling_rate;       
step_size = 1 * sampling_rate;         
n_windows = floor((n_points - window_size) / step_size) + 1;  

% alpha_power를 저장할 0으로 된 array를 initialize!
alpha_power_time = zeros(n_windows, 1);
time_vector = (0:n_windows-1) * (step_size / sampling_rate); 

for w = 1:n_windows
    start_idx = (w-1) * step_size + 1;
    end_idx = start_idx + window_size - 1;
    
    eeg_window = EEG_cleaned.data(:, start_idx:end_idx);  % 윈도우에 해당하는 데이터
    
    % 각 채널별로 FFT 계산 후 alpha_power 추출
    fft_result = fft(eeg_window, [], 2);
    power_spectrum = abs(fft_result / window_size).^2;
    freqs = sampling_rate * (0:(window_size/2)) / window_size;
    
    % alpha_power frequency setting 해주기 
    alpha_idx = find(freqs >= 8 & freqs <= 12);
    
    % 모든 채널 평균 alpha_power 계산!
    alpha_power_time(w) = mean(mean(power_spectrum(:, alpha_idx), 2));
end

%visualize 단계 
figure;
plot(time_vector, alpha_power_time, 'LineWidth', 2);  % 시간에 따른 알파 파워 시각화
xlabel('Time (s)');
ylabel('Alpha Power');
title('Average Alpha Power Over Time during Tasks');
