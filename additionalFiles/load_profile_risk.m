function lpr = load_profile_risk(handles)

% calculates the pattern risk between each sensel for 2 tekscan outputs
length_time = handles.length_time;
window_size = handles.window_size;
max_cycles = floor(length_time/window_size);

elapsedtime = 0;
sensel_tracker = 0;

corr_map_template = handles.senselvar{1}(:,:,1);
corr_map_template(~isnan(corr_map_template)) = 0;

% get cycle range of interest to average
[start_cycle, end_cycle] = getCycles(handles.avg_data,handles,max_cycles);

% gets elements within the selected range of cycles
range_of_interest = handles.window_size*(max_cycles-start_cycle)+1:handles.window_size*(max_cycles-end_cycle)+window_size; %edited by Hongsheng, 5/3/13 *Originally 4 & 1
num_of_cycle = length(range_of_interest)/window_size;

% create progress bar
h = waitbar(0,'Comparing Sensels...','Name','Calculating Load Profile Risk Map',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');

setappdata(h,'canceling',0)

tic % start process timer

try % catch any errors
    for var_count_outer = 1:handles.comparison % 1st tekscan map to compare
        for var_count_inner = 1:handles.comparison % 2nd tekscan map to compare
            
            if var_count_outer <= var_count_inner
                for x = 1:size(handles.sensels{1},1)
                    for y = 1:size(handles.sensels{1},2)
                        %reorganize 
                        template = reshape(handles.sensels{var_count_outer}{x,y},length_time,1);
                        test_template = reshape(handles.sensels{var_count_inner}{x,y},length_time,1);
                        template = template(handles.time_order{var_count_outer});
                        test_template = test_template(handles.time_order{var_count_inner});
                        
                        if ~max(isnan(test_template)) && ~max(isnan(template))
                            if max(max(template))>str2double(get(handles.noise_floor_edit, 'String')) || max(max(test_template))>str2double(get(handles.noise_floor_edit, 'String'))
                                
                                %average cycles for each sensel
                                test_tempAvg = test_template(range_of_interest(1):range_of_interest(window_size));
                                tempAvg = template(1:window_size);
                                for avg_ccrs = 1:num_of_cycle-1
                                    test_tempAvg = test_tempAvg + test_template(range_of_interest(avg_ccrs*window_size+1):range_of_interest(avg_ccrs*window_size+window_size));
                                    tempAvg = tempAvg + template(avg_ccrs*window_size+1:(avg_ccrs*window_size+window_size));
                                end
                                test_tempAvg = test_tempAvg/num_of_cycle;
                                tempAvg = tempAvg/num_of_cycle;

                                [ccr, lag] = nccr(test_tempAvg, tempAvg, false);
                                if ~isnan(ccr)
                                    corr_map{var_count_outer,var_count_inner}(x,y) = 1-ccr(lag==0); %#ok<*AGROW>
                                else
                                    corr_map{var_count_outer,var_count_inner}(x,y) = 1;
                                end
                            else
                                corr_map{var_count_outer,var_count_inner}(x,y) = 0;
                            end
                        else
                            corr_map{var_count_outer,var_count_inner}(x,y) = 0;
                        end
                        
                        if getappdata(h,'canceling')
                            break
                        end
                                               
                        elapsedtime = elapsedtime + toc; % get elapsed time
                        
                        tic
                        sensel_tracker = sensel_tracker+1;
                        if mod(sensel_tracker, 50)==0
                            waitbar(sensel_tracker / (size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2),h,['Time Remaining: ' sprintf('%i',floor((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime),3600)/60)) ':' sprintf('%02.4f',rem(rem((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime),3600),60))...
                                sprintf('     Time Elapsed: ') sprintf('%i',floor(elapsedtime/3600)) ':' sprintf('%i',floor(rem(elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem(elapsedtime,3600),60))])
                        end
                    end
                end
                corr_map{var_count_outer,var_count_inner} = corr_map{var_count_outer,var_count_inner} + corr_map_template;
            else
                corr_map{var_count_outer,var_count_inner} = corr_map{var_count_inner, var_count_outer};
                
                if getappdata(h,'canceling')
                    break
                end
                
                elapsedtime = elapsedtime + toc;
                tic
                sensel_tracker = sensel_tracker+1;
                if mod(sensel_tracker, 50)==0
                    waitbar(sensel_tracker / (size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2),h,['Time Remaining: ' sprintf('%i',floor((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime),3600)/60)) ':' sprintf('%02.4f',rem(rem((elapsedtime/sensel_tracker*(size(handles.sensels{1},1)*size(handles.sensels{1},2)*handles.comparison^2)-elapsedtime),3600),60))...
                        sprintf('     Time Elapsed: ') sprintf('%i',floor(elapsedtime/3600)) ':' sprintf('%i',floor(rem(elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem(elapsedtime,3600),60))])
                end
            end
        end
    end
    
    lpr = corr_map; % return pattern difference maps
    
    delete(h); % delete progress bar

catch ME % store thrown error in ME
    delete(h); % delete progress bar
    rethrow(ME); % reshow error
end