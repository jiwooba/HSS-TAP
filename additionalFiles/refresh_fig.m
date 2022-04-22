function refresh_fig(hObject, handles)
set(handles.run, 'Enable', 'on'); % allow user to run common pattern analysis

%% Initialization
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
selected_condition = get(handles.condition_selector, 'Value');

if strcmp(get(handles.avg_data, 'Checked'), 'on') % Use average data
    senselvar = handles.avg_senselvar;
    time_order = handles.avg_time_order;
    force = handles.avg_force;
    time = handles.avg_time;
    if  handles.mag_calced
        magnitude_risk = handles.avg_magnitude_risk;
    end
else % Use all cycle data
    senselvar = handles.senselvar;
    time_order = handles.time_order;
    force = handles.force;
    time = handles.tekvar{selected_condition}.data_a.time;
    if  handles.mag_calced
        magnitude_risk = handles.magnitude_risk;
    end
end

% determine proper scaling factor
switch handles.tekvar{selected_condition}.header.dUnits
    case 'mm'
        fScale = 1;
    case 'cm' % convert cm to mm
        fScale = 10;
    case 'm' % convert m to mm
        fScale = 1000;
end

%% Convert all data to mm
row_space = handles.tekvar{selected_condition}.header.row_spacing*fScale;
col_space = handles.tekvar{selected_condition}.header.col_spacing*fScale;
sensel_area = row_space*col_space;
% force{selected_condition} = force{selected_condition} * fScale^2;

%% Removal all data currently plotted in GUI window
delete(handles.pressure_map.Children)
hold(handles.pressure_map, 'on')

%% Plot Pressure Map Data
if ~get(handles.risk_map_checkbox, 'Value') % plot stress data
    if handles.comparison > 1
        set(handles.pressure_map_slider, 'Visible', 'on');
        set(handles.risk_type_dropdown, 'Visible', 'off');
        set(handles.comparison_selector, 'Visible', 'off');
    end
    
    if strcmp(get(handles.surf_on, 'Checked'), 'on') % plot using surface map
        curr_plot_handle = surf(handles.pressure_map, senselvar{selected_condition}(:,:,time_order{selected_condition}(index))); %creates a contour map of the current plateau with time
        view(2);
    elseif strcmp(get(handles.contour_on, 'Checked'), 'off') % plot using pcolor
        curr_plot_handle = pcolor(handles.pressure_map, senselvar{selected_condition}(:,:,time_order{selected_condition}(index))); %creates a map of the current plateau with time
    else % plot using contour map
        [~, curr_plot_handle] = contourf(handles.pressure_map, senselvar{selected_condition}(:,:,time_order{selected_condition}(index)),90, 'LineStyle', 'none'); %creates a interpolated contour map of the current plateau with time
    end
    % format plot
    set(curr_plot_handle, 'HitTest', 'off');
    handles.curr_plot = senselvar{selected_condition}(:,:,time_order{selected_condition}(index));
    set(handles.pressure_map, 'XTick', 0:2:(handles.tekvar{selected_condition}.header.cols+1))
    set(handles.pressure_map, 'YTick', 0:2:(handles.tekvar{selected_condition}.header.rows+1))
    xlim(handles.pressure_map, [0 handles.tekvar{selected_condition}.header.cols+1]);
    ylim(handles.pressure_map, [0 handles.tekvar{selected_condition}.header.rows+1]);
    set(handles.pressure_map, 'YDir', 'reverse');
    
    % set color map
    cmap = colormap(handles.pressure_map, jet(255));
    cmap = [0 0 0; cmap];
    colormap(handles.pressure_map, cmap);
    caxis(handles.pressure_map, [handles.min_crange handles.max_crange]);    
    grid(handles.pressure_map, 'off')
