function outhandles = calc_in(hObject, handles)
% calculates the number of sensels in and out of the region of interest

%% Initialize Variables
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

if strcmpi(get(handles.roi_training, 'Checked'), 'on')
    for leng = 1:handles.window_size
        % create matrix with same number of rows and cols as tekscan sensor
        y = linspace(1,rows,rows); x = linspace(1,cols,cols);
        [X, Y] = meshgrid(x,y); clear x y
        
        
    end
elseif handles.curr_select_flag == 1 % ROI is loaded and set
    % initialize the ROI space
    for leng = 1:handles.window_size
        % create matrix with same number of rows and cols as tekscan sensor
        y = linspace(1,rows,rows); x = linspace(1,cols,cols);
        [X, Y] = meshgrid(x,y); clear x y
        
        if ~isempty(find(isnan(handles.roibnd{leng}(:,1)),1)) % Region has a hole from inverting selection
            locBreak = find(isnan(handles.roibnd{leng}(:,1)));
            
            if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                [in_OutBorder, on] = inpolygon(X,Y,round(handles.roibnd{leng}(1:locBreak-1,1)),round(handles.roibnd{leng}(1:locBreak-1,2)));
                in_InBorder = inpolygon(X,Y,round(handles.roibnd{leng}(locBreak+1:end,1)),round(handles.roibnd{leng}(locBreak+1:end,2)));
            else
                [in_OutBorder, on] = inpolygon(X,Y,handles.roibnd{leng}(1:locBreak-1,1),handles.roibnd{leng}(1:locBreak-1,2));
                in_InBorder = inpolygon(X,Y,handles.roibnd{leng}(locBreak+1:end,1),handles.roibnd{leng}(locBreak+1:end,2));
            end
            
            handles.in(:,:,leng) = in_OutBorder - in_InBorder;
        elseif strcmp(get(handles.round_ROI, 'Checked'), 'on') % If rounding is selected in options
            [handles.in(:,:,leng), on] = inpolygon(X,Y,round(handles.roibnd{leng}(:,1)),round(handles.roibnd{leng}(:,2)));
        else % Load only values in the ROI
            [handles.in(:,:,leng), on] = inpolygon(X,Y,handles.roibnd{leng}(:,1),handles.roibnd{leng}(:,2));
        end
        
        if ~handles.inon % if evaluating ROI with hole
            handles.in(:,:,leng) = handles.in(:,:,leng) - on;
        end
    end
    
    outhandles = handles;
end
