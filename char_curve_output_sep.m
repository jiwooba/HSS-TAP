clear; clc; close all;

% Add subfolder
addpath(['.' filesep 'additionalFiles']);

path = '/Users/txc/OneDrive/HSS DATA/Cartilage R01/Cadaveric Studies/Intact-ACLx_ROI/Norm_Corr_Maps/'; %Path location for below file
file = 'ACL_7knees_rel_T93.mat'; %mat-file containing the between knee matches

window_size = 500; %# of points per cycle (e.g. for 100 Hz sensor acquisition rate and a cycle time of 2 sec this value would be 200)
num_repeats = 1;  %# of cycles used for pattern matching (Default: 3)

min_crange = 0; %Minimum # of Knees to show on colorbar (NOTE: any value <= this # will be set to black)
max_crange = 7; %Total # of Knees to show on colorbar
cut_off = 2;    %# of knees sharing a pattern - used to dictate the cut off as to what should be considered a pattern

max_Mcrange = 6;    %Weighted Stress Max Value
Mcrange_step = 1; %Intervals between Weighted Stress colorbar labels

screensize = get(0, 'Screensize');    %get screen size
ss_multi = floor(screensize(3)/1280); %calculate screen size multiplication factor (size relative to 1280)
rel_abs = true;                       %DO NOT CHANGE (No longer look at absolute values for mean)

char_curves = load([path file]);

char_curves = char_curves.corr_patterns;

for index = 1:numel(char_curves)
    sum_templates = [];
    
    %whs edited, 4/28/13, only color to the sensels that has the same patterns for >=3 knees
    %TC edited, 4/15/2017, only show patterns with >= cut_off knees but show all sensels > min_crange
    rows = size(char_curves(index).corr_map,1);
    cols = size(char_curves(index).corr_map,2);
    if isempty(find((char_curves(index).corr_map >= cut_off*2.5)>0,1))
        continue; % if less than cutoff knees has the same pattern, then skip rest of current loop iteration and start next one
    end
    
    figure1 = figure;
    %% 1)---------------
    axes1 = axes('Parent',figure1);
    box(axes1,'off');
    surf(char_curves(index).corr_map/2.5);
    view([0 -90])
    grid off
    axis off
    axis equal
    cmap = [0 0 0; hsv(max_crange-min_crange)];
    colormap(cmap);
    % Create colorbar
    hcb = colorbar('peer',axes1, 'Ticks', min_crange+0.5:max_crange+0.5, 'TickLabels', min_crange:max_crange, 'TickLength', 0);
    set(hcb, 'YTickMode', 'manual')
    ax_pos = axes1.Position;
    hcb.Position(3) = 1.5*hcb.Position(3);
    axes1.Position = ax_pos;

    caxis([min_crange max_crange+1]);
    hcb.Label.String = '\fontsize{18}# of Knees';
    hcb.FontSize = 12;
    hcb.FontWeight = 'Bold';
    hcb.LineWidth = 1;

    %% 2)---------the weighted pcolor, consider both the number of knees
    %(sharing the same pattern) and the amplitude of the knees.
    for i = 1:length(char_curves(index).corr_map_amp)       
        if i == 1
            weighted_corr_map = char_curves(index).corr_map_amp{i};
        else
            cp_rows = size(weighted_corr_map,1);
            cp_cols = size(weighted_corr_map,2);
            ci_rows = size(char_curves(index).corr_map_amp{i},1);
            ci_cols = size(char_curves(index).corr_map_amp{i},2);
            rows_diff = cp_rows - ci_rows;
            cols_diff = cp_cols - ci_cols;
            
            rows_f = floor(abs(rows_diff)/2);
            rows_b = abs(rows_diff) - rows_f;
            cols_f = floor(abs(cols_diff)/2);
            cols_b = abs(cols_diff) - cols_f;
            
            if rows_diff < 0
                weighted_corr_map = padarray(weighted_corr_map, [rows_f 0], NaN, 'pre');
                weighted_corr_map = padarray(weighted_corr_map, [rows_b 0], NaN, 'post');
            elseif rows_diff > 0
                char_curves(index).corr_map_amp{i} = padarray(char_curves(index).corr_map_amp{i}, [rows_f 0], NaN, 'pre');
                char_curves(index).corr_map_amp{i} = padarray(char_curves(index).corr_map_amp{i}, [rows_b 0], NaN, 'post');
            end
            
            if cols_diff < 0
                weighted_corr_map = padarray(weighted_corr_map, [0 cols_f], NaN, 'pre');
                weighted_corr_map = padarray(weighted_corr_map, [0 cols_b], NaN, 'post');
            elseif cols_diff > 0
                char_curves(index).corr_map_amp{i} = padarray(char_curves(index).corr_map_amp{i}, [0 cols_f], NaN, 'pre');
                char_curves(index).corr_map_amp{i} = padarray(char_curves(index).corr_map_amp{i}, [0 cols_b], NaN, 'post');
            end
            
            weighted_corr_map = weighted_corr_map + char_curves(index).corr_map_amp{i};
        end
    end
    figure2 = figure;
    axes2 = axes('Parent',figure2);
    axis equal
    box(axes2,'on');
    weighted_corr_map = weighted_corr_map./(char_curves(index).corr_map/2.5);
    weighted_corr_map((char_curves(index).corr_map/2.5) < cut_off) = 0;
    w = surf(weighted_corr_map);
    view([0 -90])
    grid off
    axis off
    title('\fontsize{18}Weighted Maximum Stress Map');
    cmap = colormap(axes2, jet(6*max_Mcrange-1));
    cmap = [0 0 0; cmap];
    colormap(axes2, cmap);
    % Create colorbar
    hcb = colorbar('peer',axes2,'YTick', 0:Mcrange_step:max_Mcrange);
    set(hcb, 'YTickMode', 'manual')
    caxis(axes2, [0 max_Mcrange]);
    hcb.FontSize = 12;
    hcb.FontWeight = 'Bold';
    axis equal

    %-----------------END------------------
    
    
    %% 3) ------plot the relative pattern curves------
    %--- align the curves for plotting
    for corr_condense = 1:length(char_curves(index).patterns)
        if char_curves(index).shift(corr_condense) > 1
            aligned_range{corr_condense} = [char_curves(index).shift(corr_condense):window_size*num_repeats, 1:char_curves(index).shift(corr_condense)-1];
        else
            aligned_range{corr_condense} = [1:window_size*num_repeats];
        end
    end
    %---
    for corr_condense = 1:length(char_curves(index).patterns)
        sum_templates(:,corr_condense) = char_curves(index).patterns{corr_condense}(aligned_range{corr_condense});
    end
    figure3 = figure;
    subGraph = axes('Parent',figure3);
    %     framenos = length(char_curves(index).patterns{1});