else % plot a comparison group
    set(handles.risk_type_dropdown, 'Visible', 'on');
    set(handles.comparison_selector, 'Visible', 'on');

    selected_comparison = get(handles.comparison_selector, 'Value');
    
    switch get(handles.risk_type_dropdown, 'Value')
        case 1 % magnitude comparison between two conditions
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, magnitude_risk{selected_condition, selected_comparison}(:,:,index));
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
                view(2);
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, magnitude_risk{selected_condition, selected_comparison}(:,:,index));
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, magnitude_risk{selected_condition, selected_comparison}(:,:,index), 90, 'LineStyle', 'none');
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2):floor(255/2)+1,:) = [0 0 0; 0 0 0];
            end
            
            set(curr_plot_handle, 'HitTest', 'off');
            handles.curr_plot = magnitude_risk{selected_condition, selected_comparison}(:,:, index);
            caxis(handles.pressure_map, [-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
            colormap(handles.pressure_map, cmap);
            set(handles.pressure_map_slider, 'Visible', 'on');
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
        case 2 % Plot max stress differences between two conditions
            mag_risk_total = max(magnitude_risk{selected_condition, selected_comparison},[],3);
            
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, mag_risk_total);
                view(2);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, mag_risk_total);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, mag_risk_total, 90, 'LineStyle', 'none');
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2):floor(255/2)+1,:) = [0 0 0; 0 0 0];
            end
            
            set(curr_plot_handle, 'HitTest', 'off');
            handles.curr_plot = mag_risk_total;
            caxis(handles.pressure_map, [-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
            colormap(handles.pressure_map, cmap);
            set(handles.pressure_map_slider, 'Visible', 'off');
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
        case 3 % Plot min stress differences between two conditions
            mag_risk_total = min(magnitude_risk{selected_condition, selected_comparison},[],3);
            
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, mag_risk_total);
                view(2);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, mag_risk_total);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, mag_risk_total, 90, 'LineStyle', 'none');
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2):floor(255/2)+1,:) = [0 0 0; 0 0 0];
            end
            set(curr_plot_handle, 'HitTest', 'off');
            handles.curr_plot = mag_risk_total;
            caxis(handles.pressure_map, [-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
            colormap(handles.pressure_map, cmap);
            set(handles.pressure_map_slider, 'Visible', 'off');
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
        case 4 % Plot max/min stress differences between two conditions
            max_mag_risk = max(magnitude_risk{selected_condition, selected_comparison},[],3);
            min_mag_risk = min(magnitude_risk{selected_condition, selected_comparison},[],3);
            mag_risk_total = magnitude_risk{selected_condition, selected_comparison}(:,:,1);
            mag_risk_total(abs(max_mag_risk)>abs(min_mag_risk)) = max_mag_risk(abs(max_mag_risk)>abs(min_mag_risk));
            mag_risk_total(abs(max_mag_risk)<=abs(min_mag_risk)) = min_mag_risk(abs(max_mag_risk)<=abs(min_mag_risk));
            
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, mag_risk_total(end:-1:1,:));
                view(2);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, mag_risk_total);
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2)+1,:) = [0 0 0];
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, mag_risk_total, 90, 'LineStyle', 'none');
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2):floor(255/2)+1,:) = [0 0 0; 0 0 0];
            end
            
            set(curr_plot_handle, 'HitTest', 'off');
            handles.curr_plot = mag_risk_total;
            caxis(handles.pressure_map, [-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
            colormap(handles.pressure_map, cmap);
            set(handles.pressure_map_slider, 'Visible', 'off');
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
        case 5 % pattern comparison between two conditions
            load_risk = handles.load_risk{selected_condition, selected_comparison};
            
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, load_risk);
                view(2);
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, load_risk);
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, load_risk, 90, 'LineStyle', 'none');
            end
            
            set(curr_plot_handle, 'HitTest', 'off');
            set(handles.pressure_map_slider, 'Visible', 'off');
            handles.curr_plot = load_risk;
            caxis(handles.pressure_map, [0 1])
            cmap = colormap(handles.pressure_map, hsv(255));
            cmap = [0 0 0; cmap];
            colormap(handles.pressure_map, cmap);
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
        case 6 % Plot Load Risk which is a combination of the magnitude and pattern differences
            load_risk = handles.load_risk{selected_condition, selected_comparison};
            max_mag_risk = max(magnitude_risk{selected_condition, selected_comparison},[],3);
            min_mag_risk = min(magnitude_risk{selected_condition, selected_comparison},[],3);
            mag_risk_total = magnitude_risk{selected_condition, selected_comparison}(:,:,1);
            mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
            mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
            
            if strcmp(get(handles.surf_on, 'Checked'), 'on')
                curr_plot_handle = surf(handles.pressure_map, abs(mag_risk_total).*load_risk);
                view(2);
            elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
                curr_plot_handle = pcolor(handles.pressure_map, mag_risk_total.*load_risk);
                cmap = colormap(handles.pressure_map, [cool(127);[0 0 0];hot(127)]);
                cmap(floor(255/2)+1,:) = [0 0 0];
            else
                [~, curr_plot_handle] = contourf(handles.pressure_map, mag_risk_total.*load_risk, 90, 'LineStyle', 'none');
                cmap = colormap(handles.pressure_map, jet(255));
                cmap(floor(255/2):floor(255/2)+1,:) = [0 0 0; 0 0 0];
            end
            set(curr_plot_handle, 'HitTest', 'off');
            handles.curr_plot = mag_risk_total.*load_risk;
            
            caxis(handles.pressure_map, [-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
            colormap(handles.pressure_map, cmap);
            set(handles.pressure_map_slider, 'Visible', 'off');
            xlim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.cols]);
            ylim(handles.pressure_map, [0 handles.tekvar{selected_comparison}.header.rows]);
            set(handles.pressure_map, 'YDir', 'reverse');
    end
