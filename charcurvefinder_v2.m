% So you want to put the two files in the same directory as the rest of the
% code for the tekscan program since it uses some of the functions.  
% Run the program “charcurvefinder.m” first to find all characteristic curves.
% After the program is done running you have to right click on the variable
% “corr_patterns” and then save it as a mat file.  The program 
% “char_curve_output.m” just outputs the figures and saves them.
clc; clear;

% Add subfolder
addpath(['.' filesep 'additionalFiles']);

repeats = 1;
window_size = 500; %number of points that constitute one cycle of data
num_cycles = 1; %number of cycles saved
threshold_value = 0.93; %threshold value
counter = 1;
tracker = 0;
rel_abs = 1; 

corr_patterns(1).patterns = {};
corr_patterns(1).ncc_value = [];
corr_patterns(1).shift = [];
corr_patterns(1).knee = [];
corr_patterns(1).sample = [];

%%--------location of individual pattern files----------
location2 = '/Users/txc/OneDrive/HSS DATA/Cartilage R01/Cadaveric Studies/Intact-ACLx_ROI/Norm_Corr_Maps/';
fold2 = '/ACL';
kneeID = {'Knee 01','Knee 02', 'Knee 03'...
    'Knee 04', 'Knee 05', 'Knee 06'...
    'Knee 07'...
    };

sub_file = ['_' num2str(numel(kneeID)) 'knees_rel_T' num2str(threshold_value*100) '.mat'];

while counter <=  size(kneeID,2)
    t = [location2, kneeID{counter}, fold2];
    currdir{counter}.folder = t;
    if rel_abs ==1
        txtfiles = dir(fullfile(currdir{counter}.folder, '*.rel')); %relative stress curves
    else
        txtfiles = dir(fullfile(currdir{counter}.folder, '*.txt')); %absolute stress curves
    end
    currdir{counter}.txtfiles = txtfiles;  %#ok<*SAGROW>
    currdir{counter}.txtfiles(1).ncc_value = [];
    currdir{counter}.txtfiles(1).flag = [];
    currdir{counter}.shift = 1;
    
    rightleft{counter} = 'Left'; %because there is no differences
    
    counter = counter + 1;
end

disp('Performing Matching...');
% Nested for loops to set each file as the template
for i = 1:numel(currdir)
    for j = 1:numel(currdir{i}.txtfiles)
        template = dlmread([currdir{i}.folder filesep currdir{i}.txtfiles(j).name]); % read in template
        % Nested for loops to set each file as comparison
        for k = 1:numel(currdir)
            for l = 1:numel(currdir{k}.txtfiles)
%                 if  i ~= k % make sure not comparing within the same knee
                    curr_file = dlmread([currdir{k}.folder filesep currdir{k}.txtfiles(l).name]);  % read in comparison   
                    cat_curr_file = curr_file(1:window_size);
                    cat_template = template(1:window_size);
                    for m_files = 1:num_cycles-1
                        cat_curr_file(:, m_files) = curr_file((m_files-1)*window_size+1:m_files*window_size);
                        cat_template(:, m_files) = template((m_files-1)*window_size+1:m_files*window_size);
                    end
                    [ccr_truncated, lag] = nccr(mean(cat_curr_file,2), mean(cat_template,2), false); % compare template vs comparison using normalized cross-correlation
                    
%                           %%%Plot all sensels normalized max value to 1 (blue is template)%%%
%                           %%%Uncomment to plot data compared%%%
%                                 figure(199)
%                                 subplot(2,1,1)
%                                 plot((template-mean(template))/std(template))
%                                 hold on
%                                 plot((curr_file-mean(curr_file))/std(curr_file))
%                                 hold off
%                                 title(['Knee: ' num2str(i) ' File: ' num2str(j) '  Compared to Knee:' num2str(k) ' File: ' num2str(l)]);
%                                 subplot(2,1,2)
%                                 plot(ccr_truncated)
%                                 title(['Correlation: ' num2str(max(ccr_truncated))]);
%                                 ylim([0 1])
%                                 pause(0.5)

                    if length(ccr_truncated(ccr_truncated>threshold_value)) >= 1 % make sure that there is a correlation value >= to the threshold value set
%                         disp([num2str(max(ccr_truncated)*100) ' Match between Knee ' num2str(i) ' ' currdir{i}.txtfiles(j).name ' and Knee ' num2str(k) ' ' currdir{k}.txtfiles(l).name])
                        if ~isempty(currdir{i}.txtfiles(j).ncc_value) %Make sure there is a value stored in ncc_value variable of current template
                            if ~isempty(currdir{k}.txtfiles(l).ncc_value) %Make sure there is a value stored in ncc_value variable of the current comparison
                                if currdir{k}.txtfiles(l).ncc_value < max(ccr_truncated) %If the ncc_value value is less than the max correlation value found between current template and comparison set the ncc_value of the current comparison to the max correlation value
                                    currdir{k}.txtfiles(l).ncc_value = max(ccr_truncated); %Set ncc_value of current comparison to the max correlation value
                                    currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag; %Set the flag (ID) value to the flag value of the template
