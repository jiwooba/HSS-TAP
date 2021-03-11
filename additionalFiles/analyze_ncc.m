function ccr = analyze_ncc(hObject, handles, testcase, frequency_sampling, frequency_cutoff)
%% Cross-correlation of each sensel
%% Initialize Variables

% the pattern curves in "corr_patterns(curr_index).patterns{i}" have not
% been aligned, the time shift information was stored in
% corr_patterns(curr_index).shift(i)

% counter = 1; %keeps track of the found correlated patterns
sensel_tracker = 0; %Used to keep track of the progress bar completeness
elapsedtime = 0; %Keep track of the elapsed time to calculate the time remaining
flag_tracker = 0; %Tracks index for next correlation

% set variables for number of cycles
length_time = handles.length_time;
window_size = handles.window_size;
max_cycles = floor(length_time/window_size);

% get values for minimum threshold for a match
threshold_value = str2double(get(handles.corr_thresh, 'String')); %Get the threshold value to use to determine whether two force patterns are a match
num_threshold = str2double(get(handles.ncc_thresh, 'String')); %Get the threshold value to use to determine whether the pattern can be considered common

% gets current struct containing recorded data from sensor acq of interest
sensels = handles.sensels{testcase}; 

% get cycle range of interest to average
[start_cycle, end_cycle] = getCycles(handles.avg_data,handles,max_cycles);

% gets elements within the selected range of cycles
range_of_interest = window_size*(max_cycles-start_cycle)+1:window_size*(max_cycles-end_cycle)+window_size; %edited by Hongsheng, 5/3/13 *Originally 4 & 1
num_of_cycle = length(range_of_interest)/window_size;

% index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
% selected_condition = get(handles.condition_selector, 'Value'); %gets index of currently selected condition
big_o = size(sensels,1)^2*size(sensels,2)^2; %determines the number steps for the progress slider

%% Creates a blank tekscan map to overlay locations of similar patterns
corr_map_template = handles.senselvar{1}(:,:,1);
corr_map_template(~isnan(corr_map_template)) = 0;

%% Initialize Characteristic Curve Structure
char_curves = []; %Struct to store the found characteristic curves and correlation maps
char_curves(size(sensels,1),size(sensels,2)).ncc_value = [];
char_curves(size(sensels,1),size(sensels,2)).flag = [];

corr_patterns(1). patterns = {};
corr_patterns(1).ncc_value = [];
corr_patterns(1).shift = [];
corr_patterns(1).corr_map = corr_map_template;
corr_patterns(1).corr_map_amp = corr_map_template; %edited by whs, 5/22/13

%% Initialize waitbar