end

set(handles.pressure_map, 'XTick', 0:2:handles.tekvar{selected_condition}.header.cols+1)
set(handles.pressure_map, 'YTick', 0:2:handles.tekvar{selected_condition}.header.rows+1)
axis(handles.pressure_map, 'equal');
xlim(handles.pressure_map, [0 handles.tekvar{selected_condition}.header.cols+1]);
ylim(handles.pressure_map, [0 handles.tekvar{selected_condition}.header.rows+1]);
if strcmp(get(handles.contour_on, 'Checked'), 'on')
    grid(handles.pressure_map, 'on');
end
colorbar('peer', handles.pressure_map);

%% display ROI information
loc = rem(index,handles.window_size);
if loc == 0
    loc = handles.window_size;
end

if strcmpi(get(handles.roi_training, 'Checked'), 'on') % if using training module
    handles.curr_select = handles.curr_plot*NaN;
    expoverlay = handles.curr_select;
    handles.curr_select(handles.expin(:,:,loc) == 1) = handles.curr_plot(handles.expin(:,:,loc) == 1);
    expoverlay(handles.expin(:,:,loc) == 1 & handles.curr_plot>0) = 0.3;
    
    if strcmp(get(handles.highlight_ROI, 'Checked'), 'on')
        if iscell(get(handles.senspec_popupmenu, 'String'))
            t = get(handles.senspec_popupmenu, 'Value');
            trainoverlay = handles.curr_plot*NaN;
            trainoverlay(handles.trainin{t}(:,:,loc) == 1 & handles.curr_plot>0) = 0.3;
        else
            trainoverlay = handles.curr_plot*NaN;
            trainoverlay(handles.trainin(:,:,loc) == 1 & handles.curr_plot>0) = 0.3;
        end
        
        e2 = pcolor(handles.pressure_map, expoverlay); % get sensels within ROI
        set(e2,'facealpha',0.6); % set opacity based on user choice
        e2.CData(e2.CData>0) = handles.max_crange*0.9; % change highlight color depending on user choice
        
        e3 = pcolor(handles.pressure_map, trainoverlay); % get sensels within ROI
        set(e3,'facealpha',0.6); % set opacity based on user choice
        e3.CData(e3.CData>0) = handles.max_crange*0.62; % change highlight color depending on user choice
    end
    
    if strcmp(get(handles.show_ROI, 'Checked'), 'on')
        if strcmp(get(handles.round_ROI, 'Checked'), 'on')
            p = plot(handles.pressure_map, round(handles.exproibnd{1,loc}(:,1)),round(handles.exproibnd{1,loc}(:,2)),'o-r');
        else
            p = plot(handles.pressure_map, handles.exproibnd{1,loc}(:,1),handles.exproibnd{1,loc}(:,2),'o-r');
        end
        p.MarkerSize = 10;
        p.LineWidth = 2;
                
        if iscell(get(handles.senspec_popupmenu, 'String'))
            if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                p = plot(handles.pressure_map, round(handles.trainroibnd{t}{1,loc}(:,1)),round(handles.trainroibnd{t}{1,loc}(:,2)),'o--g');
            else
                p = plot(handles.pressure_map, handles.trainroibnd{t}{1,loc}(:,1),handles.trainroibnd{t}{1,loc}(:,2),'o--g');
            end
            set(handles.stats04, 'String', ['Sensitivity: ' sprintf('%.3f',handles.sens{t}(:,:,index)) '  |  Specificity: ' sprintf('%.3f', handles.spec{t}(:,:,index))]);
            
        else
            if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                p = plot(handles.pressure_map, round(handles.trainroibnd{1,loc}(:,1)),round(handles.trainroibnd{1,loc}(:,2)),'o--g');
            else
                p = plot(handles.pressure_map, handles.trainroibnd{1,loc}(:,1),handles.trainroibnd{1,loc}(:,2),'o--g');
            end
            set(handles.stats04, 'String', ['Sensitivity: ' sprintf('%.3f', handles.sens(:,:,index)) '  |  Specificity: ' sprintf('%.3f', handles.spec(:,:,index))]);
        end
        p.MarkerSize = 5;
    end
