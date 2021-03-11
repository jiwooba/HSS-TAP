function [time_order, shift] = time_registration(hObject, handles, ~)
%% Register Intact and All Test Cases
for var_count = 1:handles.comparison
    if strcmp(get(handles.pattern_register, 'Checked'), 'off') % use first loaded tekscan data as reference
        results{var_count} = tekscan_time_registration(handles.force{var_count},handles.force{1},handles.window_size,2); %#ok<*AGROW> % stores results from cross-correlation time registration
    else % use loaded gait cycle as reference
        results{var_count} = tekscan_time_registration(handles.force{var_count},handles.gait_rep,handles.window_size,2); % stores results from cross-correlation time registration
    end
    
    % set up variables
    handles.time_order{var_count} = 1:handles.length_time;
    [row, col] = size(handles.time_order{var_count});
    
    % make sure time data is oriented in right direction
    if row>col 
        handles.time_order{var_count} = [handles.time_order{var_count}(results{var_count}.time_shift:end); handles.time_order{var_count}(1:results{var_count}.time_shift-1)];
    else
        handles.time_order{var_count} = [handles.time_order{var_count}(results{var_count}.time_shift:end) handles.time_order{var_count}(1:results{var_count}.time_shift-1)];
    end
    
    handles.time_shift_by{var_count} = results{var_count}.time_shift;
end

time_order = handles.time_order; % return matrix with element order
shift = handles.time_shift_by; % return shift determined by time registration