%                                     disp(['1 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
                                else
                                    %do nothing
                                end
                            else
                                currdir{k}.txtfiles(l).ncc_value = max(ccr_truncated);
                                currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag;
%                                 disp(['2 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
                            end
                        else
                            if ~isempty(currdir{k}.txtfiles(l).ncc_value)
                                if currdir{k}.txtfiles(l).ncc_value <= max(ccr_truncated)
                                    tracker = tracker + 1;
                                    currdir{i}.txtfiles(j).ncc_value = max(ccr_truncated);
                                    currdir{i}.txtfiles(j).flag = tracker;
                                    currdir{k}.txtfiles(l).ncc_value = max(ccr_truncated);
                                    currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag;
%                                     disp(['3 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
                                else
                                    %do nothing, because the correlation is not as strong as the previous one
                                end
                            else
                                tracker = tracker + 1;
                                currdir{i}.txtfiles(j).ncc_value = max(ccr_truncated);
                                currdir{i}.txtfiles(j).flag = tracker;
                                currdir{k}.txtfiles(l).ncc_value = max(ccr_truncated);
                                currdir{k}.txtfiles(l).flag = tracker;
%                                 disp(['4 Storing in... ' num2str(tracker)])
                            end
                        end
                    end
%                 end
            end
        end
    end
end

% for i = 1:numel(currdir)
%     for j = 1:numel(currdir{i}.txtfiles)
%         template = dlmread([currdir{i}.folder filesep currdir{i}.txtfiles(j).name]);
%         for k = 1:numel(currdir)
%             for l = 1:numel(currdir{k}.txtfiles)
%                 if  i ~= k
%                     curr_file = dlmread([currdir{k}.folder filesep currdir{k}.txtfiles(l).name]);
%                     ccr_truncated = nccr(curr_file, template, false);
%                     
%                     if length(ccr_truncated(ccr_truncated>threshold_value)) >= 1
%                         disp([num2str(max(ccr_truncated)*100) ' Match between Knee ' num2str(i) ' ' currdir{i}.txtfiles(j).name ' and Knee ' num2str(k) ' ' currdir{k}.txtfiles(l).name])
%                         
%                         if ~isempty(currdir{i}.txtfiles(j).ncc_value)
%                             if currdir{i}.txtfiles(j).ncc_value <= max(ccr_truncated)
%                                 if ~isempty(currdir{k}.txtfiles(l).ncc_value)
%                                     if currdir{i}.txtfiles(j).ncc_value >= currdir{k}.txtfiles(l).ncc_value
%                                         currdir{k}.txtfiles(l).ncc_value = currdir{i}.txtfiles(j).ncc_value;
%                                         currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag;
%                                         disp(['1 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
%                                     elseif currdir{i}.txtfiles(j).ncc_value < currdir{k}.txtfiles(l).ncc_value
%                                         currdir{i}.txtfiles(j).ncc_value = currdir{k}.txtfiles(l).ncc_value;
%                                         currdir{i}.txtfiles(j).flag = currdir{k}.txtfiles(l).flag;
%                                         disp(['2 Storing in... ' num2str(currdir{k}.txtfiles(l).flag)])
%                                     end
%                                 else
%                                     currdir{k}.txtfiles(l).ncc_value = currdir{i}.txtfiles(j).ncc_value;
%                                     currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag;
%                                     disp(['3 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
%                                 end
%                             else
%                                 currdir{k}.txtfiles(l).ncc_value = currdir{i}.txtfiles(j).ncc_value;
%                                 currdir{k}.txtfiles(l).flag = currdir{i}.txtfiles(j).flag;
%                                 disp(['4 Storing in... ' num2str(currdir{i}.txtfiles(j).flag)])
%                             end
%                         else
%                             tracker = tracker + 1;
%                             currdir{i}.txtfiles(j).ncc_value = max(ccr_truncated);
%                             currdir{i}.txtfiles(j).flag = tracker;
%                             currdir{k}.txtfiles(l).ncc_value = max(ccr_truncated);
%                             currdir{k}.txtfiles(l).flag = tracker;
%                             disp(['5 Storing in... ' num2str(tracker)])
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end

disp('Sorting...')
for i = 1:numel(currdir)
    for j = 1:numel(currdir{i}.txtfiles)
        curr_index = currdir{i}.txtfiles(j).flag;
%         amplitudes = dlmread([currdir{i}.folder filesep currdir{i}.ampfiles(j).name]); %the amplitude of each sencell within one knee with the same loading pattern.
        if ~isempty(curr_index)
            if numel(corr_patterns) >= curr_index && ~isempty(corr_patterns(curr_index).patterns)
%                 disp(['Adding to ' num2str(curr_index)])
                current_pattern = dlmread([currdir{i}.folder filesep currdir{i}.txtfiles(j).name]);
                corr_patterns(curr_index).patterns{end+1} = repmat(current_pattern, repeats,1);
                corr_patterns(curr_index).ncc_value(end+1) = currdir{i}.txtfiles(j).ncc_value;
%                 [ccr lags] = xcorr(corr_patterns(curr_index).patterns{1}, current_pattern,'coeff');
                [ccr, lags] = nccr(current_pattern, corr_patterns(curr_index).patterns{1}, false);
                [~, I] = max(ccr);
                if lags(I) <= 0
                    corr_patterns(curr_index).shift(end+1) = window_size+lags(I);
                else
                    corr_patterns(curr_index).shift(end+1) = lags(I);
                end
%                 corr_patterns(curr_index).shift(end+1) = lags(find(ccr == max(ccr))); %whs, 5/5/2013 the time shift of two profiles at which the cross correlation was maximized.
                corr_patterns(curr_index).knee(end+1) = i;
                corr_patterns(curr_index).sample(end+1) = j;
                [token, rem] = strtok(currdir{i}.txtfiles(j).name, '.');
                corr_patterns(curr_index).patLoc{end+1} = dlmread([currdir{i}.folder filesep token '.ind']);
                corr_patterns(curr_index).rawData{end+1} = dlmread([currdir{i}.folder filesep token '.raw']);
                curr_import_pattern = dlmread([currdir{i}.folder filesep token '.map']);
                cp_rows = size(corr_patterns(curr_index).corr_map,1);
                cp_cols = size(corr_patterns(curr_index).corr_map,2);
                ci_rows = size(curr_import_pattern,1);
                ci_cols = size(curr_import_pattern,2);
                rows_diff = cp_rows - ci_rows;
                cols_diff = cp_cols - ci_cols;
                
                rows_f = floor(abs(rows_diff)/2);
                rows_b = abs(rows_diff) - rows_f;
                cols_f = floor(abs(cols_diff)/2);
                cols_b = abs(cols_diff) - cols_f;
                
                if rows_diff < 0
                    corr_patterns(curr_index).corr_map = padarray(corr_patterns(curr_index).corr_map, [rows_f 0], NaN, 'pre');
                    corr_patterns(curr_index).corr_map = padarray(corr_patterns(curr_index).corr_map, [rows_b 0], NaN, 'post');                  
                elseif rows_diff > 0
                    curr_import_pattern = padarray(curr_import_pattern, [rows_f 0], NaN, 'pre');
                    curr_import_pattern = padarray(curr_import_pattern, [rows_b 0], NaN, 'post');
                end
                
                if cols_diff < 0
                    corr_patterns(curr_index).corr_map = padarray(corr_patterns(curr_index).corr_map, [0 cols_f], NaN, 'pre');
                    corr_patterns(curr_index).corr_map = padarray(corr_patterns(curr_index).corr_map, [0 cols_b], NaN, 'post');
                elseif cols_diff > 0
                    curr_import_pattern = padarray(curr_import_pattern, [0 cols_f], NaN, 'pre');
                    curr_import_pattern = padarray(curr_import_pattern, [0 cols_b], NaN, 'post');
                end
                
                curr_import_pattern(abs(curr_import_pattern)>0) = 2.5;
                corr_patterns(curr_index).corr_map = corr_patterns(curr_index).corr_map + curr_import_pattern;
                
                if rel_abs ==1
                   curr_import_amplitude = dlmread([currdir{i}.folder filesep token '.amp']); 
                   corr_patterns(curr_index).corr_map_amp{end + 1} = curr_import_amplitude;
                end
%                 corr_patterns(curr_index).corr_map_weight = (x,y)
            else
                disp(['Creating ' num2str(curr_index)])
                corr_patterns(curr_index).patterns{1} = repmat(dlmread([currdir{i}.folder filesep currdir{i}.txtfiles(j).name]),repeats,1);
                corr_patterns(curr_index).ncc_value(1) = currdir{i}.txtfiles(j).ncc_value;
                corr_patterns(curr_index).shift(1) = 1;
                corr_patterns(curr_index).knee(1) = i;
                corr_patterns(curr_index).sample(1) = j;
                [token, rem] = strtok(currdir{i}.txtfiles(j).name, '.');
                corr_patterns(curr_index).patLoc{1} = dlmread([currdir{i}.folder filesep token '.ind']);
                corr_patterns(curr_index).rawData{1} = dlmread([currdir{i}.folder filesep token '.raw']);
                curr_import_pattern = dlmread([currdir{i}.folder filesep token '.map']);
                curr_import_pattern(abs(curr_import_pattern)>0) = 2.5;
                corr_patterns(curr_index).corr_map = curr_import_pattern;
                if rel_abs ==1
                   curr_import_amplitude = dlmread([currdir{i}.folder filesep token '.amp']); 
                   corr_patterns(curr_index).corr_map_amp{1} = curr_import_amplitude;
                end
            end
        end
    end
end

for i = numel(corr_patterns):-1:1
    if isempty(corr_patterns(i).patterns)
        corr_patterns(i) = [];
    end
end

save([location2 fold2 sub_file],'corr_patterns');

disp([num2str(numel(corr_patterns)) ' Found'])