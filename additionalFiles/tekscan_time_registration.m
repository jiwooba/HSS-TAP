function results = tekscan_time_registration(pattern_of_interest, template, window_size, cycles_compared)
% Pre: Pattern of interest is the force or pressure pattern to be compared
%      to the template pattern.  The window_size is the length of a gait
%      cycle which is equal to 1/(samples per frame) times the time for 
%      1 gait cycle (which in our case is 2 seconds [0.5 Hz]).  For our
%      current experiments the window size is 19.  To use more than one
%      window length for template set cycles_compared to # of cycles to
%      use.
%Post: Outputs a structure containing the template pattern
%      (results.template), the shifted pattern of interest
%      (results.pattern_of_interest) and the time shift amount
%      (results.time_shift)
%% Perform Normalized Cross-Correlation
% call the cross-correlation function looking at the last 5 gait cycles in
% the pattern of interest and comparing it to the last two patterns in the
% template.
if numel(pattern_of_interest)/cycles_compared > window_size
% ccr = nccr(pattern_of_interest(end-5*window_size+1:end), template(end-cycles_compared*window_size+1:end), false); %whs edited, 4/28/13, use xcorr(), no need to included more cycle number
    [ccr lag] = nccr(pattern_of_interest(end-(cycles_compared+2)*window_size+1:end-2*window_size), template(end-(cycles_compared+2)*window_size+1:end-2*window_size), false);
else
    [ccr lag] = nccr(pattern_of_interest, template, false);
end

% Determine the location of the peak correlation and use this as the time shift.
[~, I] = max(ccr);
if lag(I) <= 0
    time_shift = window_size+lag(I);
else
    time_shift = lag(I);
end

%% Store Outputs
results.time_shift = time_shift; %number of elements data is shifted by
results.template = template; %don't really need this just felt like adding it
results.ncc_value = max(ccr); %Max normalized cross-correlation value

%% Reorder test cycle data to account for time shift 
%% (wraps shifted elements to end)
[row col] = size(pattern_of_interest);
if row>col
    results.pattern_of_interest = [pattern_of_interest(time_shift:end); pattern_of_interest(1:time_shift+1)];
else
    results.pattern_of_interest = [pattern_of_interest(time_shift:end) pattern_of_interest(1:time_shift+1)];
end