%     sum_templates = convert100(sum_templates,[1:length(sum_templates)],100);
    sum_templates = convert100(sum_templates(1:window_size,:),1:window_size,100);
    framenos = size(sum_templates, 1);
    pattern_i = ones(size(sum_templates));
    for i = 1:size(sum_templates, 2)
        pattern_i(:,i) = sum_templates(1:framenos,i);
    end
    plot(pattern_i, 'linewidth', 0.5); hold on;
%     plot(mean(pattern_i,2),'k','linewidth',3);
%     plot(mean(pattern_i,2) + std(pattern_i,0,2),'--r','linewidth',1);
%     plot(mean(pattern_i,2) - std(pattern_i,0,2),'--r','linewidth',1);
    shadeGraph = shadedErrorBar(0:100, mean(pattern_i,2), std(pattern_i,0,2), '--r', 1);
    shadeGraph.mainLine.LineWidth = 1;
    shadedGraph.patch.FaceAlpha = 0.1;
    xlim(subGraph,[0 100]);
    ylim(subGraph,[0 1]);
    xlabel('\fontsize{16}% Gait');
    ylabel('\fontsize{16}Normalized Force');
    subGraph.LineWidth = 1;
    subGraph.FontWeight = 'bold';
    subGraph.FontSize = 12;
    title('\fontsize{16}Relative Char Curve');
    average_curve = mean(pattern_i,2);
    
    if rel_abs == 1
        %% 4) ------plot the pattern curves------------
        cell_id = find(char_curves(index).corr_map/2.5 >= cut_off); %find the sensels that have >= cut_off number of knees with same pattern
        corr_map_row = reshape(char_curves(index).corr_map/2.5, 1, rows*cols); %make the above map linear
        n_jj = 1; %number of repetition at the cell jj
        n_tol = 1; %the whole number of repetition, e.g. 2 knees has the same pattern at sensel 2, 
                  %3 knees has the same pattern at sensel 4, nn = 2 + 3 = 5;
        clear mean_amp weight_sample weight_sample_mean weight_std_mean x_jj delta_jj w_jj
        
       for jj = cell_id'
           %calculate the mean and std at each sensel, and then calculate the weighted average and standard derivation
           %http://en.wikipedia.org/wiki/Weighted_arithmetic_mean
           kk = 1;
           for i = 1:length(char_curves(index).corr_map_amp) %how many knees has this pattern index
               rows1 = size(char_curves(index).corr_map_amp{i},1);
               cols1 = size(char_curves(index).corr_map_amp{i},2);
               corr_map_amp_row = reshape(char_curves(index).corr_map_amp{i},1,rows1*cols1);
                if corr_map_amp_row(jj) > 0 %the knee has magnitude great than 0 at sensel-jj
                   mean_amp(kk,1:framenos) = corr_map_amp_row(jj)*average_curve(1:framenos); %multiply the normalized average by the current sensel amplitude
                   kk = kk + 1;
                   n_tol = n_tol + 1;
               end
           end
           x_jj(n_jj,:) = mean(mean_amp,1); %the mean at sensel-jj
           delta_jj(n_jj,:) = std(mean_amp,0,1);
           w_jj(n_jj) = kk - 1; %the number of repeated knees at the same sensel;
           n_jj = n_jj + 1;
       end
       w_jj = w_jj/(n_tol-1);
       for framenum = 1:framenos
           weight_sample_mean(framenum) = sum(w_jj'.*x_jj(:,framenum));
           weight_std_mean(framenum) = sqrt(sum((w_jj').*(delta_jj(:,framenum).^2))/(((n_tol-2)*sum(w_jj))/(n_tol-1)));
       end
       figure4 = figure;
       subGraph = axes('Parent',figure4);
%         plot(weight_sample_mean,'b','linewidth',3); hold on;
%         plot(weight_sample_mean + weight_std_mean,'--r','linewidth',1);
%         plot(weight_sample_mean - weight_std_mean,'--r','linewidth',1);
        shadeGraph = shadedErrorBar(0:100, weight_sample_mean, weight_std_mean, '--r', 1);
        shadeGraph.mainLine.LineWidth = 1;
        shadedGraph.patch.FaceAlpha = 0.1;
        ax = axis;
        xlim(subGraph,[0 100]);
        ylim(subGraph,[0 ax(4)]);
        xlabel('\fontsize{16}% Gait');
        ylabel('\fontsize{16}Stress [MPa]');
        subGraph.LineWidth = 1;
        subGraph.FontWeight = 'bold';
        subGraph.FontSize = 12;
        grid minor
        subGraph.MinorGridLineStyle = ':';
        subGraph.MinorGridAlpha = 0.1;
        title('\fontsize{16}Weighted Avg Char Curve w/ StDev');
    end

    if rel_abs == 1
        %% 4) ------plot the pattern curves------------
        cell_id = find(char_curves(index).corr_map/2.5 >= cut_off); %find the sensels that have >= cut_off number of knees with same pattern
        corr_map_row = reshape(char_curves(index).corr_map/2.5, 1, rows*cols); %make the above map linear
        n_jj = 1; %number of repetition at the cell jj
        n_tol = 1; %the whole number of repetition, e.g. 2 knees has the same pattern at sensel 2, 
                  %3 knees has the same pattern at sensel 4, nn = 2 + 3 = 5;
        clear mean_amp weight_sample_mean2 weight_CI x_jj delta_jj w_jj
        
       for jj = cell_id'
           %calculate the mean and std at each sensel, and then calculate the weighted average and standard derivation
           %http://en.wikipedia.org/wiki/Weighted_arithmetic_mean
           kk = 1;
           for i = 1:length(char_curves(index).patLoc) %how many knees has this pattern index
               locInd = find(char_curves(index).patLoc{i} == jj);
               if ~isempty(locInd)
                   mean_amp(kk,1:framenos) = convert100(char_curves(index).rawData{i}(aligned_range{i}(1:window_size),locInd),1:window_size,100); %store the sensel pattern for the current sensel location
                   kk = kk + 1;
                   n_tol = n_tol + 1;
               end
           end
           x_jj(n_jj,:) = mean(mean_amp,1); %the mean at sensel-jj
           delta_jj(n_jj,:) = std(mean_amp,0,1); %the stdev at sensel-jj
           w_jj(n_jj) = kk - 1; %the number of repeated knees at the same sensel;
           n_jj = n_jj + 1; %cycles to the next pattern index (can't use jj because contains discontinuous cell ids
       end
       w_jj = w_jj/(n_tol-1);
       for framenum = 1:framenos
           weight_sample_mean2(framenum) = sum(w_jj'.*x_jj(:,framenum));
           weight_CI(framenum) =1.96*sqrt(sum((w_jj').*(delta_jj(:,framenum).^2))/(((n_tol-1)*sum(w_jj))/n_tol))/sqrt(max(max(char_curves(index).corr_map/2.5)));
       end
       figure5 = figure;
       subGraph = axes('Parent',figure5);
%         plot(weight_sample_mean,'b','linewidth',3); hold on;
%         plot(weight_sample_mean + weight_std_mean,'--r','linewidth',1);
%         plot(weight_sample_mean - weight_std_mean,'--r','linewidth',1);
        shadeGraph = shadedErrorBar(0:100, weight_sample_mean2, weight_CI, '--r', 1);
        shadeGraph.mainLine.LineWidth = 1;
        shadedGraph.patch.FaceAlpha = 0.1;
        ax = axis;
        xlim(subGraph,[0 100]);
        ylim(subGraph,[0 ax(4)]);
        xlabel('\fontsize{16}% Gait');
        ylabel('\fontsize{16}Stress [MPa]');
        subGraph.LineWidth = 1;
        subGraph.FontWeight = 'bold';
        subGraph.FontSize = 12;
        grid minor
        subGraph.MinorGridLineStyle = ':';
        subGraph.MinorGridAlpha = 0.1;
        title('\fontsize{16}Weighted Avg Char Curve w/ 95% CI');
    end

    [cond, rem] = strtok(file, '_');
    [descrip, rem] = strtok(rem, '_');
    set(figure1, 'Position', [0 500 550 440], 'PaperPositionMode', 'auto');
    set(figure2, 'Position', [600 500 550 440], 'PaperPositionMode', 'auto');
    set(figure3, 'Position', [0 0 550 440], 'PaperPositionMode', 'auto');
    set(figure4, 'Position', [600 0 550 440], 'PaperPositionMode', 'auto');
    set(figure5, 'Position', [1200 0 550 440], 'PaperPositionMode', 'auto');

    print(figure1, '-dtiff', [path cond '_' descrip '_cc' num2str(index) '_KneeMap.tiff'], '-r300')
    print(figure2, '-dtiff', [path cond '_' descrip '_cc' num2str(index) '_WeightedMap.tiff'], '-r300')
    print(figure3, '-dtiff', [path cond '_' descrip '_cc' num2str(index) '_NormCurve.tiff'], '-r300')
    print(figure4, '-dtiff', [path cond '_' descrip '_cc' num2str(index) '_WeightedSTD.tiff'], '-r300')
    print(figure5, '-dtiff', [path cond '_' descrip '_cc' num2str(index) '_WeightedCI.tiff'], '-r300')
    
    dlmwrite([path cond '_' descrip '_cc' num2str(index) '_norm_corr_map.txt'], sum_templates/numel(char_curves(index).patterns));   
%     dlmwrite([path cond '_' descrip '_cc' num2str(index) '_curve.crv'],     x_jj', 'delimiter', '\t');
%     dlmwrite([path cond '_' descrip '_cc' num2str(index) '_weight_curve.crv'],     weight_sample', 'delimiter', '\t');
    dlmwrite([path cond '_' descrip '_cc' num2str(index) '_weight_STD.txt'], [weight_sample_mean', weight_std_mean']);
    dlmwrite([path cond '_' descrip '_cc' num2str(index) '_weight_CI.txt'], [weight_sample_mean2', weight_CI']);
    dlmwrite([path cond '_' descrip '_cc' num2str(index) '_weighted_max_map.txt'], weighted_corr_map);
    close(figure1, figure2, figure3, figure4, figure5);
end




