elseif handles.curr_select_flag == 1 % ROI is set
    handles.curr_select = handles.curr_plot*NaN;
    overlay = handles.curr_select;
    handles.curr_select(handles.in(:,:,loc) == 1) = handles.curr_plot(handles.in(:,:,loc) == 1);
    overlay(handles.in(:,:,loc) == 1 & handles.curr_plot>0) = 0.3;
    
    % if option checked to highlight ROI
    if strcmp(get(handles.highlight_ROI, 'Checked'), 'on')
        e2 = pcolor(handles.pressure_map, overlay); % get sensels within ROI
        set(e2,'facealpha',handles.h_transp); % set opacity based on user choice
        e2.CData(e2.CData>0) = handles.max_crange*handles.highlight; % change highlight color depending on user choice
    end
    
    handles.curr_plot = handles.curr_select;
    if strcmp(get(handles.show_ROI, 'Checked'), 'on')
        if strcmp(get(handles.round_ROI, 'Checked'), 'on')
            plot(handles.pressure_map, round(handles.roibnd{1,loc}(:,1)),round(handles.roibnd{1,loc}(:,2)),'.-r');
        else
            plot(handles.pressure_map, handles.roibnd{1,loc}(:,1),handles.roibnd{1,loc}(:,2),'.-r');
        end
    end
end

%% display WCOCS locations
if strcmp(get(handles.centroid, 'Checked'), 'on') 
    rows = handles.tekvar{selected_condition}.header.rows;
    cols = handles.tekvar{selected_condition}.header.cols;

    % Show left WCOCS
    if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [I, J] = centroid_location(abs(handles.curr_plot(1:rows,1:round(cols/2))), str2num(get(handles.noise_floor_edit, 'String')), true);
        set(handles.centroid_loc_text, 'String', ['Centroid Location: X = '...
            num2str(J*col_space) ' Y = ' num2str(I*row_space)])
        set(handles.centroid_loc_text2, 'String', ' ')
        hold(handles.pressure_map, 'on')
        plot(handles.pressure_map, J, I, 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],...
            'MarkerSize',10,...
            'Marker','pentagram',...
            'LineStyle','none', 'HitTest', 'off');
        hold(handles.pressure_map, 'off')
