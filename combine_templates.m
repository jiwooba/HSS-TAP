function [ccr comb_char_curves] = combine_templates(char_curves, window_size, corr_thresh)
% Pre: Input the struct containing the characteristic curve data, the window_size
%      of the template and the threshold value.
%Post: Outputs struct containing the characteristic curve data with
%      correlation maps and individual templates (ccr) & combined
%      characteristic loading curves (comb_char_curves) & remaining curves

%% Initialize Variables
threshold_value = corr_thresh; %store set threshold value
tracker = 1; %Used to keep count of the number of found templates
template_tracker = 0; %Used to keep track of progress for waitbar
comb_char(1).templates = {}; %Initialize structure and cell array to store found template matches
no_comb_char(1).templates = {};
no_comb_char(1).corr_maps = {};
no_comb_char(1).x = {};
no_comb_char(1).y = {};
no_comb_char(1).offset = [];
no_comb_char_tracker = 0;

%% Initialize Waitbar
elapsedtime = 0;

h = waitbar(0,'Comparing Templates...','Name','Finding Characteristic Loading Patterns',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

%% Matches Loading Patterns to Find Characteristic Templates
for m = 1:length(char_curves)
    for n = 1:length(char_curves)
        tic
        % Calls nccr to calculate the cross-correlation between the
        % template and the last 5 load patterns
        ccr = nccr(char_curves(n).template, char_curves(m).template(end-3*window_size+1:end-2*window_size), false);
        
        [row, col] = find(ccr == max(ccr), 1,'first');
        
        % makes sure that the calculated cross-correlation has 3 points
        % greater than the threshold value and that the template isn't
        % being compared to itself
        ccr_truncated = ccr;
        if length(ccr_truncated(ccr_truncated>threshold_value))>=3 && m ~= n
            % If the cross-correlation comparison threshold is met check to
            % see if the flag value is set (>0) for the template
            if (char_curves(m).flag)==0
                % If the flag is not set see if the flag for the compared
                % pattern is set... if it is set the flag of the template
                % to the flag of the compared load pattern otherwise 
                % create a new characteristic pattern
                if (char_curves(n).flag)>0 && char_curves(n).maxcorr >= char_curves(m).maxcorr
                    char_curves(m).flag = char_curves(n).flag;
                    char_curves(m).maxcorr = mean(ccr(ccr>threshold_value));
                    char_curves(m).offset = col;
                else
                    char_curves(n).flag = tracker;
                    char_curves(n).maxcorr = mean(ccr(ccr>threshold_value));
                    char_curves(n).offset = col;
                    char_curves(m).offset = col;
                    tracker = tracker + 1;
                end
            % If the flag is already set for the template make sure that
            % the correlation value currently stored is maximal otherwise
            % set the template to the flag of the compared load pattern
            % if not set the compared load patterns flag to the flag of the
            % template
            elseif (char_curves(n).flag)>0 && char_curves(n).maxcorr >= char_curves(m).maxcorr
                char_curves(m).flag = char_curves(n).flag;
                char_curves(m).maxcorr = mean(ccr(ccr>threshold_value));
                char_curves(m).offset = col;
            else
                char_curves(n).flag = char_curves(m).flag;
                char_curves(n).maxcorr = mean(ccr(ccr>threshold_value));
                char_curves(n).offset = col;
            end
        end
        % Check to make sure that the 'Cancel' button on the waitbar has
        % not been pressed
        if getappdata(h,'canceling')
            break
        end
        % Update the waitbar
        comp_time = toc;
        elapsedtime = elapsedtime + toc;
        template_tracker = template_tracker + 1;
        if mod(template_tracker, 20)==0
            track_time = elapsedtime/template_tracker*(length(char_curves)^2);
            waitbar(template_tracker / (length(char_curves)^2),h,['Time Remaining: ' sprintf('%i',floor((track_time-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((track_time)-elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem((track_time)-elapsedtime,3600),60))...
                sprintf('     Characteristic Curves Found: ') sprintf('%i',tracker)])
        end
    end
    % Check to make sure that the 'Cancel' button on the waitbar has
    % not been pressed
    if getappdata(h,'canceling')
        break
    end
end

%% Sorts and Stores the Characteristic Curves

% Check to make sure that the 'Cancel' button on the waitbar has
% not been pressed
if ~getappdata(h, 'canceling')
    % Go through the found characteristic curves
    for m = 1:length(char_curves)
        % Check that the length of the struct comb_char is larger than the
        % flag value of the current found characteristic curve and that the
        % flag is not equal to 0
        if length(comb_char)>=char_curves(m).flag && char_curves(m).flag ~= 0
            % Stores the template, correlation map and the sensel x and y
            % coordinates in the structure comb_char in the corresponding
            % flag location
            if ~isempty(comb_char(char_curves(m).flag).templates)
                comb_char(char_curves(m).flag).templates{length(comb_char(char_curves(m).flag).templates)+1} = char_curves(m).template;
                comb_char(char_curves(m).flag).corr_maps{length(comb_char(char_curves(m).flag).templates)} = char_curves(m).corr_map;
                comb_char(char_curves(m).flag).x{length(comb_char(char_curves(m).flag).templates)} = char_curves(m).x;
                comb_char(char_curves(m).flag).y{length(comb_char(char_curves(m).flag).templates)} = char_curves(m).y;
                curr_template = comb_char(char_curves(m).flag).templates{length(comb_char(char_curves(m).flag).templates)};
                ccr = nccr(comb_char(char_curves(m).flag).templates{1}, curr_template(length(curr_template)-2*window_size+1:end), false);                
                [row, col] = find(ccr >= max(ccr), 1,'first');
                comb_char(char_curves(m).flag).offset(length(comb_char(char_curves(m).flag).templates)) = col;
            else
                comb_char(char_curves(m).flag).templates{1} = char_curves(m).template;
                comb_char(char_curves(m).flag).corr_maps{1} = char_curves(m).corr_map;
                comb_char(char_curves(m).flag).x{1} = char_curves(m).x;
                comb_char(char_curves(m).flag).y{1} = char_curves(m).y;
                comb_char(char_curves(m).flag).offset(1) = 1;
%                 comb_char(char_curves(m).flag).offset{1} = char_curves(m).offset;
           end
        elseif char_curves(m).flag ~= 0
            comb_char(char_curves(m).flag).templates{1} = char_curves(m).template;
            comb_char(char_curves(m).flag).corr_maps{1} = char_curves(m).corr_map;
            comb_char(char_curves(m).flag).x{1} = char_curves(m).x;
            comb_char(char_curves(m).flag).y{1} = char_curves(m).y;
%             comb_char(char_curves(m).flag).offset{1} = char_curves(m).offset;
            comb_char(char_curves(m).flag).offset(1) = 1;
%         else
%             no_comb_char_tracker = no_comb_char_tracker + 1;
%             no_comb_char(no_comb_char_tracker).templates{end+1} = char_curves(m).template;
%             no_comb_char(no_comb_char_tracker).corr_maps{end+1} = char_curves(m).corr_map;
%             no_comb_char(no_comb_char_tracker).x{end+1} = char_curves(m).x;
%             no_comb_char(no_comb_char_tracker).y{end+1} = char_curves(m).y;
%             no_comb_char(no_comb_char_tracker).offset(end+1) = 1;            
        end
    end
    
    % Store the sorted data and remove the characteristic curves with no
    % matches
    counter = 1;
    for p = 1:length(comb_char)
        if ~isempty(comb_char(p).templates)
            comb_char_curves(counter).templates = comb_char(p).templates;
            comb_char_curves(counter).corr_map = comb_char(p).corr_maps;
            comb_char_curves(counter).x = comb_char(p).x;
            comb_char_curves(counter).y = comb_char(p).y;
            comb_char_curves(counter).offset = comb_char(p).offset;
            counter = counter+1;
        end
    end
    ccr = char_curves;
%     no_comb_char_curves = no_comb_char;
end
%Remove the waitbar
delete(h)

end