function out = training_calc_in(hObject, handles, roibnd)
% calculates the number of sensels in and out of the region of interest

%% Initialize Variables
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

if strcmpi(get(hObject, 'Checked'), 'on')
    % initialize the ROI space
    in = zeros(rows,cols,handles.window_size);
    for leng = 1:handles.window_size
        % create matrix with same number of rows and cols as tekscan sensor
        y = linspace(1,rows,rows); x = linspace(1,cols,cols);
        [X, Y] = meshgrid(x,y); clear x y
        
        if ~isempty(find(isnan(roibnd{leng}),1)) % Region has a hole from inverting selection
            locBreak = find(isnan(roibnd{leng}(:,1)));
            
            if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                [in_OutBorder, on] = inpolygon(X,Y,round(roibnd{leng}(1:locBreak-1,1)),round(roibnd{leng}(1:locBreak-1,2)));
                in_InBorder = inpolygon(X,Y,round(roibnd{leng}(locBreak+1:end,1)),round(roibnd{leng}(locBreak+1:end,2)));
            else
                [in_OutBorder, on] = inpolygon(X,Y,roibnd{leng}(1:locBreak-1,1),roibnd{leng}(1:locBreak-1,2));
                in_InBorder = inpolygon(X,Y,roibnd{leng}(locBreak+1:end,1),roibnd{leng}(locBreak+1:end,2));
            end
            
            n(:,:,leng) = in_OutBorder - in_InBorder;
        elseif strcmp(get(handles.round_ROI, 'Checked'), 'on') % If rounding is selected in options
            [in(:,:,leng), on] = inpolygon(X,Y,round(roibnd{leng}(:,1)),round(roibnd{leng}(:,2)));
        else % Load only values in the ROI
            [in(:,:,leng), on] = inpolygon(X,Y,roibnd{leng}(:,1),roibnd{leng}(:,2));
        end
        
        if ~handles.inon % if evaluating ROI with hole
            in(:,:,leng) = in(:,:,leng) - on;
        end
    end
    
    out = in;
end