%         handles.var_collector(selected_condition,[1,2]) = [J*col_space, I*row_space]; %whs added, collect the key values.
    end
    
    % Show right WCOCS
    if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [I, J] = centroid_location(abs(handles.curr_plot(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), true);
        if get(handles.right_plateau, 'Value')
            set(handles.centroid_loc_text, 'String', ['Centroid Location: X = '...
                num2str((J+cols/2)*col_space) ' Y = ' num2str(I*row_space)])
            set(handles.centroid_loc_text2, 'String', ' ')
        else
            set(handles.centroid_loc_text2, 'String', ['Centroid Location: X = '...
                num2str((J+cols/2)*col_space) ' Y = ' num2str(I*row_space)])
        end
        hold(handles.pressure_map, 'on')
        plot(handles.pressure_map, J+cols/2, I, 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],...
            'MarkerSize',10,...
            'Marker','pentagram',...
            'LineStyle','none', 'HitTest', 'off');
        hold(handles.pressure_map, 'off')
%         handles.var_collector(selected_condition,3:4) = [(J+cols/2)*col_space, I*row_space]; %whs added, collect the key values.
    end
end

%% Show Stats for Current Tekscan Map
if strcmp(get(handles.pressure_measurement, 'Checked'), 'on')
    mag_roi = handles.curr_plot;
    if strcmp(get(handles.include_zero, 'Checked'), 'on')
        set(handles.stats01, 'String', ['Mean: ' num2str(mean(mean(mag_roi(~isnan(mag_roi)))))...
            ' MPa  |  Max: ' num2str(max(max(mag_roi(~isnan(mag_roi))))) ' MPa']);
        set(handles.stats02, 'String', ['Min: ' num2str(min(min(mag_roi(~isnan(mag_roi)))))...
            ' MPa  |  Sum: ' num2str(sum(sum(mag_roi(~isnan(mag_roi))))*sensel_area) ' N']);
    else
        set(handles.stats01, 'String', ['Mean: ' num2str(mean(mean(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))))...
            ' MPa  |  Max: ' num2str(max(max(mag_roi(~isnan(mag_roi))))) ' MPa']);
        set(handles.stats02, 'String', ['Min: ' num2str(min(min(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))))...
            ' MPa  |  Sum: ' num2str(sum(sum(mag_roi(~isnan(mag_roi))))*sensel_area) ' N']);
    end
    set(handles.stats03, 'String', ['Total Contact Area: ' num2str(sensel_area*length(mag_roi(mag_roi>0))) ' mm^2']);
%     handles.var_collector(selected_condition,5:8) = [mean(mean(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))), max(max(mag_roi(~isnan(mag_roi)))), ...
%         sum(sum(mag_roi(~isnan(mag_roi))))*sensel_area, sensel_area*length(mag_roi(mag_roi>0))]; %whs added, collect the key values.
end
guidata(hObject, handles); %whs added,

%% Plot Force Profile
min_xaxis = time(index)-handles.Tl/2*str2double(get(handles.cycles_to_show, 'String'));

if min_xaxis < 0 
    min_xaxis = 0; 
end

max_xaxis = time(index)+handles.Tl/2*str2double(get(handles.cycles_to_show, 'String'));

if max_xaxis > time(end)
    max_xaxis = time(end);
end

cla(handles.cycle_tracker_axes);
cla(handles.axes2);
hold(handles.cycle_tracker_axes, 'on');
   
plot(handles.cycle_tracker_axes, time, force{selected_condition}(time_order{selected_condition})*fScale^2, 'HitTest', 'off');

if get(handles.risk_map_checkbox, 'Value')
    curr_plot_handle = plot(handles.cycle_tracker_axes, time, force{selected_comparison}(time_order{selected_comparison})* fScale^2, 'r');
    set(curr_plot_handle, 'HitTest', 'off');
end

xlim(handles.cycle_tracker_axes, [min_xaxis max_xaxis])
xlim(handles.axes2, [min_xaxis max_xaxis])
 