h = waitbar(0,'Comparing Sensels...','Name',['Finding Characteristic Force Patterns (' handles.tekvar_name{testcase} ')'],...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');

set(h, 'units', 'normalized','position', [0.3 0.45 0.3 0.1]);
set(0, 'ShowHiddenHandles', 'on')
childrenWaitb = get(h, 'Children');
set(childrenWaitb, 'units', 'normalized', 'Position', [0.15 0.5 0.7 0.2]);
set(childrenWaitb(2), 'units', 'normalized', 'Position', [0.35 0.1 0.3 0.2]);
setappdata(h,'canceling',0);
set(0, 'ShowHiddenHandles', 'off')
set(h, 'WindowStyle', 'modal'); %force progress bar always on top

%% 
tic

try
    %% rasters through template sensels
    for x = 1:size(sensels,1)
        for y = 1:size(sensels,2)
            template = reshape(sensels{x,y},length_time,1); %reorganize the sensel to a vector ordered by time
            template = [template(handles.time_shift_by{testcase}:end); template(1:handles.time_shift_by{testcase})]; %shift vector based on previous pattern registration
            template_pattern = (template(range_of_interest)); %whs edited, 4/28/2013 *only look only a specific range of patterns
            corr_map = corr_map_template; %start with blank tekscan map
            if (~isnan(template_pattern)) %make sure template pattern does not contain NaN
                template_pattern = lp_filter(template_pattern, frequency_sampling, frequency_cutoff); %whs edited, low pass filted the data :: tc added dialog to change lp filter
                if max(template_pattern)>str2double(get(handles.noise_floor_edit, 'String')) %check if the max value of template is above the noise floor set
                    %% raster through comparison sensels for each template sensel
                    for xsensel = x:size(sensels,1)
                        for ysensel = 1:size(sensels,2)
                            curr_sensel = reshape(sensels{xsensel,ysensel},length_time,1); % reorganize the sensel to a vector ordered by time
                            curr_sensel = [curr_sensel(handles.time_shift_by{testcase}:end); curr_sensel(1:handles.time_shift_by{testcase})]; %shift vector based on previous registration
                            if ~isnan(curr_sensel) % make sure sensel does not contain NaN
                                if max(curr_sensel)>str2double(get(handles.noise_floor_edit, 'String')) % check if the max value of the sensel is above the noise floor
                                    curr_sensel(range_of_interest) = lp_filter(curr_sensel(range_of_interest), frequency_sampling, frequency_cutoff); % whs edited, low pass filted the data
                                    
                                    %average template and current comparison sensel
                                    curr_sensel_avg = curr_sensel(range_of_interest(1):range_of_interest(window_size));
                                    template_pattern_avg = template_pattern(1:window_size);
                                    for avg_ccrs = 1:num_of_cycle-1
                                        curr_sensel_avg = curr_sensel_avg + curr_sensel(range_of_interest(avg_ccrs*window_size+1):range_of_interest(avg_ccrs*window_size+window_size));
                                        template_pattern_avg = template_pattern_avg + template_pattern(avg_ccrs*window_size+1:(avg_ccrs*window_size+window_size));
                                    end
                                    curr_sensel_avg = curr_sensel_avg/num_of_cycle;
                                    template_pattern_avg = template_pattern_avg/num_of_cycle;
                                    
                                    ccr_truncated = nccr(curr_sensel_avg, template_pattern_avg, false); % get ncc between averaged data of template and current pattern
                                    
                                    if (x~=xsensel || y>ysensel) % Also check that template and comparison are not the same sensel
                                        if length(ccr_truncated(ccr_truncated >= threshold_value)) >= 1 % make sure there is a ncc value above the threshold (Can be increased to make the algorithm more stringent. 
                                            corr_map(xsensel, ysensel) = max(ccr_truncated);
                                            if ~isempty(char_curves(x,y).ncc_value) % make sure that there are already matches identified for the current template sensel
                                                if ~isempty(char_curves(xsensel,ysensel).ncc_value) % if the comparison sensel already contains matches
                                                    if char_curves(xsensel,ysensel).ncc_value < max(ccr_truncated) %make sure the comparison sensel does not contain a match greater than the current template
                                                        char_curves(xsensel,ysensel).ncc_value = max(ccr_truncated); %set max ncc_value of the comparison sensel to the calculated ncc
                                                        char_curves(xsensel,ysensel).flag = char_curves(x,y).flag; %put comparison sensels in same group as template
                                                    else
                                                        % do nothing
                                                    end
                                                else
                                                    char_curves(xsensel,ysensel).ncc_value = max(ccr_truncated);
                                                    char_curves(xsensel,ysensel).flag = char_curves(x,y).flag;
                                                end
                                            else % if no pattern ID set for the current template
                                                if ~isempty(char_curves(xsensel,ysensel).ncc_value) % if the comparison sensel already contains matches
                                                    if char_curves(xsensel,ysensel).ncc_value < max(ccr_truncated) % make sure the comparison sensel does not contain a match greater than the current template
                                                        flag_tracker = flag_tracker + 1; % create new pattern ID
                                                        char_curves(x,y).ncc_value = max(ccr_truncated); % set max ncc_value of the template sensel to the calculated ncc
                                                        char_curves(x,y).flag = flag_tracker; % set pattern ID of the template
                                                        char_curves(xsensel,ysensel).ncc_value = max(ccr_truncated); % set ncc value of the comparison to the same as the template
                                                        char_curves(xsensel,ysensel).flag = char_curves(x,y).flag; % put the comparison sensels in the same group as the template
                                                    else
                                                        % do nothing, because the correlation is not as strong as the previous one
                                                    end
                                                else % if comparison and template do not have any identified patterns
                                                    flag_tracker = flag_tracker + 1; % create new pattern ID
                                                    char_curves(x,y).ncc_value = max(ccr_truncated); % set max ncc_value of the template sensel to the calculated ncc
                                                    char_curves(x,y).flag = flag_tracker; % set pattern ID of the template
                                                    char_curves(xsensel,ysensel).ncc_value = max(ccr_truncated); % set ncc value of the comparison to the same a the template
                                                    char_curves(xsensel,ysensel).flag = flag_tracker; % put the comparison sensels in the same group as the template
                                                end
                                            end
                                        end
                                    end
                                end
                            end % (~isnan)
                                                        
                            comp_time = toc;
                            tic
                            sensel_tracker = sensel_tracker+1;
                            elapsedtime = elapsedtime + comp_time;
                            avg_time = elapsedtime/sensel_tracker;
                            if mod(sensel_tracker, 600)==0
                                waitbar(sensel_tracker / (big_o),h,['Time Remaining: ' sprintf('%i',floor((avg_time*(big_o)-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((avg_time*(big_o)-elapsedtime),3600)/60)) ':' sprintf('%02.4f',rem(rem((avg_time*(big_o)-elapsedtime),3600),60))...
                                    sprintf('     Time Elapsed: ') sprintf('%i',floor(elapsedtime/3600)) ':' sprintf('%i',floor(rem(elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem(elapsedtime,3600),60))])
                            end
                            
                            if getappdata(h,'canceling')
                                break
                            end
                            
                        end
                    end
                else
                    sensel_tracker = sensel_tracker + size(sensels,1)*size(sensels,2);
                end
            else
                sensel_tracker = sensel_tracker + size(sensels,1)*size(sensels,2);
            end
            
            if getappdata(h,'canceling')
                break
            end
            
        end % x = 1:size()
    end% y = 1:size()
    
    % collect the patterns, sensels which has the same pattern will be
    % collected together. 'corr_patterns(curr_index).shift' is the shift of each
    % sensel relative to the first sensel in the same group.
    for x = 1:size(sensels,1) % raster across elements in the x direction
        for y = 1:size(sensels,2) % raster across elements in the y direction
            curr_index = char_curves(x,y).flag;
            if ~isempty(curr_index) % make sure the current element has other matches
                if numel(corr_patterns) >= curr_index && ~isempty(corr_patterns(curr_index).patterns)
                    cur_pattern = reshape(sensels{x,y},length_time,1);
                    cur_pattern = [cur_pattern(handles.time_shift_by{testcase}:end); cur_pattern(1:handles.time_shift_by{testcase})]; %whs time_shift_by is the time registration offset (matching the tekscan data with the input profile)
                    cur_pattern(range_of_interest) = lp_filter(cur_pattern(range_of_interest), frequency_sampling, frequency_cutoff);
                    % whs edited, 5/3/13...TC edited, 3/11/2017
                    current_pattern = cur_pattern(range_of_interest);
                    corr_patterns(curr_index).patterns{end+1} = current_pattern;
                    corr_patterns(curr_index).ncc_value(end+1) = char_curves(x,y).ncc_value;
                    corr_patterns(curr_index).patLoc(end+1) = sub2ind(size(sensels), x, y);
                    [ccr, lags] = nccr(current_pattern, corr_patterns(curr_index).patterns{1}, false);
                    corr_patterns(curr_index).shift(end+1) = lags(find(ccr == max(ccr),1,'first')); % whs, 5/5/2013 the time shift of two profiles at which the cross correlation was maximized.
                    corr_patterns(curr_index).corr_map(x,y) = 2.5+corr_patterns(curr_index).shift(end);
                    corr_patterns(curr_index).corr_map_amp(x,y) = max(current_pattern); % weight factor of the current sensel, whs added, 5/22/3013;
                else
                    cur_pattern = reshape(sensels{x,y},length_time,1);
                    cur_pattern = [cur_pattern(handles.time_shift_by{testcase}:end); cur_pattern(1:handles.time_shift_by{testcase})];
                    cur_pattern(range_of_interest) = lp_filter(cur_pattern(range_of_interest), frequency_sampling, frequency_cutoff);
                    current_pattern = cur_pattern(range_of_interest);
                    corr_patterns(curr_index).patterns{1} = current_pattern;
                    corr_patterns(curr_index).ncc_value(1) = char_curves(x,y).ncc_value;
                    corr_patterns(curr_index).patLoc(1) = sub2ind(size(sensels), x, y); %#ok<*AGROW>
                    corr_patterns(curr_index).shift(1) = 1;
                    corr_patterns(curr_index).corr_map = corr_map_template;
                    corr_patterns(curr_index).corr_map(x,y) = 2.5+corr_patterns(curr_index).shift(1);
                    corr_patterns(curr_index).corr_map_amp = corr_map_template;
                    corr_patterns(curr_index).corr_map_amp(x,y) = max(current_pattern);
                end
            else % keep patterns that have no other matches
                cur_pattern = reshape(sensels{x,y},length_time,1);
                cur_pattern = [cur_pattern(handles.time_shift_by{testcase}:end); cur_pattern(1:handles.time_shift_by{testcase})];
                cur_pattern(range_of_interest) = lp_filter(cur_pattern(range_of_interest), frequency_sampling, frequency_cutoff);
                current_pattern = cur_pattern(range_of_interest);
                if max(current_pattern) > str2double(get(handles.noise_floor_edit, 'String'))
                    flag_tracker = flag_tracker + 1;
                    corr_patterns(flag_tracker).patterns{1} = current_pattern;
                    corr_patterns(flag_tracker).ncc_value(1) = 1;
                    corr_patterns(flag_tracker).patLoc(1) = sub2ind(size(sensels), x, y);
                    corr_patterns(flag_tracker).shift(1) = 1;
                    corr_patterns(flag_tracker).corr_map = corr_map_template;
                    corr_patterns(flag_tracker).corr_map(x,y) = 2.5;
                    corr_patterns(flag_tracker).corr_map_amp = corr_map_template;
                    corr_patterns(flag_tracker).corr_map_amp(x,y) = max(current_pattern);
                end
            end
        end
    end
    
    for i = numel(corr_patterns):-1:1
        if isempty(corr_patterns(i).patterns) || numel(corr_patterns(i).patterns) < num_threshold
            corr_patterns(i) = [];
        end
    end
    
    if ~getappdata(h, 'canceling')
        set(handles.save_corr_data, 'Enable', 'on')
        set(handles.save_corr_maps, 'Enable', 'on')
        set(handles.corr_maps_button, 'Enable', 'on')
        set(handles.indiv_profiles_checkbox, 'Enable', 'on')
        set(handles.show_corr_map_overlay, 'Enable', 'on')
    end
    
    delete(h)
    
catch ME % if there is an error in finding cross-correlations, stores information about errors in ME class
    delete(h)
    rethrow(ME) % reissues any errors caught
end

ccr = corr_patterns; % returns correlation patterns