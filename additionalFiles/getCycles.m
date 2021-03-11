function [start_cycle, end_cycle] = getCycles(hObject, handles, max_cycles)

if strcmpi(get(hObject, 'checked'),'off');
    if max_cycles > 5 % If there is at least 6 cycles to average from
        start_cycle = 5; % use 5th to last cycle
        end_cycle = 2; % use 2nd to last cycle
    elseif max_cycles > 1 % if max_cycles is less than 6 but greater than 1
        start_cycle = max_cycles-1; % choose the second cycle as the start
        end_cycle = 2; % use second to last cycle as start
    end
else % if user has set the range of cycles to average
    start_cycle = handles.start_cycle;
    end_cycle = handles.end_cycle;
end