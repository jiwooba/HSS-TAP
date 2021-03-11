function datam=lp_filter(rawdata, frequency_sampling, frequency_cutoff);

%apply low pass filter, 1st order zero-lag butterworth filter
%first dimension have to be the time for filtfilt.
if frequency_cutoff > 0
    [b,a]=butter(6,frequency_cutoff/(frequency_sampling/2),'low');
    datam=filtfilt(b,a,rawdata);
else
    datam = rawdata;
end