% plot overlay information and graphs
if strcmpi(get(handles.second_axis, 'Visible'), 'on')
    selected_second_axis = get(handles.second_axis, 'Value');
end

if strcmp(get(handles.pattern_register, 'Checked'), 'on') && ~get(handles.risk_map_checkbox, 'Value') && strcmp(get(handles.second_axis, 'Visible'), 'on')   
    plot(handles.cycle_tracker_axes, handles.tekvar{selected_condition}.data_a.time(1:numel(handles.gait_rep)), handles.gait_rep, 'LineStyle', '-.', 'Color', 'm', 'HitTest', 'off');
    hold(handles.axes2,'all');
    
    if selected_second_axis <= 3
        plot(handles.axes2, [0 handles.tekvar{selected_condition}.data_a.time(end)], [0 0], 'LineStyle', '--', 'Color',[0.749 0.749 0], 'HitTest', 'off')
        plot(handles.axes2, handles.tekvar{selected_condition}.data_a.time(1:numel(handles.(handles.kinematics(selected_condition).order{selected_second_axis}))), handles.(handles.kinematics(selected_condition).order{selected_second_axis}),'LineStyle','-.','Color',[0.4 0.4 0.4], 'HitTest', 'off');
        ylim(handles.axes2, [min(handles.(handles.kinematics(selected_condition).order{selected_second_axis}))-1 max(handles.(handles.kinematics(selected_condition).order{selected_second_axis}))+1])
        curr_data_point = handles.flexion_rep(index);
        curr_data_point = [num2str(curr_data_point) handles.kinematics(selected_condition).units{selected_second_axis}];
        name = handles.kinematics(selected_condition).name{selected_second_axis};
    else
        flag_d = '';
        if get(handles.show_derivs, 'Value')
            flag_d = 'd';
        end
        curr_select = [flag_d handles.kinematics(selected_condition).order{selected_second_axis}];
        curr_values = handles.kinematics(selected_condition).(curr_select);
        plot(handles.axes2, [0 handles.tekvar{selected_condition}.data_a.time(end)], [0 0], 'LineStyle', '--', 'Color',[0.749 0.749 0], 'HitTest', 'off')
        hold(handles.axes2, 'on')
        plot(handles.axes2, handles.tekvar{selected_condition}.data_a.time, curr_values,'LineStyle','-.', 'Color', [0.4 0.4 0.4], 'HitTest', 'off');
        ylim(handles.axes2, [min(curr_values)-0.25 max(curr_values)+0.25])
        curr_data_point = curr_values(index);
        curr_data_point = [num2str(curr_data_point) handles.kinematics(selected_condition).([flag_d 'units']){selected_second_axis}];
        name = handles.kinematics(selected_condition).([flag_d 'name']){selected_second_axis};
        hold(handles.axes2, 'off')
    end

    ylabel(handles.axes2, name);
end

% plot vertical line in force plot to show current frame location
curr_plot_handle = plot(handles.cycle_tracker_axes, [handles.tekvar{selected_condition}.data_a.time(index) handles.tekvar{selected_condition}.data_a.time(index)], [0 handles.cycle_tracker_axes.YLim(2)], '-.k');

set(curr_plot_handle, 'HitTest', 'off');

tracker_title = [num2str((index-1)*handles.T) ' s '];
if strcmp(get(handles.pattern_register, 'Checked'), 'on') && ~get(handles.risk_map_checkbox, 'Value')
    tracker_title = [tracker_title ' [' num2str(handles.gait_time(index)/handles.Tl*100) '% | ' curr_data_point '] (Frame ' num2str(index) ')'];
else
    tracker_title = [tracker_title '(Frame ' num2str(index) ')'];
end

set(handles.axes2, 'HitTest', 'off');
title(handles.cycle_tracker_axes, tracker_title); xlabel(handles.cycle_tracker_axes, 'Time [s]'); ylabel(handles.cycle_tracker_axes, 'Force (N)'); 

guidata(hObject, handles);