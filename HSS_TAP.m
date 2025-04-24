function varargout = HSS_TAP(varargin)
% HSS_TAP M-file for HSS_TAP.fig
%      HSS_TAP, by itself, creates a new HSS_TAP or raises the existing
%      singleton*.
%
%      H = HSS_TAP returns the handle to a new HSS_TAP or the handle to
%      the existing singleton*.
%
%      HSS_TAP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HSS_TAP.M with the given input arguments.
%
%      HSS_TAP('Property','Value',...) creates a new HSS_TAP or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before HSS_TAP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to HSS_TAP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help HSS_TAP

% Last Modified by GUIDE v2.5 17-Oct-2024 15:32:19

%March 2011 created by Tony Chen

%May 2013 updated by Hongsheng W
%-- 1. cross correlation using matlab embedded function xcorr('coeff')
%-- 2. low pass filter the raw data before runing the analyze_ncc().
%-- 3. rewrite the analyze_ncc loops, now the code gives the same results,
%inspite of changes on the other region. (the region with the same 
%pattern always gets the same pattern no matter changes at the other region.)

%May 2014 updated by Tony C
%-- 1. Added save all: saves map stats, contact area, and WCoC by pressing
%Ctrl + A
%-- 2. Altered char patterns so that have the option not to smooth data

%Dec 2014 updated by Tony C
%-- 1. Added load/save ROIs
%-- 2. Add edit ROI
%-- 3. Add copy ROI: Forward (Ctl + F), Reverse (Ctl + R), and Replace All

%Jun 2019 updated by Lainie
%-- 1. Edited and added comments 
%-- 3. fixed bug in get_quadrant function

%August 2020 updated by Tony C and Ashley P
%-- 1. Added in ROI highlighting
%-- 2. Added in STAPLE ROI
%-- 3. Added experimental semi-automated C-C ROI identification

%Jan 2021 updated by Tony C and Ashley P
%-- 2. Removed unnecessary functions and code for distribution
%-- 3. Added in Training Code

%May 3, 2022 updated by Tony C
%-- 1. Added Difference  Regions code to look at areas with difference
%between two specimens/conditions

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @HSS_TAP_OpeningFcn, ...
                   'gui_OutputFcn',  @HSS_TAP_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% Add subfolder
addpath(['.' filesep 'additionalFiles']);

% --- Executes just before HSS_TAP is made visible.
function HSS_TAP_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to HSS_TAP (see VARARGIN)

% Choose default command line output for HSS_TAP
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes HSS_TAP wait for user response (see UIRESUME)
% uiwait(handles.gui_frame);


% --- Outputs from this function are returned to the command line.
function varargout = HSS_TAP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function pressure_map_slider_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to pressure_map_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%When the slider is incremented, call function refresh_fig to update all
%necessary GUI elements
refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function pressure_map_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pressure_map_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function open_Callback(hObject, eventdata, handles)
% hObject    handle to open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set variables
handles.curr_select_flag = 0; % clears all set regions of interest
handles.highlight = 0.65; % sets ROI highlight color
handles.h_transp = 0.5; % sets ROI highlight opacity
handles.avg_flag = 0; % sets flag for whether average data will be calculated

% Opens Gui to select a Tekscan movie file
[file, path]=uigetfile(...
	{'*.asf; *.csv; *.mat', 'Tekscan files';...
    '*.*',  'All Files'}, ...
	'Pick a Tekscan output file');

% Code to open and parse selected Tekscan file
if ~isequal(file,0) %checks that cancel isn't pressed
    
    set(handles.condition_selector, 'String', {'Pop-up Menu'});
    set(handles.comparison_selector, 'String', {'Pop-up Menu'});
    
    answer = 0; % flag for while loop for opening more files

    % If the field comparison doesn't exists then initialize all variables
    if ~isfield(handles,'comparison')
        handles.comparison = 1; % number of files open
        handles.tekvar = {}; % cell array of tekscan map data
        handles.tekvar_name = {}; % cell array containing the name identifier for each loaded tekscan file
        handles.senselvar = {}; % cell array for the rearranged tekscan data
        handles.force = {}; % cell array for the total force for each loaded tekscan file
        handles.scale_factor = {}; % cell array of the scale factor
        handles.sensels = {}; 
        handles.kinematics = {};
        handles.simulator = {};
    else % Otherwise increment comparison flag for each new file openned
        handles.comparison = handles.comparison + 1;
    end
    
    handles.tekvar{handles.comparison} = open_tekscan(file, path); % open tekscan file
    
    handles.path = path; % remember most recent path visited - for convenience
    
    % store number of sensels and length of acquisition of first file opened
    % to ensure that all files opened are of the same length
    handles.length_sample = size(handles.tekvar{handles.comparison}.data_a.sensel,3);
    time_sample = handles.tekvar{handles.comparison}.data_a.time;
    
    % Creates dialogue box to input a condition name; default option displayed is file name (no extension)
    handles.tekvar_name{handles.comparison} = (cell2mat(inputdlg('Enter Name for Condition:','Name:',1, {strtok(file, '.')})));  % Ability to give a unique identifier to each opened tekscan file
    
    %% For knees: this section can be removed if laterality doesn't matter or always select 'Right' in program to maintain sensor orientation
    % Creates dialogue box for user to identify the knee as left or right
    choice = questdlg('Left or Right Knee?', ...
        'Left or Right Knee:', ...
        'Left','Right','Right');
    handles.knee_side{handles.comparison} = choice;
    
    % if 'left' is chosen, reverse order of the column elements
    if strcmpi(handles.knee_side{handles.comparison}, 'left')
        handles.tekvar{handles.comparison}.data_a.sensel =...
            handles.tekvar{handles.comparison}.data_a.sensel(:, handles.tekvar{handles.comparison}.header.cols:-1:1, :);
    end
    
    %% Continues to prompt user for new tekscan files until 'no' is pressed in the dialogue box
    while answer == 0 % Loop until 'No' is chosen in dialogue box
        % Construct a Dialogue Box to determine whether multiple conditions will be compared
        choice = questdlg('Compare to Another Condition?', ...
            'Comparison', ...
            'Yes','No','No');

        switch choice
            case 'Yes' % If option 'Yes' was selected continue to prompt for more files
                [file, pathfile]=uigetfile(...
                    {'*.asf; *.csv; *.mat', 'Tekscan files';...
                    '*.*',  'All Files'}, ...
                    'Pick a Tekscan output file', handles.path);  
       
                % make sure cancel wasn't pressed in open file dialoge and 
                % stores file information
                if ~isequal(file,0)
                    handles.comparison = handles.comparison + 1; % +1 to comparison flag (number of tekscan files open)
                    
                    handles.tekvar{handles.comparison} = open_tekscan(file, pathfile); % open tekscan file
                    
                    % Compare length of first tekscan file opened and
                    % store the length of the largest file
                    curr_length_sample = size(handles.tekvar{handles.comparison}.data_a.sensel,3);
                    if curr_length_sample > handles.length_sample
                        handles.length_sample = curr_length_sample; % finds length of longest Tekscan file
                        time_sample = handles.tekvar{handles.comparison}.data_a.time;
                    end
                    
                    % Creates dialogue box to input a condition name for the additional file; default option displayed is file name (no extension)                    
                    handles.tekvar_name{handles.comparison} =  (cell2mat(inputdlg('Enter Name for Condition:','Name:',1, {strtok(file, '.')}))); % Name of test condition
 
                    % Creates dialogue box for user to identify the additional knee as left or right 
                    choice = questdlg('Left or Right Knee?', ...
                        'Knee Side', ...
                        'Left','Right','Right');
                    handles.knee_side{handles.comparison} = choice;

                    % If 'left' is chosen, reverse order of the column elements
                    if strcmpi(handles.knee_side{handles.comparison}, 'left')
                        handles.tekvar{handles.comparison}.data_a.sensel =...
                            handles.tekvar{handles.comparison}.data_a.sensel(:, handles.tekvar{handles.comparison}.header.cols:-1:1, :);
                    end
                    
                    % Stores name of additional file in handles
                    handles.path = pathfile;
                    if isempty(handles.tekvar_name{handles.comparison})
                        handles.tekvar_name{handles.comparison} = strtok(file, '.');
                    end
                else % if cancel was pressed in open dialogue, will cause loop to break
                    answer = 1;
                end
            case 'No' % If option 'No' was selected
                answer = 1;
        end
    end
    
    % Make sure that all opened tekscan files have the same acquisition
    % time, if files are shorter use function repmat to extend
    % number of acquitions until files are all same length
    for w = 1:handles.comparison
        curr_length_sample = size(handles.tekvar{w}.data_a.sensel, 3); % get the total number of frames for the current file
        if curr_length_sample < handles.length_sample % if the file was shorter than the largest file
            temp = handles.tekvar{w}.data_a.sensel(:,:,1);
            temp(~isnan(temp)) = 0;
            temp = repmat(temp, [1 1 handles.length_sample-curr_length_sample]);
            temp(:, :, end+1:end+curr_length_sample) = handles.tekvar{w}.data_a.sensel;
            handles.tekvar{w}.data_a.sensel = temp;
            handles.tekvar{w}.data_a.time = time_sample;
        end
    end
    
    guidata(hObject, handles) % updates the handles struct to contain the tekscan data
    initialize(hObject, handles) % Setup handles with all required parameters and setup GUI
end    

% --------------------------------------------------------------------
function save_mov_Callback(hObject, eventdata, handles)
% hObject    handle to save_mov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Ask user name of avi file to save
[file, pathfile]=uiputfile(...
    {'*.avi','AVI Movie File(*.avi)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Pressure Map Movie', handles.path);

% ensures 'Cancel' wasn't pressed and then save movie for the tekscan file
% currently selected
if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    selected_condition = get(handles.condition_selector, 'Value'); % get currently selected tekscan file
   
    % set range of frames to save
    time_span =  (inputdlg({'Start Frame (min value = 1):',...
        ['End Frame (max value = ' num2str(handles.length_time) '):']},...
        'Movie Frame Span',1, {'1', num2str(handles.length_time)}));
    
    start_frame = str2num(time_span{1}); %#ok<*ST2NM> % store start frame
    end_frame = str2num(time_span{2}); % store end frame
    
    % If there are more than one tekscan file open see if user wants to have
    % a second tekscan file saved as a comparison
    if handles.comparison
        choice = questdlg('Plot Test Condition?', ...
            'Comparison', ...
            'Yes','No','No');
    else
        choice = 'No';
    end
    
    switch choice
        case 'Yes' % if two tekscan files are to be saved in the same movie file
            fig = figure('Color', 'White');
            fps =  (inputdlg({'FPS:'}, 'Frames Per Second',1,{num2str(handles.Fs)})); % frames/sec to run movie at
            aviobj = VideoWriter([pathfile file]);
            aviobj.FrameRate = str2num(fps{1});
            aviobj.Quality = 100; %No compression
            open(aviobj);
            set(fig, 'Position', [0 0 1050 440], 'PaperPositionMode', 'auto');
            % start capturing frames of movie file
            for frame_write = start_frame:end_frame
                
                cond1 = subplot(1,2,1); % create a 2 column x 1 row figure
                % for tekscan 1
                pcond1 = pcolor(handles.senselvar{1}(:,:,handles.time_order{1}(frame_write)));
                caxis([0 handles.max_crange])
                title(handles.tekvar_name{1})
                set(cond1, 'XTick', 0:1:handles.tekvar{selected_condition}.header.cols)
                set(cond1, 'YTick', 0:1:handles.tekvar{selected_condition}.header.rows)
                set(cond1,'nextplot','replacechildren');
                set(gcf,'Renderer','zbuffer');
                set(cond1, 'YDir', 'reverse')
                axis(cond1, 'tight');
                axis(cond1, 'off');
                pcond1.LineStyle = 'none';
                cmap = colormap(jet(256));
                cmap = [0 0 0; cmap];
                colormap(cmap);
                colorbar
                
                cond2 = subplot(1,2,2);
                % for tekscan 2
                pcond2 = pcolor(handles.senselvar{2}(:,:,handles.time_order{2}(frame_write)));
                caxis([0 handles.max_crange])
                title(handles.tekvar_name{2})
                set(cond2, 'XTick', 0:1:handles.tekvar{selected_condition}.header.cols)
                set(cond2, 'YTick', 0:1:handles.tekvar{selected_condition}.header.rows)
                set(cond2,'nextplot','replacechildren');
                set(gcf,'Renderer','zbuffer');
                set(cond2, 'YDir', 'reverse')
                axis(cond2, 'tight');
                axis(cond2, 'off');
                pcond2.LineStyle = 'none';
                cmap = colormap(jet(256));
                cmap = [0 0 0; cmap];
                colormap(cmap);
                colorbar
                
                % make movie frame
                F = getframe(fig);
                writeVideo(aviobj,F)
            end
        case 'No' % if only a single tekscan file will be saved in the movie
            fig = figure('Color', 'White');
            fps =  (inputdlg({'FPS:'}, 'Frames Per Second',1,{num2str(handles.Fs)})); % frames/sec to run movie at
            aviobj = VideoWriter([pathfile file]);
            aviobj.FrameRate = str2num(fps{1});
            aviobj.Quality = 100; % no compression
            open(aviobj);
            
            % start capturing frames of movie file
            for frame_write = start_frame:end_frame
                pcolor(handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(frame_write)));
                caxis([0 handles.max_crange])
                set(gca, 'XTick', 0:1:handles.tekvar{selected_condition}.header.cols)
                set(gca, 'YTick', 0:1:handles.tekvar{selected_condition}.header.rows)
                set(gca,'nextplot','replacechildren');
                set(gcf,'Renderer','zbuffer');
                set(gca, 'YDir', 'reverse')
                axis equal
                axis off
                grid on
                cmap = colormap(jet(256));
                cmap = [0 0 0; cmap];
                colormap(cmap);
                colorbar
                F = getframe(fig);
                writeVideo(aviobj,F)
            end
    end
    
    % close figure and movie objects
    close(fig);
    close(aviobj);
    close(aviobj);
end

% --------------------------------------------------------------------
function save_corr_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_corr_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Saves common pattern data for the currently selected tekscan map as text delimited files

selected_condition = get(handles.condition_selector, 'Value'); %Get currently selected tekscan file

length_templates = length(handles.stored_char_templates{selected_condition}.char_templates); %get the number of characteristic curves found

%get base file name to be used when saving correlation maps
[file, pathfile]=uiputfile(...
    {'*.txt','Text File(*.txt)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Correlation Map Data', handles.path);

[token, rem] = strtok(file, '.');

% Make sure 'Cancel' wasn't pressed and then save correlation maps
if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    % performing operations for exporting each found characteristic pattern
    for index = 1:length_templates
        tfile = [token '_' num2str(index) rem]; % file name for the current correlation map = 'base file name' + 'correlation map #'
        
        curr_corr_maps = handles.stored_char_templates{selected_condition}.char_templates(index); % stores the current correlation map
        aligned_range = {}; % initialize cell array for aligned tekscan data
        aligned_pattern = []; % aligned patterns for each characteristic pattern
        
        % for each sensel with the pattern, align the data and then store in
        % aligned_range
        for corr_condense = 1:length(curr_corr_maps.patterns)
            len_currMap = length(curr_corr_maps.patterns{corr_condense});
            if curr_corr_maps.shift(corr_condense) <=0
                aligned_range{corr_condense} = [len_currMap + curr_corr_maps.shift(corr_condense):len_currMap, 1:len_currMap + curr_corr_maps.shift(corr_condense)-1]; %#ok<*AGROW>
            elseif curr_corr_maps.shift(corr_condense) > 1
                aligned_range{corr_condense} = [curr_corr_maps.shift(corr_condense):len_currMap, 1:curr_corr_maps.shift(corr_condense)-1];
            else
                aligned_range{corr_condense} = 1:len_currMap;
            end
        end
        
        %-----Normalize the loading patterns-----
        sum_templates_abs = curr_corr_maps.patterns{1}(aligned_range{1}); % absolute value of each sensel
        sum_templates_rel =  curr_corr_maps.patterns{1}(aligned_range{1})...
            /max(curr_corr_maps.patterns{1}(aligned_range{1})); % normalize by itself, therefore, only shape and not amplitude matters
        aligned_pattern(:,1) = curr_corr_maps.patterns{1}(aligned_range{1});
        for corr_condense = 2:length(curr_corr_maps.patterns)
            % get the average profile shape of the current
            % loading pattern
            sum_templates_abs = sum_templates_abs + curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense});
            sum_templates_rel = sum_templates_rel + curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})...
            /max(curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense}));
            aligned_pattern(:,corr_condense) = curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense});
        end
        %----Write data to files----
        dlmwrite([pathfile tfile], sum_templates_abs/length(curr_corr_maps.patterns)); 
        dlmwrite([pathfile token '_' num2str(index) '.raw'], aligned_pattern); % raw stress data for characteristic curve
        dlmwrite([pathfile token '_' num2str(index) '.ind'], curr_corr_maps.patLoc); % index location for each found pattern
        dlmwrite([pathfile token '_' num2str(index) '.rel'], sum_templates_rel/length(curr_corr_maps.patterns)); % relative stress data for characteristic curve
        dlmwrite([pathfile token '_' num2str(index) '.amp'], handles.stored_char_templates{selected_condition}.char_templates(index).corr_map_amp); % the magnitude map of each sensel sharing the same pattern.
        dlmwrite([pathfile token '_' num2str(index) '.map'], handles.stored_char_templates{selected_condition}.char_templates(index).corr_map); % mapped location of characteristic patterns on a map of the sensor
    end
end

% --------------------------------------------------------------------
function save_corr_maps_Callback(hObject, eventdata, handles)
% hObject    handle to save_corr_maps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Saves the common pattern maps for the selected tekscan map as tiff images

counter = 0; % counter used to save maps and images

selected_condition = get(handles.condition_selector, 'Value'); % get the currently selected tekscan file

length_templates = length(handles.stored_char_templates{selected_condition}.char_templates); % get the number of characteristic curves found

% get base file name to be used when saving correlation maps
[file, pathfile]=uiputfile(...
    {'*.tiff','Tiff File(*.tiff)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Correlations Map', handles.path);

[token, rem] = strtok(file, '.'); % separates filename and extension

% Intialize a blank tekscan map to use for total correlation map
combined_corr_map = handles.stored_char_templates{selected_condition}.char_templates(1).corr_map;
combined_corr_map(~isnan(combined_corr_map)) = 0;

% Only continue if a file was selected
if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    figure1 = figure(10); %Open new figure
    % Make the figure the same a multiple of current screen size
    screensize = get(0, 'Screensize');
    ss_multi = floor(screensize(3)/1280);
    
    % Save correlation maps
    for index = 1:length_templates
        % Only save files after 5 characteristic maps have been displayed in
        % a figure
        if mod(index,5)==1 && index~=1
            % save current figure as a .tiff once figure has 5 patterns
            tfile = [token '_' num2str(counter+1) rem];
            set(figure1, 'Position', [0 0 1280*ss_multi 1024*ss_multi], 'PaperPositionMode', 'auto');
            print(figure1, '-dtiff', [pathfile tfile], '-r300');
            
            close(figure1) % close the previous figure
            
            counter = counter + 1;
            figure1 = figure(10+counter); % open a new figure
        end

        w = subplot(3,5,index-(5*counter)); % in the current figure create a 3 x 5 grid to layout for characteristic maps and plots
        curr_corr_maps = handles.stored_char_templates{selected_condition}.char_templates(index); % store the characteristic loading patterns for the currently selected condition in new variable for ease of calling
        sum_corr_maps = handles.stored_char_templates{selected_condition}.char_templates(index).corr_map; % store the characteristic loading pattern map for the currently selected condition in a new variable for ease of calling
        
        % for each sensel with the pattern, align the data and then store in
        % aligned_range
        for corr_condense = 1:length(curr_corr_maps.patterns)
            len_currMap = length(curr_corr_maps.patterns{corr_condense});
            if curr_corr_maps.shift(corr_condense) <=0 % if the time shift is negative, shift left to align
                aligned_range{corr_condense} = [len_currMap + curr_corr_maps.shift(corr_condense):len_currMap, 1:len_currMap + curr_corr_maps.shift(corr_condense)-1];
            elseif curr_corr_maps.shift(corr_condense) > 1 % if the time shift is positive, shift right to align
                aligned_range{corr_condense} = [curr_corr_maps.shift(corr_condense):len_currMap, 1:curr_corr_maps.shift(corr_condense)-1];
            else % if there is no time shift, keep the current alignment
                aligned_range{corr_condense} = 1:len_currMap;
            end
        end
        
        % setup image for each characteristic pattern found within a single tekscan file
        color_corr_map = sum_corr_maps;
        color_corr_map(abs(sum_corr_maps)>0) = 1;
        sum_corr_maps(abs(sum_corr_maps)>0) = sum_corr_maps(abs(sum_corr_maps)>0)-2;
        combined_corr_map = combined_corr_map + (index*color_corr_map);
%         pcolor(w, sum_corr_maps) % uncomment to use pcolor instead of surf
%         set(w, 'YDir', 'reverse'); % uncomment to use pcolor instead of surf
        surf(w, sum_corr_maps) % comment to use pcolor instead of surf
        view([0 -90])
        grid off
        axis off
        axis tight
        cmap = colormap(winter(21)); % creates a colormap with 42 different colors
        cmap(22,:) = [0 0 0]; % changes 22nd color to black (shift = 0)
        cmap = [cmap; colormap(autumn(21))];
        colormap(cmap);
        caxis([-20 20]);
        c = colorbar('southoutside');
        c.Label.String = 'Shift [accquisitions]';

        %check and initialize variable sum_templates for display of each
        %individual similar pattern found or the average of the similar
        %patterns found
        if get(handles.indiv_profiles_checkbox, 'Value')
            sum_templates = {}; %initialize sum_templates to empty cell array
            sum_templates{1} = (curr_corr_maps.patterns{1}(aligned_range{1})-mean(curr_corr_maps.patterns{1}(aligned_range{1})))/std(curr_corr_maps.patterns{1}(aligned_range{1})); %get first value to show
        else
            sum_templates = curr_corr_maps.patterns{1}(aligned_range{1}); %set sum_templates to the first pattern found
        end
        
        %repeat above with the rest of the similar patterns
        for corr_condense = 2:length(curr_corr_maps.patterns)
            if get(handles.indiv_profiles_checkbox, 'Value') %If indicated, plots the found patterns seperately
                sum_templates{corr_condense} = (curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})-mean(curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})))/std(curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})); %add the next similar pattern to the cell array
            else
                sum_templates = sum_templates + curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense}); %sum the current pattern with the previous similar patterns.
            end
        end
        
        subplot(3,5,(index+5)-(5*counter)) %activate subplot in the next row
        if get(handles.indiv_profiles_checkbox, 'Value') %Plots the individual normalized force plot of the current found pattern
            stored_templates = cell2mat(sum_templates);
            plot(stored_templates);
        else %plots the average of the found similar patterns
            plot(sum_templates/length(curr_corr_maps.patterns))
        end
        title([num2str(size(handles.stored_char_templates{selected_condition}.char_templates(index).patterns,2)) ' Matches']); %title of the subplot is the number of matches for the current characteristic pattern
                
        subplot(3,5,(index+10)-(5*counter)) %activate subplot in the next row
        if get(handles.indiv_profiles_checkbox, 'Value') %plot each individal fft for the current found pattern
            fft_templates = {}; 
            
            L = length(sum_templates{1});
            sinefft = fft(sum_templates{1});
            f = handles.Fs*(0:floor(L/2))/L;
            P2 = abs(sinefft/L);
            fft_templates{1} = P2(1:floor(L/2+1));
            fft_templates{1}(2:end-1) = 2*fft_templates{1}(2:end-1);
            
            plot(f, fft_templates{1})
            hold on
        else %plot the average fft for the average found pattern
            L = length(sum_templates);
            sinefft = fft(sum_templates);
            f = handles.Fs*(0:floor(L/2))/L;
            P2 = abs(sinefft/L);
            fft_templates = P2(1:floor(L/2+1));
            fft_templates(2:end-1) = 2*fft_templates(2:end-1);
            
            plot(f, fft_templates);
        end
        
        %if the individual patterns check box is checked plot the remaining
        %fft plots for the current fount pattern
        for corr_condense = 2:length(curr_corr_maps.patterns)
            if get(handles.indiv_profiles_checkbox, 'Value')
                L = length(sum_templates{corr_condense});
                sinefft = fft(sum_templates{corr_condense});
                f = handles.Fs*(0:floor(L/2))/L;
                P2 = abs(sinefft/L);
                fft_templates{corr_condense} = P2(1:floor(L/2+1));
                fft_templates{corr_condense}(2:end-1) = 2*fft_templates{corr_condense}(2:end-1);
                
                plot(f, fft_templates{corr_condense})
            end
        end
        
        hold off
        title('FFT');
        xlabel('Frequency [Hz]');
        ylabel('|Y(f)|');
    end
    
    tfile = [token '_' num2str(counter+1) rem]; %save last values
    set(figure1, 'Position', [0 0 1280*ss_multi 1024*ss_multi], 'PaperPositionMode', 'auto');
    print(figure1, '-dtiff', [pathfile tfile], '-r300') %save last figure
    
    close(figure1)
    
    if get(handles.show_corr_map_overlay, 'Value') %if users wants all patterns overlayed on a single tekscan map
        figure90 = figure(90);
        w = axes;
        surf(combined_corr_map)
        view([0 -90])
        grid off
        axis off
        axis tight
        cmap = colormap(jet(max(max(combined_corr_map))));
        cmap = [0 0 0; cmap];
        colormap(cmap);
        c = colorbar('southoutside');
        c.Label.String = 'Pattern #';
        c.FontSize = 12;
        c.FontWeight = 'Bold';
        
        tfile = [token '_overlay' rem];
        set(figure90, 'Position', [0 0 1280*ss_multi 1024*ss_multi], 'PaperPositionMode', 'auto');
        print(figure90, '-dtiff', [pathfile tfile], '-r300')
        
        close(figure90)
    end
end

% --------------------------------------------------------------------
function exit_Callback(hObject, eventdata, handles)
% hObject    handle to exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(0,'ShowHiddenHandles','on')
delete(get(0,'Children'))


function corr_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to corr_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of corr_thresh as text
%        str2double(get(hObject,'String')) returns contents of corr_thresh as a double


% --- Executes during object creation, after setting all properties.
function corr_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to corr_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function temp_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to temp_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of temp_thresh as text
%        str2double(get(hObject,'String')) returns contents of temp_thresh as a double


% --- Executes during object creation, after setting all properties.
function temp_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to temp_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Start Common Patterns Analysis
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%uses FFT algorithm to find common patterns within each tekscan map

%Have user enter parameters for low pass filter
%setting Cut-Off to 0 will disable filtering
prompt={'Enter Sample Frequency:',...
        'Enter Cut-Off (0 for no filtering):'};
name='Input for Low Pass Filter';
numlines=1; %number of input lines to include for the low-pass filter dialogue
defaultanswer={num2str(handles.Fs),num2str((handles.Fs-1)/2)}; %Default parameters are Sample Freq: 100 and Cut-Off: 6
answer=inputdlg(prompt,name,numlines,defaultanswer);

if str2num(answer{2})/(str2num(answer{1})/2) < 1 %If the cut-off frequency is <1 run characteristic curve analysis otherwise throw error
    for var_count = 1:handles.comparison
        handles.stored_char_templates{var_count}.char_templates = analyze_ncc(hObject, handles, var_count, str2num(answer{1}), str2num(answer{2})); %analyzes each tekscan map to find correlated areas
    end
else % throw error to user
    errordlg('Sample Cut-Off/(Sample Frequency/2) must be between 0 and 1');
end

set(handles.corr_uipanel, 'Visible', 'On');
guidata(hObject, handles);


% --- Executes on button press in corr_maps_button.
function corr_maps_button_Callback(hObject, eventdata, handles)
% hObject    handle to corr_maps_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% whs, 5/5/13, the plot out curves has already been aligned. (considered the time shift)
counter = 0;

% set variables
length_time = handles.length_time;
window_size = handles.window_size;
max_cycles = floor(length_time/window_size);

% get necessary parameters for selected condition in dropdown
selected_condition = get(handles.condition_selector, 'Value');
length_templates = length(handles.stored_char_templates{selected_condition}.char_templates);

% get cycle range of interest to average
[start_cycle, end_cycle] = getCycles(handles.avg_data,handles,max_cycles);

% gets elements within the selected range of cycles
range_of_interest = window_size*(max_cycles-start_cycle)+1:window_size*(max_cycles-end_cycle)+window_size;
  
figure1 = figure(10); %#ok<*NASGU>

% get correlation map data for selected condition
combined_corr_map = handles.stored_char_templates{selected_condition}.char_templates(1).corr_map;
combined_corr_map(~isnan(combined_corr_map)) = 0; % create blank map

for index = 1:length_templates % do following for each found template
    % open new figure when there are 5 common patterns loaded in last window
    if mod(index,5)==1 && index~=1
        counter = counter + 1;
        figure1 = figure(10+counter);
    end
    
    subplot(3,5,index-(5*counter)); % split figure into 3 rows and 5 columns
    
    % get correlation maps for found pattern at current index
    curr_corr_maps = handles.stored_char_templates{selected_condition}.char_templates(index);
    sum_corr_maps = handles.stored_char_templates{selected_condition}.char_templates(index).corr_map;
    aligned_range = {};

    for corr_condense = 1:length(curr_corr_maps.patterns)
        len_currMap = length(curr_corr_maps.patterns{corr_condense});
        if curr_corr_maps.shift(corr_condense) < 1 % if shift value is negative, shift left
            aligned_range{corr_condense} = [len_currMap + curr_corr_maps.shift(corr_condense):len_currMap, 1:len_currMap + curr_corr_maps.shift(corr_condense)-1];
        elseif curr_corr_maps.shift(corr_condense) > 1 % if shift value is positive, shift right
            aligned_range{corr_condense} = [curr_corr_maps.shift(corr_condense):len_currMap, 1:curr_corr_maps.shift(corr_condense)-1];
        else % if no shift, do nothing
            aligned_range{corr_condense} = 1:len_currMap;
        end
    end
        
    color_corr_map = sum_corr_maps;
    color_corr_map(abs(sum_corr_maps)>0) = 1;
    sum_corr_maps(abs(sum_corr_maps)>0) = sum_corr_maps(abs(sum_corr_maps)>0) - 2;
    combined_corr_map = combined_corr_map + (index*color_corr_map);
%     pcolor(w, sum_corr_maps); % uncomment to use pcolor instead of surf
%     set(w, 'YDir', 'reverse'); % uncomment to use pcolor instead of surf
    surf(sum_corr_maps) % comment to use pcolor instead of surf
    view([0 -90])
    grid off
    axis off
    axis tight
    cmap = colormap(winter(21));
    cmap(22,:) = [0 0 0];
    cmap = [cmap; colormap(autumn(21))];
    colormap(cmap);
    caxis([-21 21]);
    c = colorbar('southoutside');
    c.Label.String = 'Shift [accquisitions]';

    % if plotting individual patterns is checked
    if get(handles.indiv_profiles_checkbox, 'Value')
        sum_templates = {};
        sum_templates{1} = (curr_corr_maps.patterns{1}(aligned_range{1})-mean(curr_corr_maps.patterns{1}(aligned_range{1})))/std(curr_corr_maps.patterns{1}(aligned_range{1})); % get first value to show
    else % plot average pattern
        sum_templates = curr_corr_maps.patterns{1}(aligned_range{1});
    end

    for corr_condense = 2:length(curr_corr_maps.patterns)
        if get(handles.indiv_profiles_checkbox, 'Value')
            sum_templates{corr_condense} = (curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})-mean(curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})))/std(curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense})); %get first value to show
        else
            sum_templates = sum_templates + curr_corr_maps.patterns{corr_condense}(aligned_range{corr_condense});
        end
    end

    subplot(3,5,(index+5)-(5*counter))
    if get(handles.indiv_profiles_checkbox, 'Value')
        stored_templates = cell2mat(sum_templates);
        plot(stored_templates);
    else
        plot(sum_templates/length(curr_corr_maps.patterns))
    end
    title([num2str(size(handles.stored_char_templates{selected_condition}.char_templates(index).patterns,2)) ' Matches']);

    subplot(3,5,(index+10)-(5*counter))
    if get(handles.indiv_profiles_checkbox, 'Value')
        fft_templates = {};
        
        L = length(sum_templates{1});
        sinefft = fft(sum_templates{1});
        f = handles.Fs*(0:floor(L/2))/L;
        P2 = abs(sinefft/L);
        fft_templates{1} = P2(1:floor(L/2+1));
        fft_templates{1}(2:end-1) = 2*fft_templates{1}(2:end-1);
        
        plot(f, fft_templates{1})
        hold on
    else
        L = length(sum_templates);
        sinefft = fft(sum_templates);
        f = handles.Fs*(0:floor(L/2))/L;
        P2 = abs(sinefft/L);
        fft_templates = P2(1:floor(L/2+1));
        fft_templates(2:end-1) = 2*fft_templates(2:end-1);
        
        plot(f, fft_templates);
    end
    
   for corr_condense = 2:length(curr_corr_maps.patterns)
       if get(handles.indiv_profiles_checkbox, 'Value')
           L = length(sum_templates{corr_condense});
           sinefft = fft(sum_templates{corr_condense});
           f = handles.Fs*(0:floor(L/2))/L;
           P2 = abs(sinefft/L);
           fft_templates{corr_condense} = P2(1:floor(L/2+1));
           fft_templates{corr_condense}(2:end-1) = 2*fft_templates{corr_condense}(2:end-1);

           plot(f, fft_templates{corr_condense})
       end
   end
    
   hold off
   title('FFT');
   xlabel('Frequency [Hz]');
   ylabel('|Y(f)|');
end

if get(handles.show_corr_map_overlay, 'Value')
    figure(90);
%     pcolor(w, combined_corr_map); % uncomment to use pcolor instead of surf
%     set(w, 'YDir', 'reverse'); % uncomment to use pcolor instead of surf
    surf(combined_corr_map) % comment to use pcolor instead of surf
    view([0 -90])
    grid off
    axis off
    axis tight
    cmap = colormap(colorcube(max(max(combined_corr_map))));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    c = colorbar('southoutside');
    c.Label.String = 'Pattern #';
    c.FontSize = 12;
    c.FontWeight = 'Bold';
end

% --------------------------------------------------------------------
function handles = parse_tekscan_map(hObject, handles)

% Split tekscan map either into left/right half or all

% set the range of sensels depending on whether left/right/both selected by
% user
if get(handles.left_plateau, 'Value')
    handles.xstart = 1; handles.xend = handles.tekvar{1}.header.rows;
    handles.ystart = 1; handles.yend = round(handles.tekvar{1}.header.cols/2);
elseif get(handles.right_plateau, 'Value')
    handles.xstart = 1; handles.xend = handles.tekvar{1}.header.rows;
    handles.ystart = handles.tekvar{1}.header.cols-round(handles.tekvar{1}.header.cols/2)+1; 
    handles.yend = handles.tekvar{1}.header.cols;
else
    handles.xstart = 1; handles.xend = handles.tekvar{1}.header.rows;
    handles.ystart = 1; handles.yend = handles.tekvar{1}.header.cols;
end

% run for all comparisons
for var_count = 1:handles.comparison
    s_f=handles.tekvar{var_count}.data_a.sensel(handles.xstart:handles.xend,handles.ystart:handles.yend,:);
    s_f(isnan(s_f))=0;
    sigma_s=sum(sum(s_f));
    size_sigma_s = size(sigma_s,3);
    
    handles.force{var_count}=reshape(sigma_s,size_sigma_s,1)*handles.tekvar{var_count}.header.sensel_area*handles.scale_factor{var_count};
    
    handles.senselvar{var_count} = NaN*ones(size(handles.tekvar{var_count}.data_a.sensel));
    handles.senselvar{var_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :) = handles.tekvar{var_count}.data_a.sensel(handles.xstart:handles.xend, handles.ystart:handles.yend, :)*handles.scale_factor{var_count};
  
    %Break apart sensel matrix into cell array
    handles.sensels{var_count} = mat2cell(handles.tekvar{var_count}.data_a.sensel, ones(size(handles.tekvar{var_count}.data_a.sensel,1),1)...
        , ones(size(handles.tekvar{var_count}.data_a.sensel,2),1), size(handles.tekvar{var_count}.data_a.time,1));    
end

handles.cycle_tracker_max = max(cell2mat(handles.force));

elapsedtime = 0;
sensel_tracker = 0;

h = waitbar(0,'Reparsing Sensels...','Name','Parsing Sensels',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');

setappdata(h,'canceling',0)
tic

try
    for var_outer_count = 1:handles.comparison
        for var_inner_count = 1:handles.comparison
            if  handles.mag_calced
                handles.magnitude_risk{var_outer_count,var_inner_count} = NaN*ones(size(handles.total_magnitude_risk{var_outer_count,var_inner_count}));
                handles.magnitude_risk{var_outer_count,var_inner_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :) = handles.total_magnitude_risk{var_outer_count,var_inner_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :);
            end
            if handles.load_calced
                handles.load_risk{var_outer_count,var_inner_count} = NaN*ones(size(handles.total_load_risk{var_outer_count,var_inner_count}));
                handles.load_risk{var_outer_count,var_inner_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :) = handles.total_load_risk{var_outer_count,var_inner_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :);
            end
            elapsedtime = elapsedtime + toc;
            tic
            sensel_tracker = sensel_tracker+1;
            if mod(sensel_tracker, 10)==0
                waitbar(sensel_tracker / (handles.comparison^2),h,['Time Remaining: ' sprintf('%i',floor((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime),3600)/60)) ':' sprintf('%02.4f',rem(rem((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime),3600),60))...
                    sprintf('     Time Elapsed: ') sprintf('%i',floor(elapsedtime/3600)) ':' sprintf('%i',floor(rem(elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem(elapsedtime,3600),60))])
            end
        end
    end
    
    delete(h);
    
catch ME
    delete(h);
    rethrow(ME);
end

% --------------------------------------------------------------------
function initialize(hObject, handles)

%reset all menu items to default settings
set(handles.cycle_tracker_axes, 'HitTest', 'off');
set(handles.pattern_register, 'Checked', 'off');
set(handles.second_axis, 'Visible', 'off');
set(handles.run, 'Enable', 'on');
handles.useMaxSat = false;

set(handles.both_plateaus, 'Value', 1);

%Set start and end sensel positions for current sensor
handles.xstart = 1; handles.xend = handles.tekvar{1}.header.rows; %NOTE: X and Y are actually reversed throughout code since rows are the Y values and cols are the X values
handles.ystart = 1; handles.yend = handles.tekvar{1}.header.cols;

%% Initialize all tekscan maps opened
for var_count = 1:handles.comparison
    
    s_f=handles.tekvar{var_count}.data_a.sensel(handles.xstart:handles.xend,handles.ystart:handles.yend,:); %get stress map data for current tekscan map
    s_f(isnan(s_f))=0; %convert all non-numeric values to 0
    sigma_s=sum(sum(s_f)); %get total stress for each frame
    size_sigma_s = size(sigma_s,3); %get number of frames
    
    handles.force{var_count}=reshape(sigma_s,size_sigma_s,1)*handles.tekvar{var_count}.header.sensel_area; %total force (convert from stress) for each frame, use reshape function to change matrix from m x n x o matrix to a (m*n*o) x 1 matrix
    
    handles.senselvar{var_count} = NaN*ones(size(handles.tekvar{var_count}.data_a.sensel)); %Initialize senselvar for total number of frames
    handles.senselvar{var_count}(handles.xstart:handles.xend, handles.ystart:handles.yend, :) = handles.tekvar{var_count}.data_a.sensel(handles.xstart:handles.xend, handles.ystart:handles.yend, :); %copy sensel data over to senselvar
     
    %If "Equalize Total Force" is checked... determine the scale factor from first tekscan map
    if sum(handles.force{var_count}) ~= sum(handles.force{1}) && strcmp(get(handles.eq_total_force, 'Checked'), 'on')
        handles.scale_factor{var_count} = sum(handles.force{1})/sum(handles.force{var_count}); %calculate scale factor for current map
        handles.senselvar{var_count} = handles.senselvar{var_count}*handles.scale_factor{var_count}; %scale stress maps
        handles.force{var_count} = handles.force{var_count}*handles.scale_factor{var_count}; %scale total force
    else
        handles.scale_factor{var_count} = 1; %set scale factor to 1 if not scaling
    end
    
    %Break apart sensel matrix into cell array where each {m n} cell
    %contains the stress over acquisition time at each sensel
    handles.sensels{var_count} = mat2cell(handles.tekvar{var_count}.data_a.sensel, ones(size(handles.tekvar{var_count}.data_a.sensel,1),1)...
        , ones(size(handles.tekvar{var_count}.data_a.sensel,2),1), size(handles.tekvar{var_count}.data_a.sensel,3));
    
end

selected_condition = get(handles.condition_selector, 'Value'); %get index value for currently selected tekscan map
handles.min_crange = 0; %sets the minimum value for the stress map
handles.max_crange = max(max(max(cell2mat(handles.senselvar)))); %sets the maximum value for the stress maps based on the maximum stress for all open tekscan files
handles.cycle_tracker_max(selected_condition) = max(handles.force{selected_condition}); %set the maximum force and use it to set the max force in the force plot
handles.auto_max_crange = handles.max_crange; %flag to decide whether to use user input max stress range or to determine max stress range automatically

%Sample Collection Parameters
handles.T = handles.tekvar{1}.header.seconds_per_frame; %Sample time (s)
handles.Fs = 1/handles.T; %Sampling Frequency (Hz)
handles.Tl = str2double(get(handles.cycle_time, 'String')); %Gait Cycle time (s)
handles.stored_char_templates = {}; %where characteristic curves are stored
handles.centroid_loc = []; %location of the Weighted Center of Contact Stress
handles.time_reg_auto = false; %true/false on whether or not to align the total force plots for all open tekscan files
handles.time_shift_by{1} = 0; %how much to shift each total force plot by to match the first open case (or a template file)
handles.mag_calced = 0; %flag to determine if magnitude difference calculations have been performed
handles.load_calced = 0; %flag to determine if loading pattern difference calculations have been performed

handles.window_size = floor(handles.Fs*handles.Tl);  %Sets default window size (Default value is based on 1 cycle/2 sec recording data at 10 Hz)
handles.length_time = size(handles.tekvar{1}.data_a.time,1); %Length of the time vector
handles.time_order{1} = 1:handles.length_time; %This variable is used to manipulate the order of vector elements in the time vector
handles.range_plotting = [1, handles.window_size]; % sets default range of frames to plot using 'Tools'->'Plotting'

set(handles.registration, 'Enable', 'on') %activates the registration button

%execute following code if there are more than 1 tekscan files open
if handles.comparison > 1 
    set(handles.calc, 'Enable', 'on') %enable "Calculate" menu
    set(handles.smag, 'Enable', 'on') %enable "Save Comparisons" menu list
    
    %execute if "Automated time registration" is checked
    if handles.time_reg_auto
        [handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, false);
        handles.time_reg_auto = true;
        guidata(hObject, handles);
    else
        for var_count = 1:handles.comparison
            % set up variables
            handles.time_order{var_count} = 1:handles.length_time;
            handles.time_shift_by{var_count} = 0;
        end
    end

    %initialize the following GUI elements
    set(handles.condition_selector, 'String', {}); %Tekscan File Dropdown Menu
    set(handles.comparison_selector, 'String', {}); %Tekscan comparison file Dropdown box
    set(handles.condition_selector, 'String', handles.tekvar_name); %use cell array containing all tekscan file names as values for dropdow box
    set(handles.comparison_selector, 'String', handles.tekvar_name); %use cell array containing all tekscan file names as values for dropdow box
    set(handles.risk_map_checkbox, 'Visible', 'off'); %hide risk map checkbox
    set(handles.mag_diff_scale, 'Enable', 'off'); %Disable "Auto Magnitude Scale Difference" item in menu
    set(handles.risk_type_dropdown, 'Visible', 'off'); %disable dropdown box for comparisons
    set(handles.risk_map_checkbox, 'Value', false); %turn off risk map checkbox
else
    set(handles.risk_map_checkbox, 'Visible', 'off'); %turn off risk map checkbox
    set(handles.mag_diff_scale, 'Enable', 'off') %Disable "Auto Magnitude Scale Difference" item in menu
    set(handles.risk_type_dropdown, 'Visible', 'off'); %hide risk map checkbox
    set(handles.calc, 'Enable', 'on') %disable comparison calculations menu item
    set(handles.smag, 'Enable', 'off') %disable "Save Comparisons" menu list
end    

%% Enable or Disable elements on the GUI
set(handles.save_corr_data, 'Enable', 'off')
set(handles.save_corr_maps, 'Enable', 'off')
set(handles.corr_maps_button, 'Enable', 'off')
set(handles.indiv_profiles_checkbox, 'Enable', 'off')

set(handles.pressure_map_slider, 'Max', handles.length_time);
if get(handles.pressure_map_slider, 'Value') > get(handles.pressure_map_slider, 'Max')
    set(handles.pressure_map_slider, 'Value', get(handles.pressure_map_slider, 'Max'));
end
set(handles.pressure_map_slider, 'SliderStep', [1/handles.length_time 0.1]);
set(handles.pressure_map_slider, 'Visible', 'on');

set(handles.axes2, 'YAxisLocation','right',...
    'YColor',[0.749 0.749 0],...
    'ColorOrder',[0 0.5 0;1 0 0;0 0.75 0.75;0.75 0 0.75;0.75 0.75 0;0.25 0.25 0.25;0 0 1],...
    'Color','none', 'HitTest', 'off');

set(handles.cycle_tracker_axes, 'HitTest', 'on');
set(handles.pressure_map, 'HitTest', 'on');

handles.avg_time = [];
handles.avg_senselvar = {};
handles.avg_force = {};
handles.avg_magnitude_risk = {};
handles.avg_load_risk = {};

set(handles.avg_data, 'Checked', 'off')

guidata(hObject, handles);

refresh_fig(hObject, handles);


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


function noise_floor_edit_Callback(hObject, eventdata, handles)
% hObject    handle to noise_floor_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of noise_floor_edit as text
%        str2double(get(hObject,'String')) returns contents of noise_floor_edit as a double
handles.min_crange = str2double(get(hObject, 'String'));

guidata(hObject, handles);
refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function noise_floor_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noise_floor_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in compare_checkbox.
function compare_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to compare_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of compare_checkbox


% --- Executes on button press in risk_map_checkbox.
function risk_map_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to risk_map_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of risk_map_checkbox

refresh_fig(hObject, handles);
    
% --- Executes on button press in indiv_profiles_checkbox.
function indiv_profiles_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to indiv_profiles_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of indiv_profiles_checkbox


function mr = magnitude_risk(handles, subdiv)

elapsedtime = 0;
sensel_tracker = 0;

h = waitbar(0,'Comparing Sensels...','Name','Calculating Magnitude Risk Map',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');

setappdata(h,'canceling',0)
tic

for var_count_outer = 1:handles.comparison
    for var_count_inner = 1:handles.comparison
        red_var = handles.senselvar{var_count_inner}(:,:,handles.time_order{var_count_inner});
        blue_var = handles.senselvar{var_count_outer}(:,:,handles.time_order{var_count_outer});
        
        red_var(red_var<get(handles.noise_floor_edit, 'Value')) = 0;
        blue_var(blue_var<get(handles.noise_floor_edit, 'Value')) = 0;
        
        if strcmpi(subdiv, 'div')
            mr{var_count_outer, var_count_inner} = red_var./blue_var;
            mr{var_count_outer, var_count_inner}(isinf(mr{var_count_outer, var_count_inner})) = 20;
        else
            mr{var_count_outer, var_count_inner} =  red_var - blue_var;
        end
        
        elapsedtime = elapsedtime + toc;
        tic
        sensel_tracker = sensel_tracker+1;
        if mod(sensel_tracker, 10)==0
            waitbar(sensel_tracker / (handles.comparison^2),h,['Time Remaining: ' sprintf('%i',floor((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime)/3600)) ':' sprintf('%i',floor(rem((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime),3600)/60)) ':' sprintf('%02.4f',rem(rem((elapsedtime/sensel_tracker*(handles.comparison^2)-elapsedtime),3600),60))...
                sprintf('     Time Elapsed: ') sprintf('%i',floor(elapsedtime/3600)) ':' sprintf('%i',floor(rem(elapsedtime,3600)/60)) ':' sprintf('%02.4f',rem(rem(elapsedtime,3600),60))])
        end
    end
end

delete(h);

% --- Executes on selection change in risk_type_dropdown.
function risk_type_dropdown_Callback(hObject, eventdata, handles)
% hObject    handle to risk_type_dropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns risk_type_dropdown contents as cell array
%        contents{get(hObject,'Value')} returns selected item from risk_type_dropdown

refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function risk_type_dropdown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to risk_type_dropdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function tools_Callback(hObject, eventdata, handles)
% hObject    handle to tools (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function time_reg_Callback(hObject, eventdata, handles)
% hObject    handle to time_reg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, true);
handles.time_reg_auto = true;

guidata(hObject, handles);

refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function quadrant_pressures_Callback(hObject, eventdata, handles)
% hObject    handle to quadrant_pressures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider

if get(handles.both_plateaus, 'Value') || get(handles.left_plateau, 'Value')
    figure(1001)
%     if get(handles.test_condition_toggle, 'Value')
        LP_AC = get_quadrant('LP_AC', handles.curr_plot);
%     else
%         LP_AC = get_quadrant('LP_AC', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(LP_AC); %creates a contour map of the current plateau with time
    else
        contourf(LP_AC, 90, 'LineStyle', 'none'); %creates a contour map of the current plateau with time
    end
    title({'Left Plateau: Anterio-Central'; ['Mean: ' num2str(mean(mean(LP_AC(~isnan(LP_AC))))) ' Max: ' num2str(max(max(LP_AC(~isnan(LP_AC)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1002)
%     if get(handles.test_condition_toggle, 'Value')
        LP_PC = get_quadrant('LP_PC', handles.curr_plot);
%     else
%         LP_PC = get_quadrant('LP_PC', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(LP_PC);
    else
        contourf(LP_PC, 90, 'LineStyle', 'none');
    end
    title({'Left Plateau: Posterio-Central'; ['Mean: ' num2str(mean(mean(LP_PC(~isnan(LP_PC))))) ' Max: ' num2str(max(max(LP_PC(~isnan(LP_PC)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1003)
%     if get(handles.test_condition_toggle, 'Value')
        LP_PP = get_quadrant('LP_PP', handles.curr_plot);
%     else
%         LP_PP = get_quadrant('LP_PP', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(LP_PP);
    else
        contourf(LP_PP, 90, 'LineStyle', 'none');
    end
    title({'Left Plateau: Posterio-Peripheral'; ['Mean: ' num2str(mean(mean(LP_PP(~isnan(LP_PP))))) ' Max: ' num2str(max(max(LP_PP(~isnan(LP_PP)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1004)
%     if get(handles.test_condition_toggle, 'Value')
        LP_AP = get_quadrant('LP_AP', handles.curr_plot);
%     else
%         LP_AP = get_quadrant('LP_AP', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(LP_AP);
    else
        contourf(LP_AP, 90, 'LineStyle', 'none');
    end
    title({'Left Plateau: Anterio-Peripheral'; ['Mean: ' num2str(mean(mean(LP_AP(~isnan(LP_AP))))) ' Max: ' num2str(max(max(LP_AP(~isnan(LP_AP)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);
end

if get(handles.both_plateaus, 'Value') || get(handles.right_plateau, 'Value')

    figure(1005)
%     if get(handles.test_condition_toggle, 'Value')
        RP_AC = get_quadrant('RP_AC', handles.curr_plot);
%     else
%         RP_AC = get_quadrant('RP_AC', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(RP_AC);
    else
        contourf(RP_AC, 90, 'LineStyle', 'none');
    end
    title({'Right Plateau: Anterio-Central'; ['Mean: ' num2str(mean(mean(RP_AC(~isnan(RP_AC))))) ' Max: ' num2str(max(max(RP_AC(~isnan(RP_AC)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1006)
%      if get(handles.test_condition_toggle, 'Value')
        RP_PC = get_quadrant('RP_PC', handles.curr_plot);
%     else
%         RP_PC = get_quadrant('RP_PC', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(RP_PC);
    else
        contourf(RP_PC, 90, 'LineStyle', 'none');
    end
    title({'Right Plateau: Posterio-Central'; ['Mean: ' num2str(mean(mean(RP_PC(~isnan(RP_PC))))) ' Max: ' num2str(max(max(RP_PC(~isnan(RP_PC)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1007)
%     if get(handles.test_condition_toggle, 'Value')
        RP_PP = get_quadrant('RP_PP', handles.curr_plot);
%     else
%         RP_PP = get_quadrant('RP_PP', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(RP_PP);
    else
        contourf(RP_PP, 90, 'LineStyle', 'none');
    end
    title({'Right Plateau: Posterio-Peripheral'; ['Mean: ' num2str(mean(mean(RP_PP(~isnan(RP_PP))))) ' Max: ' num2str(max(max(RP_PP(~isnan(RP_PP)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

    figure(1008)
%     if get(handles.test_condition_toggle, 'Value')
        RP_AP = get_quadrant('RP_AP', handles.curr_plot);
%     else
%         RP_AP = get_quadrant('RP_AP', handles.senselvar(:,:,index));
%     end
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(RP_AP);
    else
        contourf(RP_AP, 90, 'LineStyle', 'none');
    end
    title({'Right Plateau: Anterio-Peripheral'; ['Mean: ' num2str(mean(mean(RP_AP(~isnan(RP_AP))))) ' Max: ' num2str(max(max(RP_AP(~isnan(RP_AP)))))]});
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);
    caxis([handles.min_crange handles.max_crange]);

end

% --------------------------------------------------------------------
function calc_Callback(hObject, eventdata, handles)
% hObject    handle to calc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mag_risk_Callback(hObject, eventdata, handles)
% hObject    handle to mag_risk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.time_reg_auto
    [handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, false);
    handles.time_reg_auto = true;
    guidata(hObject, handles);
end
handles.total_magnitude_risk = magnitude_risk(handles,'sub');
handles.magnitude_risk = handles.total_magnitude_risk;
handles.min_mag_crange = min(min(min(cell2mat(handles.magnitude_risk))));
handles.max_mag_crange = max(max(max(cell2mat(handles.magnitude_risk))));
handles.mag_calced = 1;

set(handles.risk_map_checkbox, 'Visible', 'on');
set(handles.mag_diff_scale, 'Enable', 'on')
set(handles.risk_type_dropdown, 'Visible', 'off');
set(handles.risk_map_checkbox, 'Value', false);

guidata(hObject,handles);


% --------------------------------------------------------------------
function pattern_risk_Callback(hObject, eventdata, handles)
% hObject    handle to pattern_risk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.total_load_risk = load_profile_risk(handles);
handles.load_risk = handles.total_load_risk;
handles.load_calced = 1;

set(handles.risk_map_checkbox, 'Visible', 'on');
set(handles.mag_diff_scale, 'Enable', 'on')
set(handles.risk_type_dropdown, 'Visible', 'off');
set(handles.risk_map_checkbox, 'Value', false);

guidata(hObject,handles);


% --------------------------------------------------------------------
function save_img_Callback(hObject, eventdata, handles)
% hObject    handle to save_img (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.tiff','Tiff File(*.tiff)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Current Pressure Map', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    scalefactor = 2;

    index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
    figure1 = figure;
    figure1.GraphicsSmoothing = 'on';
    
    % Create and format axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21],...
        'YMinorGrid','off',...
        'YGrid','off',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37],...
        'XMinorGrid','off',...
        'XGrid','off',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[handles.min_crange handles.max_crange]);
       
    % colorbar %Adds a color bar denoting heatmap values
    box(axes1,'on');
    hold(axes1,'all');
    selected_condition = get(handles.condition_selector, 'Value');

    if strcmp(get(handles.avg_data, 'Checked'), 'on')
        senselvar = handles.avg_senselvar;
        time_order = handles.avg_time_order;
        time = handles.avg_time;
        if  handles.mag_calced
            magnitude_risk = handles.avg_magnitude_risk;
        end
    else
        senselvar = handles.senselvar;
        time_order = handles.time_order;
        time = handles.tekvar{selected_condition}.data_a.time;
        if  handles.mag_calced
            magnitude_risk = handles.magnitude_risk;
        end
    end
    
    curr_plot = senselvar{selected_condition}(:,:,time_order{selected_condition}(index));

    if strcmp(get(handles.surf_on, 'Checked'), 'on')
        surf(curr_plot)
        view([0 -90]);
        grid off
        axis off
    elseif strcmp(get(handles.contour_on, 'Checked'), 'on')
        contourf(curr_plot, 90, 'LineStyle','none');
    else
        p = pcolor(senselvar{selected_condition}(:,:,time_order{selected_condition}(index)));
        p.LineStyle = 'none';
        set(axes1,'YDir', 'reverse');
        axis off
    end
    
    cmap = colormap(jet(255));
    cmap = [0 0 0; cmap];
    colormap(cmap);

    % Create colorbar
    axis equal
    c = colorbar(axes1);
    c.Location = 'eastoutside';
    c.Label.String = ['Stress [' handles.tekvar{selected_condition}.header.units ']'];
    c.FontSize = 12*scalefactor;
    c.FontWeight = 'Bold';
    ax_pos = axes1.Position;
    c.Position(3) = 1.5*c.Position(3);
    axes1.Position = ax_pos;
    
    % Show ROI using settings in Options
    if handles.curr_select_flag == 1
        ROI_show = questdlg('Show ROI?', ...
            'Show ROI', ...
            'Yes', 'No', 'Yes');
        
        if strcmp(ROI_show, 'Yes')
            loc = rem(index,handles.window_size);
            if loc == 0
                loc = handles.window_size;
            end
            curr_select = curr_plot*NaN;
            overlay = curr_select;
            curr_select(handles.in(:,:,loc) == 1) = curr_plot(handles.in(:,:,loc) == 1);
            overlay(handles.in(:,:,loc) == 1 & curr_plot>0) = 1e-100;
            
            if strcmp(get(handles.show_ROI, 'Checked'), 'on')
                if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                    plot(round(handles.roibnd{1,loc}(:,1)),round(handles.roibnd{1,loc}(:,2)),'-r','LineWidth', 3);
                else
                    plot(handles.roibnd{1,loc}(:,1),handles.roibnd{1,loc}(:,2),'-r','LineWidth', 3);
                end
            end
            
            if strcmp(get(handles.highlight_ROI, 'Checked'), 'on')
                if strcmp(get(handles.surf_on, 'Checked'), 'on')
                    e2 = surf(overlay);
                elseif strcmp(get(handles.contour_on, 'Checked'), 'on')
                    e2 = contourf(overlay, 90, 'LineStyle','none');
                else
                    e2 = pcolor(overlay);
                end
                e2.LineStyle = 'none';
                set(e2,'facealpha',handles.h_transp);
                e2.CData(e2.CData>0) = handles.max_crange* handles.highlight;
            end
            
            handles.curr_plot = handles.curr_select;
        end
    end
        
    % Show WCoCS Vector Arrows    
    Knee_side = questdlg('Plot WCoCs Path?', ...
    'Plot Path', ...
    'Yes','No','Yes');

    if strcmp(Knee_side, 'Yes')
        toeoff = 58;

        hold on
        var_cos = save_centroid(handles, handles.range_plotting(1):handles.range_plotting(2));
        
        if get(handles.left_plateau, 'Value')
            var_cos = var_cos(2:end,4:7);
        elseif get(handles.right_plateau, 'Value')
            var_cos = var_cos(2:end,8:11);
        elseif get(handles.both_plateaus, 'Value')
            var_cos = var_cos(2:end,4:end);
        end
        
        var_cos = cell2mat(var_cos);
        
        cycletime = str2num(get(handles.cycle_time, 'String'));
        NumofCycle = round(size(var_cos,1)/(handles.Fs*cycletime)); %cycle is 2s
        var_cos_mean = zeros(handles.Fs*cycletime,size(var_cos,2));
        for i = 1:NumofCycle
            var_cos_mean = var_cos_mean + var_cos(1 + (i-1)*cycletime*handles.Fs:i*cycletime*handles.Fs, :);
        end
        var_cos_mean = var_cos_mean/NumofCycle;
        var_cos_mean = convert100(var_cos_mean, 1:cycletime*handles.Fs, 100);

        if get(handles.both_plateaus, 'Value')
            %Left Plateau
            quiver(var_cos_mean(1:toeoff-1,1)/2,var_cos_mean(1:toeoff-1,3)/2,var_cos_mean(2:toeoff,2),var_cos_mean(2:toeoff,4),'Color', [1 1 1],'linewidth',0.8*scalefactor,'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p1 = quiver(var_cos_mean(1:toeoff-1,1)/2,var_cos_mean(1:toeoff-1,3)/2,var_cos_mean(2:toeoff,2),var_cos_mean(2:toeoff,4),'Color', [0 0 0.8],'linewidth',0.5*scalefactor,'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            quiver(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,var_cos_mean([toeoff+1:end 1],2),var_cos_mean([toeoff+1:end 1],4),'color', [1 1 1],'linewidth',0.8*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p2 = quiver(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,var_cos_mean([toeoff+1:end 1],2),var_cos_mean([toeoff+1:end 1],4),'color', [0.8 0.8 0.8],'linewidth',0.5*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p3 = plot(var_cos_mean(1,1)/2,var_cos_mean(1,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
            %Right Plateau
            quiver(var_cos_mean(1:toeoff-1,5)/2,var_cos_mean(1:toeoff-1,7)/2,var_cos_mean(2:toeoff,6),var_cos_mean(2:toeoff,8),'color', [1 1 1],'linewidth',0.8*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            l1 = quiver(var_cos_mean(1:toeoff-1,5)/2,var_cos_mean(1:toeoff-1,7)/2,var_cos_mean(2:toeoff,6),var_cos_mean(2:toeoff,8),'color', [0 0.7 0.7],'linewidth',0.5*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            quiver(var_cos_mean(toeoff:end,5)/2,var_cos_mean(toeoff:end,7)/2,var_cos_mean([toeoff+1:end 1],6),var_cos_mean([toeoff+1:end 1],8),'color', [1 1 1],'linewidth',0.8*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            l2 = quiver(var_cos_mean(toeoff:end,5)/2,var_cos_mean(toeoff:end,7)/2,var_cos_mean([toeoff+1:end 1],6),var_cos_mean([toeoff+1:end 1],8),'color', [0.7 0.7 0.7],'linewidth',0.5*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            l3 = plot(var_cos_mean(1,5)/2,var_cos_mean(1,7)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
            leg = [p1 p2 p3 l1 l2 l3];
            txt = {'Medial Stance', 'Medial Swing', 'Medial Start', 'Lateral Stance', 'Lateral Swing', 'Lateral Start'};
            counter = 1;
            while counter <= length(leg)
                if sum(isnan(leg(counter).XData))
                    leg(counter) = [];
                    txt(counter) = [];
                else
                    counter = counter + 1;
                end
            end
            legend(leg, txt, 'Location', 'south');
        elseif get(handles.left_plateau, 'Value')
            quiver(var_cos_mean(1:toeoff-1,1)/2,var_cos_mean(1:toeoff-1,3)/2,var_cos_mean(2:toeoff,2),var_cos_mean(2:toeoff,4),'Color', [1 1 1],'linewidth',0.8*scalefactor,'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p1 = quiver(var_cos_mean(1:toeoff-1,1)/2,var_cos_mean(1:toeoff-1,3)/2,var_cos_mean(2:toeoff,2),var_cos_mean(2:toeoff,4),'Color', [0 0 0.8],'linewidth',0.5*scalefactor,'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            quiver(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,var_cos_mean([toeoff+1:end 1],2),var_cos_mean([toeoff+1:end 1],4),'color', [1 1 1],'linewidth',0.8*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p2 = quiver(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,var_cos_mean([toeoff+1:end 1],2),var_cos_mean([toeoff+1:end 1],4),'color', [0.8 0.8 0.8],'linewidth',0.5*scalefactor, 'maxheadsize', 0.8, 'alignvertexcenters', 'on'); box on;
            p3 = plot(var_cos_mean(1,1)/2,var_cos_mean(1,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
            legend([p1 p2 p3], 'Medial Stance', 'Medial Swing', 'Medial Start', 'location', 'southwest');
        else
            l1 = plot(var_cos_mean(1:toeoff,1)/2,var_cos_mean(1:toeoff,3)/2,'o-m','linewidth',0.5, 'markersize',3,'markerfacecolor','m'); box on;
            l2 = plot(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,'o-k','linewidth',0.5, 'markersize',3,'markerfacecolor','k'); box on;
            l3 = plot(var_cos_mean(toeoff,1)/2,var_cos_mean(toeoff,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
            legend([l1 l2 l3], 'Lateral Stance', 'Lateral Swing', 'Lateral Start', 'location', 'southeast');
        end
    end
    
    if strcmp(get(handles.centroid, 'Checked'), 'on') && strcmp(Knee_side, 'No')
        rows = handles.tekvar{selected_condition}.header.rows;
        cols = handles.tekvar{selected_condition}.header.cols;
        
        if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            [I, J] = centroid_location(abs(handles.curr_plot(1:rows,1:round(cols/2))), str2num(get(handles.noise_floor_edit, 'String')), true);
            hold on
            plot(J, I, 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],...
                'MarkerSize',15,...
                'Marker','pentagram',...
                'LineStyle','none');
            hold off
        end
        
        if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            [I, J] = centroid_location(abs(handles.curr_plot(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), true);
            hold on
            plot(J+cols/2, I, 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],...
                'MarkerSize',15,...
                'Marker','pentagram',...
                'LineStyle','none');
            hold off
        end
    end

    set(figure1, 'Position', [0 0 scalefactor*550 scalefactor*440], 'PaperPositionMode', 'auto');

    print(figure1, '-dtiff', [pathfile file], '-r400')

    close(figure1)
end

% --------------------------------------------------------------------
function centroid_Callback(hObject, eventdata, handles)
% hObject    handle to centroid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
    set(handles.centroid_loc_text, 'String', ' ');
    set(handles.centroid_loc_text2, 'String', ' ');
else
    set(hObject, 'Checked', 'on')
end

guidata(hObject, handles)

refresh_fig(hObject, handles)

% --------------------------------------------------------------------
function pressure_measurement_Callback(hObject, eventdata, handles)
% hObject    handle to pressure_measurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%     choice = questdlg('Select Area?', ...
%         'Comparison', ...
%         'Yes','No','No');

if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
    set(handles.stats01, 'String', ' ');
    set(handles.stats02, 'String', ' ');
    set(handles.stats03, 'String', ' ');
else
    set(hObject, 'Checked', 'on')
end

guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function smag_Callback(hObject, eventdata, handles)
% hObject    handle to smag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_load_pattern_diff_Callback(hObject, eventdata, handles)
% hObject    handle to save_load_pattern_diff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.tiff','Tiff File(*.tiff)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Load Pattern Difference Map', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
        
    [filename, tok] = strtok(file, '.');
    scalefactor = 2;
    
    index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
    figure1 = figure;
    figure1.GraphicsSmoothing = 'on';
    
    selected_condition = get(handles.condition_selector, 'Value');

    selected_comparison = get(handles.comparison_selector, 'Value');
    
    load_risk = handles.load_risk{selected_condition, selected_comparison};

    % Create axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','on',...
        'YGrid','on',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','on',...
        'XGrid','on',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[0 1]);
    % Uncomment the following line to preserve the X-limits of the axes
%     xlim(axes1,[0 35]);
    % Uncomment the following line to preserve the Y-limits of the axes
%     ylim(axes1,[0 23]);
    
    % colorbar %Adds a color bar denoting heatmap values
    box(axes1,'on');
    hold(axes1,'all');
    
%     pcolor(load_risk)
%     contour(handles.load_risk,'LineColor',[0 0 0],'Fill','on');
%     if strcmp(get(handles.surf_on, 'Checked'), 'on')
%         surf(load_risk)
%         view([0 -90]);
%         grid off
%         axis off
%     elseif strcmp(get(handles.contour_on, 'Checked'), 'on')
%         contourf(load_risk, 90, 'LineStyle','none');
%     else
%         p = pcolor(load_risk);
%         p.LineStyle = 'none';
%         set(axes1,'YDir', 'reverse');
%     end
    
    surf(load_risk)
    view([0 -90])
    grid off
    axis off
    axis equal
    
    caxis(handles.pressure_map, [0 1])
    cmap = colormap(hsv(255));
    cmap = [0 0 0; cmap(end:-1:1,:)];
    colormap(cmap);

    % Create colorbar
    colorbar('peer',axes1);

    set(figure1, 'Position', [0 0 scalefactor*550 scalefactor*440], 'PaperPositionMode', 'auto');

    print(figure1, '-dtiff', [pathfile filename '_pattdiff' tok], '-r400')
    
    save([pathfile filename '_pattdiff.mat'], 'load_risk');
    
    close(figure1)
end


% --------------------------------------------------------------------
function save_mag_diff_Callback(hObject, eventdata, handles)
% hObject    handle to save_mag_diff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.tiff','Tiff File(*.tiff)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Magnitude Difference Map', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);

    index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
    selected_condition = get(handles.condition_selector, 'Value');
    selected_comparison = get(handles.comparison_selector, 'Value');
    figure1 = figure;
    
    % Create axes
    % Create axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','on',...
        'YGrid','on',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','on',...
        'XGrid','on',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
    % Uncomment the following line to preserve the X-limits of the axes
    xlim(axes1,[0 35]);
    % Uncomment the following line to preserve the Y-limits of the axes
    ylim(axes1,[0 23]);
    
    box(axes1,'on');
    hold(axes1,'all');
    
    if strcmp(get(handles.contour_on, 'Checked'), 'off')
        pcolor(handles.magnitude_risk{selected_condition, selected_comparison}(:,:,index));
    else
        contour(handles.magnitude_risk(:,:,index),'LineColor',[0 0 0],'Fill','on');
    end
    axis equal

    % Create colorbar
    cmap = colormap(jet(256));
    cmap(256/2+1,:) = [0 0 0];
    colormap(cmap);
    colorbar('peer',axes1);
    
    print(figure1, '-dtiff', [pathfile file])
    
    close(figure1)
end


% --------------------------------------------------------------------
function save_maxmin_mag_diff_Callback(hObject, eventdata, handles)
% hObject    handle to save_maxmin_mag_diff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.tiff','Tiff File(*.tiff)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Max/Min Magnitude Difference Map', handles.path);

[token, rem] = strtok(file, '.');

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    scalefactor = 2;
    
    selected_condition = get(handles.condition_selector, 'Value');

    selected_comparison = get(handles.comparison_selector, 'Value');
%%    
    max_mag_risk = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
    reshape_mag_risk = reshape(max_mag_risk, numel(max_mag_risk),1);
    reshape_mag_risk(isnan(reshape_mag_risk)) = 0;
    elements_to_take = floor(0.95*numel(reshape_mag_risk));
    sorted_mag_risk = sort(reshape_mag_risk);
    fraction_mag_risk_total = max_mag_risk;
    fraction_mag_risk_total(~isnan(fraction_mag_risk_total)) = 0;
    fraction_mag_risk_total(max_mag_risk>sorted_mag_risk(elements_to_take)) = max_mag_risk(max_mag_risk>sorted_mag_risk(elements_to_take));
    
%     max_mag_risk = fraction_mag_risk_total;
    
    figure1 = figure;
    
    % Create axes
    % Create axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','on',...
        'YGrid','on',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','on',...
        'XGrid','on',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[handles.min_mag_crange handles.max_mag_crange]);
    % Uncomment the following line to preserve the X-limits of the axes
    xlim(axes1,[0 35]);
    % Uncomment the following line to preserve the Y-limits of the axes
    ylim(axes1,[0 23]);
    
    % colorbar %Adds a color bar denoting heatmap values
    box(axes1,'on');
%     hold(axes1,'all');

    surf(max_mag_risk(end:-1:1,:));
    axis off
    grid off
    view(2);
    axis equal
    xlim([0 handles.tekvar{selected_comparison}.header.cols+1]);
    ylim([0 handles.tekvar{selected_comparison}.header.rows+1]);
    
    % Create colorbar
    cmap = colormap(jet(255));
    cmap(floor(255/2+1),:) = [0 0 0];
    caxis([-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
    colormap(cmap);
    colorbar

    set(figure1, 'Position', [0 0 scalefactor*550 scalefactor*440], 'PaperPositionMode', 'auto');

    print(figure1, '-dtiff', [pathfile token '_max' rem], '-r400')

    close(figure1);
%%    
    min_mag_risk = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
    reshape_mag_risk = reshape(min_mag_risk, numel(min_mag_risk),1);
    reshape_mag_risk(isnan(reshape_mag_risk)) = 0;
    elements_to_take = floor(0.05*numel(reshape_mag_risk));
    sorted_mag_risk = sort(reshape_mag_risk);
    fraction_mag_risk_total = min_mag_risk;
    fraction_mag_risk_total(~isnan(fraction_mag_risk_total)) = 0;
    fraction_mag_risk_total(min_mag_risk<sorted_mag_risk(elements_to_take)) = min_mag_risk(min_mag_risk<sorted_mag_risk(elements_to_take));
    
%     min_mag_risk = fraction_mag_risk_total;
    
    figure1 = figure;
    
    % Create axes
    % Create axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','on',...
        'YGrid','on',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','on',...
        'XGrid','on',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[handles.min_mag_crange handles.max_mag_crange]);
    % Uncomment the following line to preserve the X-limits of the axes
    xlim(axes1,[0 35]);
    % Uncomment the following line to preserve the Y-limits of the axes
    ylim(axes1,[0 23]);
    
    % colorbar %Adds a color bar denoting heatmap values
    box(axes1,'on');
%     hold(axes1,'all');

    surf(min_mag_risk(end:-1:1,:));
    axis off
    grid off
    view(2);
    axis equal
    xlim([0 handles.tekvar{selected_comparison}.header.cols+1]);
    ylim([0 handles.tekvar{selected_comparison}.header.rows+1]);
    
    % Create colorbar
    cmap = colormap(jet(255));
    cmap(floor(255/2+1),:) = [0 0 0];
    caxis([-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
    colormap(cmap);
    colorbar

    set(figure1, 'Position', [0 0 scalefactor*550 scalefactor*440], 'PaperPositionMode', 'auto');
        
    print(figure1, '-dtiff', [pathfile token '_min' rem], '-r300')
    
    close(figure1);
%%
    mag_risk_total = handles.magnitude_risk{selected_condition, selected_comparison}(:,:,1);
    mag_risk_total(max_mag_risk>=abs(min_mag_risk)) = max_mag_risk(max_mag_risk>=abs(min_mag_risk));
    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
    
    figure1 = figure;
    
    % Create axes
    % Create axes
    axes1 = axes('Parent',figure1,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','off',...
        'YGrid','off',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','off',...
        'XGrid','off',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[handles.min_mag_crange handles.max_mag_crange]);
       
    box(axes1,'off');
%     hold(axes1,'all');

    curr_plot_handle = surf(mag_risk_total(end:-1:1,:));
    axis off
    grid off
    view(2);
    axis equal
    cmap = colormap(jet(255));
    cmap(floor(255/2)+1,:) = [0 0 0];
    caxis([-1*max([handles.min_mag_crange handles.max_mag_crange]) max([handles.min_mag_crange handles.max_mag_crange])]);
    colormap(cmap);
    xlim([0 handles.tekvar{selected_comparison}.header.cols+1]);
    ylim([0 handles.tekvar{selected_comparison}.header.rows+1]);
    colorbar
 
    set(figure1, 'Position', [0 0 scalefactor*550 scalefactor*440], 'PaperPositionMode', 'auto');

    print(figure1, '-dtiff', [pathfile token '_maxmin' rem], '-r300')
    
    save([pathfile token '_maxmin.mat'], 'mag_risk_total', 'min_mag_risk', 'max_mag_risk')
    
    close(figure1);
    
end

% --------------------------------------------------------------------
function save_combined_diff_Callback(hObject, eventdata, handles)
% hObject    handle to save_combined_diff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_mag_diff_all_Callback(hObject, eventdata, handles)
% hObject    handle to save_mag_diff_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, pathfile]=uiputfile(...
    {'*.mp4','MP4 Movie File(*.mp4)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Pressure Map Movie', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    selected_condition = get(handles.condition_selector, 'Value');
    selected_comparison = get(handles.comparison_selector, 'Value');
   
    time_span =  (inputdlg({'Start Frame (min value = 1):', ['End Frame (max value = ' num2str(handles.length_time) '):']}, 'Movie Frame Span',1, {'1', num2str(handles.length_time)}));
    
    start_frame = str2num(time_span{1});
    end_frame = str2num(time_span{2});
    
    fps =  (inputdlg({'FPS:'}, 'Frames Per Second',1,{num2str(handles.Fs)})); %frames/sec to run movie at
    
    
    % Handle response
    fig = figure('Position', [1 1 950/2 320]);
    aviobj = VideoWriter([pathfile file], 'MPEG-4');
    aviobj.FrameRate = str2num(fps{1});
    aviobj.Quality = 100; %No compression
    open(aviobj);
 
    axes1 = axes('Parent',fig,'YTick',[1 3 5 7 9 11 13 15 17 19 21 23],...
        'YMinorGrid','on',...
        'YGrid','on',...
        'XTick',[1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35],...
        'XMinorGrid','on',...
        'XGrid','on',...
        'Layer','top',...
        'FontSize',14,...
        'FontName','Aharoni',...
        'CLim',[handles.min_mag_crange handles.max_mag_crange]);
    % Uncomment the following line to preserve the X-limits of the axes
    xlim(axes1,[0 35]);
    % Uncomment the following line to preserve the Y-limits of the axes
    ylim(axes1,[0 23]);
    
    % colorbar %Adds a color bar denoting heatmap values
    box(axes1,'on');
    
    for frame_write = start_frame:end_frame
        diffMap = surf(axes1, handles.magnitude_risk{selected_condition, selected_comparison}(:,:,frame_write));

        caxis([0 handles.max_crange])
        set(axes1, 'XTick', 0:1:handles.tekvar{selected_condition}.header.cols);
        set(axes1, 'YTick', 0:1:handles.tekvar{selected_condition}.header.rows);
        set(axes1,'nextplot','replacechildren');
        set(gcf,'Renderer','zbuffer');
        set(axes1, 'YDir', 'reverse');
        axis equal
        axis off
        view(2);
        grid on
        
        if strcmp(get(handles.pattern_register, 'Checked'), 'on')
            tracker_title = ['[' num2str(handles.gait_time(frame_write)/handles.Tl*100) '%] (Frame ' num2str(frame_write) ')'];
        else
            tracker_title = ['(Frame ' num2str(frame_write) ')'];
        end
        
        title(axes1, ['Percent Gait: ' tracker_title]);
        cmap = colormap(jet(256));
        cmap(256/2+1,:) = [0 0 0];
        colormap(cmap);
        colorbar;
        caxis([handles.min_mag_crange handles.max_mag_crange]);
        
        F = getframe(fig);
        writeVideo(aviobj,F)
    end
    
    close(fig)
    close(aviobj);
end

% --------------------------------------------------------------------
function man_time_reg_Callback(hObject, eventdata, handles)
% hObject    handle to man_time_reg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selected_condition = get(handles.condition_selector, 'Value');

time_shift =  str2num(cell2mat(inputdlg('Enter Time Shift:','Manual Time Shift',1,{num2str(handles.time_shift_by{selected_condition})})));

handles.time_shift{selected_condition} = time_shift;

handles.time_order{selected_condition} = 1:handles.length_time;
[row, col] = size(handles.time_order);

if row>col
    handles.time_order{selected_condition} = [handles.time_order{selected_condition}(time_shift:end); handles.time_order{selected_condition}(1:time_shift-1)];
else
    handles.time_order{selected_condition} = [handles.time_order{selected_condition}(time_shift:end) handles.time_order{selected_condition}(1:time_shift-1)];
end
handles.time_shift_by{selected_condition} = time_shift;
handles.time_reg_auto = false;

time_order = handles.time_order;
shift = handles.time_shift;

guidata(hObject, handles);

refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function roughness_Callback(hObject, eventdata, handles)
% hObject    handle to roughness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_map_stats_Callback(hObject, eventdata, handles)
% hObject    handle to save_map_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save_pressure
if eventdata == 140
    file = handles.base_file;
    pathfile = handles.path;
else
    [file, pathfile]=uiputfile(...
        {'*.csv','Comma Separated File (*.csv)';...
        '*.*',  'All Files(*.*)'}, ...
        'Save Current Map Statistics', handles.path);
end

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    flag = 0;
    selected_condition = get(handles.condition_selector, 'Value');

    % determine proper scaling factor for units
    switch handles.tekvar{selected_condition}.header.dUnits
        case 'mm'
            fScale = 1;
        case 'cm' % convert cm to mm
            fScale = 10;
        case 'm' % convert m to mm
            fScale = 1000;
    end
    row_spacing = handles.tekvar{selected_condition}.header.row_spacing*fScale;
    col_spacing = handles.tekvar{selected_condition}.header.col_spacing*fScale;
    sensel_area = row_spacing*col_spacing;
    sUnit = '[N]';
        
    if strcmp(get(handles.convForce_menu, 'Checked'), 'off') % checks if user wants to convert data to force
        sensel_area = 1;
        sUnit = '[MPa]';
    end
    map_stats = cell(1,9);
    map_stats(1,1:2) = {'Threshold Pressure (MPa)' handles.tekvar{selected_condition}.header.scale_factor*handles.tekvar{selected_condition}.header.noise_threshold^handles.tekvar{selected_condition}.header.exponent};
    map_stats(2,:) = {'Time [s]' ['Mean ' sUnit] ['Max ' sUnit] 'Loc X Max Force [mm]' 'Loc Y Max Force [mm]' ['Min ' sUnit] 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' ['Sum ' sUnit]};
    
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        map_stats(2,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
    end 
    
    if strcmp(get(handles.avg_data, 'checked'), 'on')
        senselvar = handles.avg_senselvar;
        time_order = handles.avg_time_order;
        force = handles.avg_force;
        time = handles.avg_time;
    else
        senselvar = handles.senselvar;
        time_order = handles.time_order;
        force = handles.force{selected_condition};
        time = handles.tekvar{selected_condition}.data_a.time;
    end

    for index = 1:length(time)
        locs = rem(index,handles.window_size);
        if locs == 0
            locs = handles.window_size;
        end

        if get(handles.risk_map_checkbox, 'Value')
            selected_comparison = get(handles.comparison_selector, 'Value');

            switch get(handles.risk_type_dropdown, 'Value')
                case 5
                    mag_roi = handles.curr_plot;
                    flag = 1;
                case 1
                    mag_roi = handles.magnitude_risk(:,:, index);
                case 2
                    mag_risk_total = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 3
                    mag_risk_total = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 4
                    max_mag_risk = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    min_mag_risk = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_risk_total = handles.magnitude_risk{selected_condition, selected_comparison}(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 6
                    max_mag_risk = max(handles.magnitude_risk,[],3);
                    min_mag_risk = min(handles.magnitude_risk,[],3);
                    mag_risk_total = handles.magnitude_risk(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total.*load_risk;
                    flag = 1;
            end
        else
            %whs,output the pressure of the selected region of interest
            if handles.curr_select_flag == 1
                loc = rem(index,handles.window_size);
                if loc == 0
                    loc = handles.window_size;
                end
                
                mag_roi = handles.curr_plot*NaN;
                mag_roi = get_selection_ele(senselvar{selected_condition}(:,:,time_order{selected_condition}(index)),handles.in(:,:,locs));
            else
                mag_roi = senselvar{selected_condition}(:,:,time_order{selected_condition}(index));
            end
        end
        
        if strcmp(get(handles.include_zero, 'Checked'), 'on')
            [max_loc_y, max_loc_x] = find(mag_roi == max(max(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String'))))), 1);
            [min_loc_y, min_loc_x] = find(mag_roi == min(min(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String'))))), 1);
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))))) num2str(max(max(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))))) num2str(max_loc_x*col_spacing) num2str(max_loc_y*row_spacing) num2str(min(min(mag_roi(~isnan(mag_roi))))) num2str(min_loc_x*col_spacing) num2str(min_loc_y*row_spacing) num2str(sum(sum(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String'))))))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_stats(index+2, :) = temp_map_stats;
        else
            [max_loc_y, max_loc_x] = find(mag_roi == max(max(mag_roi)), 1);
            if ~isempty(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))
                [min_loc_y, min_loc_x] = find(mag_roi == min(min(mag_roi(~isnan(mag_roi) & mag_roi ~= 0 & mag_roi>=str2double(get(handles.noise_floor_edit,'String'))))), 1);
            else
                [min_loc_y, min_loc_x] = find(mag_roi == 0 & mag_roi>=str2double(get(handles.noise_floor_edit,'String')),1);
            end
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(mag_roi(~isnan(mag_roi) & mag_roi~=0 & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))*sensel_area))) num2str(max(max(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))*sensel_area))) num2str(max_loc_x*col_spacing) num2str(max_loc_y*row_spacing) num2str(min(min(mag_roi(~isnan(mag_roi) & mag_roi ~= 0 & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))*sensel_area))) num2str(min_loc_x*col_spacing) num2str(min_loc_y*row_spacing) num2str(sum(sum(mag_roi(~isnan(mag_roi) & mag_roi>=str2double(get(handles.noise_floor_edit,'String')))*sensel_area)))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_stats(index+2, :) = temp_map_stats;
        end
               
        if flag == 1
            break;
        end
    end
    
    csvwrite([pathfile file], map_stats, 2)
end


% --------------------------------------------------------------------
function save_centroid_Callback(hObject, eventdata, handles)
% hObject    handle to save_centroid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if eventdata == 140
    file = handles.base_file;
    pathfile = handles.path;
else
    [file, pathfile]=uiputfile(...
        {'*.csv','Comma Separated File (*.csv)';...
        '*.*',  'All Files(*.*)'}, ...
        'Save Centroid Data', handles.path);
end

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    loc = save_centroid(handles);
    % ======whs, add the fivepointstencile for calculating the velocity
    csvwrite([pathfile file], loc, 1)
end

function loc = save_centroid(handles, frame_range)
% save data from WCoCS

% Get necessary variables
selected_condition = get(handles.condition_selector, 'Value');
Left_I = 0; Left_J = 0; Right_I = 0; Right_J = 0; Left_dx = 0; Left_dy = 0; Right_dx = 0; Right_dy = 0;
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

% Set name of columns
loc(1,:) = {'Medial_X [mm from origin]' 'Medial_dX/dt [mm/s]' 'Medial_Y [mm from origin]' 'Medial_dY/dt [mm/s]' 'Lateral_X [mm from origin]' 'Lateral_dX/dt [mm/s]' 'Lateral_Y [mm from origin]' 'Lateral_dY/dt [mm/s]'};


% determine proper scaling factor
switch handles.tekvar{selected_condition}.header.dUnits
    case 'mm'
        multi_fact = 1;
    case 'cm' % convert cm to mm
        multi_fact = 10;
    case 'm' % convert m to mm
        multi_fact = 1000;
end

row_space = handles.tekvar{selected_condition}.header.row_spacing*multi_fact;
col_space = handles.tekvar{selected_condition}.header.col_spacing*multi_fact;

% Check if using averaged or raw data
if strcmp(get(handles.avg_data, 'checked'), 'on')
    senselvar = handles.avg_senselvar;
    time_order = handles.avg_time_order;
    force = handles.avg_force;
    time = handles.avg_time; 
else
    senselvar = handles.senselvar;
    time_order = handles.time_order;
    force = handles.force;
    time = handles.tekvar{selected_condition}.data_a.time;
end

if nargin == 1 % use all frames if none is input by user
    frames = 1:length(force{selected_condition});
else % use user defined frame range
    frames = frame_range;
end

% If using know pattern registration
if strcmp(get(handles.pattern_register, 'Checked'), 'on')
    loc = [{'Percent Gait' 'Flexion Angle [deg]'} loc];
end

loc = [{'Time [s]'} loc];

if get(handles.both_plateaus, 'Value')
    loc = [loc {'Slope between ML COS' 'Intercept between ML COS' 'Rotation of ML COS [o/s]'}];
end

if ~get(handles.risk_map_checkbox, 'Value') % if getting WCoCS for stress map
    for index = frames % loop through chosen frames
        
        locs = rem(index,handles.window_size);
        if locs == 0
            locs = handles.window_size;
        end
        
        % Left Side
        if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            %-------whs, output the selected region of interest----------
            if handles.curr_select_flag == 1
                var_temp = get_selection_ele(handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index)),handles.in(:,:,locs));
                [Left_I, Left_J] = centroid_location(abs(var_temp(1:rows,1:round(cols/2))), str2num(get(handles.noise_floor_edit, 'String')), true);
                clear var_temp;
                %--------------------------------------------------------------------
            else
                [Left_I, Left_J] = centroid_location(abs(senselvar{selected_condition}(1:rows,1:round(cols/2),time_order{selected_condition}(index))), str2num(get(handles.noise_floor_edit, 'String')), true);
            end
            Left_dx = 0; Left_dy = 0;
        end
        
        % Right Side
        if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            if handles.curr_select_flag == 1
                var_temp = get_selection_ele(handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index)),handles.in(:,:,locs));
                [Right_I, Right_J] = centroid_location(abs(var_temp(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), true);
                clear var_temp;
            else
                [Right_I, Right_J] = centroid_location(abs(senselvar{selected_condition}(1:rows,(cols-round(cols/2)):cols,time_order{selected_condition}(index))), str2num(get(handles.noise_floor_edit, 'String')), true);
            end
            Right_dx = 0; Right_dy = 0;
        end
        
        % store data to put into matrix
        temp_loc = [Left_J*col_space, Left_dx, Left_I*row_space, Left_dy, (Right_J+cols/2)*col_space, Right_dx, Right_I*row_space, Right_dy];
        
        if get(handles.both_plateaus, 'Value') % calculate rotation angle and velocity if both sides are used
            raw = polyfit([Left_J Right_J], [Left_I Right_I], 1);
            m(index) = raw(1);
            b(index) = raw(2);
            if index > 1
                atheta(index) = atand((m(index-1)-m(index))/(1+m(index-1)*m(index)))/(time(index)-time(index-1));
            else
                atheta(index) = NaN;
            end
            temp_loc = [temp_loc m(index) b(index) atheta(index)];
        end
        
        if strcmp(get(handles.pattern_register, 'Checked'), 'on') % output gait cycle and flexion angle if pattern registration is used
            temp_loc = [handles.gait_time(index)/handles.Tl*100 handles.flexion_rep(index) temp_loc];
        end
        
        % store data matrix
        temp_loc = [time(index) temp_loc];
        loc2(index, :) = temp_loc;
    end
    loc2 = loc2(frames,:);
    
    % Smooth WCoCS using a 5 point moving average
    if ~get(handles.both_plateaus, 'Value')
        %---------Five point stencil by Hongsheng-----------
        loc2(:,5) = fivepointderiv(loc2(:,4), handles.Fs); 
        loc2(:,7) = fivepointderiv(loc2(:,6), handles.Fs);
        loc2(:,9) = fivepointderiv(loc2(:,8), handles.Fs);
        % if strcmp('off',get(handles.pattern_register,'Checked'))
        %     loc2(:,11) = fivepointderiv(loc2(:,10), handles.Fs);
        % end
    else
        %---------Five point stencil by Hongsheng-----------
        loc2(:,5) = fivepointderiv(loc2(:,4), handles.Fs); 
        loc2(:,7) = fivepointderiv(loc2(:,6), handles.Fs);
        loc2(:,9) = fivepointderiv(loc2(:,8), handles.Fs);
        loc2(:,11) = fivepointderiv(loc2(:,10), handles.Fs);
        % loc2(:,14) = fivepointderiv(loc2(:,12), handles.Fs);
        loc2(:,11) = atheta;
    end

else % looking a comparison map between two conditions
    
    % Left half
    if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [Left_I, Left_J] = centroid_location(abs(handles.curr_plot(1:rows,1:round(cols/2))), str2num(get(handles.noise_floor_edit, 'String')), true);
    end
    
    % Right half
    if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [Right_I, Right_J] = centroid_location(abs(handles.curr_plot(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), true);
    end
    
    temp_loc = [handles.T, Left_J, Left_I, Right_J+cols/2, Right_I];
    
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        temp_loc(1,end+1:end+2) = [handles.gait_time(1)/handles.Tl*100 handles.flexion_rep(1)];
    end
    loc2(1, 1:end-2) = temp_loc;
end

loc = [loc; num2cell(loc2)];

% --------------------------------------------------------------------
function save_contact_stats_Callback(hObject, eventdata, handles)
% hObject    handle to save_contact_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% save contact area
if eventdata == 140 % do not prompt user if using save all
    file = handles.base_file;
    pathfile = handles.path;
else % prompt user for file name and location
    [file, pathfile]=uiputfile(...
        {'*.csv','Comma Separated File(*.csv)';... %allows user to save data as a .csv
        '*.*',  'All Files(*.*)'}, ...
        'Save Contact Area Data', handles.path);
end

if ~isequal(file,0) %if the file is open
    handles.path = pathfile;
    guidata(hObject, handles);
    selected_condition = get(handles.condition_selector, 'Value'); % get current selected condition
    
    % calculate sensel area in mm
    switch handles.tekvar{selected_condition}.header.dUnits
        case 'mm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing;
        case 'cm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing*100;
        case 'm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing*10000;            
    end

    if strcmp(get(handles.avg_data, 'checked'), 'on') %if averaging data is indicated
        senselvar = handles.avg_senselvar;
        time_order = handles.avg_time_order;
        time = handles.avg_time;
    else %use unaveraged data
        senselvar = handles.senselvar;
        time_order = handles.time_order;
        time = handles.tekvar{selected_condition}.data_a.time;
    end
    
    contact_area(1,:) = {'Threshold Pressure (MPa)' handles.tekvar{selected_condition}.header.scale_factor*handles.tekvar{selected_condition}.header.noise_threshold^handles.tekvar{selected_condition}.header.exponent};
    contact_area(2,:) = {'Time [s]' 'Contact Area [mm^2]'}; %initialize column headers
    
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
       contact_area(2,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'}; %adds extra column headers 
    end
    
    for index = 1:length(time) %cycles through all times
        locs = rem(index,handles.window_size);
        if locs == 0
            locs = handles.window_size;
        end
            curr_map = senselvar{selected_condition}(:,:,time_order{selected_condition}(index)); %gets the current map
            
            if handles.curr_select_flag == 1
                curr_map = get_selection_ele(senselvar{selected_condition}(:,:,time_order{selected_condition}(index)),handles.in(:,:,locs));
            end
            
            temp_contact_area = {num2str(time(index)) num2str(sensel_area*length(curr_map(curr_map>0 & curr_map>=str2double(get(handles.noise_floor_edit,'String')))))}; %gets contact area at current time
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_contact_area(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))}; %gets additional data if indicated
            end           
            contact_area(index+2,:) = temp_contact_area;
    end
    
    csvwrite([pathfile file], contact_area, 2) %write data to csv file
end

% --------------------------------------------------------------------
function save_pressure_vs_area_Callback(hObject, eventdata, handles)
% hObject    handle to save_pressure_vs_area (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% save the stress/area histogram data (roughness)
[file, pathfile]=uiputfile(...
    {'*.csv','Text File(*.csv)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Pressure Vs Area Measurements...', handles.path);

if ~isequal(file,0)

    % calculate sensel area in mm
    switch handles.tekvar{selected_condition}.header.dUnits
        case 'mm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing;
        case 'cm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing*100;
        case 'm'
            sensel_area = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.col_spacing*10000;
    end
    
    handles.path = pathfile;
    guidata(hObject, handles);
    
    x = handles.max_crange/14:handles.max_crange/14:handles.max_crange;
    index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
    
    h = histogram(reshape(handles.curr_plot, numel(handles.curr_plot>str2double(get(handles.noise_floor_edit, 'String'))),1),x);
   
    histo(1,:) = {'Bin' 'Area (mm^2)'};
    for t = 1:length(x)
        histo(t+1,:) = {num2str(x(t)) num2str(h(t)*sensel_area)};
    end
    
    csvwrite([pathfile file], histo)
end

% --------------------------------------------------------------------
function prefs_Callback(hObject, eventdata, handles)
% hObject    handle to prefs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function set_pressure_scale_Callback(hObject, eventdata, handles)
% hObject    handle to set_pressure_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject, 'Checked'), 'on') % Manually set color map for Stress
    set(hObject, 'Checked', 'off')
    pressure_span =  (inputdlg({'Min Pressure (min value = 0):', 'Max Pressure:'}, 'Pressure Map Span',1, {'0', num2str(handles.auto_max_crange)}));

    handles.min_crange = str2num(pressure_span{1});
    handles.max_crange = str2num(pressure_span{2});
else % Automatically set color map max/min for Stress
    set(hObject, 'Checked', 'on')
    if handles.useMaxSat
        handles.min_crange = handles.headers.saturation_pressure*handles.persat;
        set(handles.noise_floor_edit, 'String',num2str(handles.min_crange));
    else
        handles.min_crange = 0;
    end
    handles.max_crange = handles.auto_max_crange;
end

guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function mag_diff_scale_Callback(hObject, eventdata, handles)
% hObject    handle to mag_diff_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject, 'Checked'), 'on') % Manually set stress range for magnitude difference plots
    set(hObject, 'Checked', 'off')
    mag_span =  (inputdlg({'Min Pressure:', 'Max Pressure:'}, 'Pressure Map Span',1, {num2str(handles.min_mag_crange), num2str(handles.max_mag_crange)}));

    handles.min_mag_crange = str2num(mag_span{1});
    handles.max_mag_crange = str2num(mag_span{2});
else % Automatically set color map max/min for magnitude difference plots
    set(hObject, 'Checked', 'on')
    handles.min_mag_crange = min(min(min(handles.magnitude_risk)));
    handles.max_crange = max(max(max(handles.magnitude_risk)));
end

guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function contour_on_Callback(hObject, eventdata, handles)
% hObject    handle to contour_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject, 'Checked'), 'on') % used pcolor
    set(hObject, 'Checked', 'off')
else % use contour map
    set(hObject, 'Checked', 'on')
    set(handles.surf_on, 'Checked', 'off')
end

guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function include_zero_Callback(hObject, eventdata, handles)
% hObject    handle to include_zero (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Include zero value sensels in all calculations (e.g. average and max/min
% stress)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
else
    set(hObject, 'Checked', 'on')
end

guidata(hObject, handles);
refresh_fig(hObject, handles);


% --- Executes on button press in show_corr_map_overlay.
function show_corr_map_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to show_corr_map_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_corr_map_overlay

% Function called by quadrant_pressures_Callback
function quadvalues = get_quadrant(quad_loc, sensel)

[rows, cols] = size(sensel);

NANs = isnan(sensel(4:end, :)); % get NANs skip top 3 rows because 4010N has 3 rows of bridging sensels but should work still for all other sensors.

still_NAN = 0;
LP_end = 1; %col where left plateau ends
RP_start = 1; %col where right plateau starts

for f = 1:cols
    if numel(find(NANs(:,f)==0))==0 && still_NAN==0
        LP_end = f-1;
        still_NAN = 1;
    elseif numel(find(NANs(:,f)==1))==0 && still_NAN==1
        RP_start = f;
        still_NAN = 2;
    end
end

switch quad_loc
    case 'LP_PP'
        quadvalues = sensel((rows/2+1):end,1:LP_end/2);
    case 'LP_AP'
        quadvalues = sensel(5:13,1:LP_end/2);
    case 'LP_PC'
        quadvalues = sensel((rows/2+1):end,(LP_end/2+1):LP_end);
    case 'LP_AC'
        quadvalues = sensel(5:13,(LP_end/2+1):LP_end);
    case 'RP_PP'
        quadvalues = sensel((rows/2+1):end,(floor(11/2)+RP_start+1):end);
    case 'RP_AP'
        quadvalues = sensel(5:13,(floor(11/2)+RP_start+1):end);
    case 'RP_PC'
        quadvalues = sensel((rows/2+1):end,RP_start:(floor(11/2)+RP_start));
    case 'RP_AC'
        quadvalues = sensel(5:13,RP_start:(floor(11/2)+RP_start));
end

function sectorvalues = get_sector(sector_loc, sensel)

[rows, cols] = size(sensel);

NANs = isnan(sensel(4:end, :)); % get NANs skip top 3 rows because 4010N has 3 rows of bridging sensels but should work still for all other sensors.

still_NAN = 0;
LP_end = 1; %col where left plateau ends
RP_start = 1; %col where right plateau starts

for f = 1:cols
    if numel(find(NANs(:,f)==0))==0 && still_NAN==0
        LP_end = f-1;
        still_NAN = 1;
    elseif numel(find(NANs(:,f)==1))==0 && still_NAN==1
        RP_start = f;
        still_NAN = 2;
    end
end

switch sector_loc
    case 'LP_PP'
        sectorvalues = sensel((floor(rows/2)*2+1):end,1:LP_end/2);
    case 'LP_MP'
        sectorvalues = sensel((floor(rows/2)+1):(floor(rows/2)*2),1:LP_end/2);
    case 'LP_AP'
        sectorvalues = sensel(1:floor(rows/2),1:LP_end/2);
    case 'LP_PC'
        sectorvalues = sensel((floor(rows/2)*2+1):end,(LP_end/2+1):LP_end);
    case 'LP_MC'
        sectorvalues = sensel((floor(rows/2)+1):(floor(rows/2)*2),(LP_end/2+1):LP_end);
    case 'LP_AC'
        sectorvalues = sensel(1:floor(rows/2),(LP_end/2+1):LP_end);
    case 'RP_PP'
        sectorvalues = sensel((floor(rows/2)*2+1):end,(floor(11/2)+RP_start+1):end);
    case 'RP_MP'
        sectorvalues = sensel((floor(rows/2)+1):(floor(rows/2)*2),(floor(11/2)+RP_start+1):end);
    case 'RP_AP'
        sectorvalues = sensel(1:floor(rows/2),(floor(11/2)+RP_start+1):end);
    case 'RP_PC'
        sectorvalues = sensel((floor(rows/2)*2+1):end,RP_start:(floor(11/2)+RP_start));
    case 'RP_MC'
        sectorvalues = sensel((floor(rows/2)+1):(floor(rows/2)*2),RP_start:(floor(11/2)+RP_start));
    case 'RP_AC'
        sectorvalues = sensel(1:floor(rows/2),RP_start:(floor(11/2)+RP_start));
end

% --------------------------------------------------------------------
function eq_total_force_Callback(hObject, eventdata, handles)
% hObject    handle to eq_total_force (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% equalize force to total sum of force in first loaded condition across all frames use to scale
% stress for each remaining condition.
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
else
    set(hObject, 'Checked', 'on')
end

guidata(hObject, handles);
initialize(hObject, handles);


% --- Executes on selection change in condition_selector.
function condition_selector_Callback(hObject, eventdata, handles)
% hObject    handle to condition_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns condition_selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from condition_selector
selected_condition = get(handles.condition_selector, 'Value');

%---------whs edited, update the current axis by the current trial---------
handles.min_crange = 0;

if strcmp(get(handles.set_pressure_scale, 'Checked'), 'on')
    handles.max_crange = max(max(max(cell2mat(handles.senselvar))));
end    
handles.cycle_tracker_max(selected_condition) = max(handles.force{selected_condition});
guidata(hObject, handles);
%----------------------------------------------------
current_menu_length = get(handles.second_axis, 'String');
if strcmp(get(handles.pattern_register, 'Checked'), 'on')
    if numel(current_menu_length) > numel(handles.kinematics(selected_condition).name)
        set(handles.second_axis, 'Value', numel(handles.kinematics(selected_condition).name));
    end
    set(handles.second_axis, 'String', handles.kinematics(selected_condition).name);
end

refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function condition_selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to condition_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in comparison_selector.
function comparison_selector_Callback(hObject, eventdata, handles)
% hObject    handle to comparison_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns comparison_selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from comparison_selector
refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function comparison_selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to comparison_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in both_plateaus.
function both_plateaus_Callback(hObject, eventdata, handles)
% hObject    handle to both_plateaus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of both_plateaus

handles = parse_tekscan_map(hObject, handles);
guidata(hObject, handles);

refresh_fig(hObject, handles);


% --- Executes on button press in right_plateau.
function right_plateau_Callback(hObject, eventdata, handles)
% hObject    handle to right_plateau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of right_plateau

set(handles.right_plateau, 'Value', 1);
guidata(hObject, handles);
handles = parse_tekscan_map(hObject, handles);
guidata(hObject, handles);

refresh_fig(hObject, handles);


% --- Executes on button press in left_plateau.
function left_plateau_Callback(hObject, eventdata, handles)
% hObject    handle to left_plateau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of left_plateau

set(handles.left_plateau, 'Value', 1)
guidata(hObject, handles);
handles = parse_tekscan_map(hObject, handles);
guidata(hObject, handles);

refresh_fig(hObject, handles);


% --- Executes on mouse press over axes background.
function cycle_tracker_axes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to cycle_tracker_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

curr_point = get(hObject, 'CurrentPoint');
slider_max = get(handles.pressure_map_slider, 'Max');

set(handles.pressure_map_slider, 'Value', ceil((curr_point(1,1)/handles.T)));

guidata(hObject, handles);

refresh_fig(hObject, handles);


% --- Executes when gui_frame is resized.
function gui_frame_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to gui_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function cycles_to_show_Callback(hObject, eventdata, handles)
% hObject    handle to cycles_to_show (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cycles_to_show as text
%        str2double(get(hObject,'String')) returns contents of cycles_to_show as a double


% --- Executes during object creation, after setting all properties.
function cycles_to_show_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cycles_to_show (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on cycles_to_show and none of its controls.
function cycles_to_show_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to cycles_to_show (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

current_value = get(handles.cycles_to_show, 'String');

if strcmp(eventdata.Key, 'return')
    guidata(hObject, handles)
    refresh_fig(hObject, handles)
end


% --------------------------------------------------------------------
function pattern_register_Callback(hObject, eventdata, handles)
% hObject    handle to pattern_register (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
    set(handles.diff_pattern, 'Enable', 'off')
    set(handles.avg_data, 'Enable', 'off')
    set(handles.second_axis, 'Visible', 'off')
    set(handles.show_derivs, 'Visible', 'off')
else
    set(handles.second_axis, 'Visible', 'on')
    set(hObject, 'Checked', 'on')
    set(handles.diff_pattern, 'Enable', 'on')
    set(handles.avg_data, 'Enable', 'on')
    
    num_gait_cycle = round(handles.length_time/handles.Tl*handles.T);
    [Gfile, Gpath]=uigetfile(...
        {'*.mat','Matlab files(*.mat)';...
        '*.*',  'All Files(*.*)'}, ...
        'Pick a Gait Cycle file');
    
    if ~isequal(Gfile,0)
        handles.Gpath = Gpath;
        handles.Gfile = Gfile;
        gait_cycle = load([Gpath Gfile]); %open gait cycle file
        
        gait_time = (linspace(0,handles.Tl,numel(gait_cycle.force)))';
        sample_time = (linspace(handles.T, handles.Tl, handles.window_size))';
        handles.gait_spline = spline(gait_time, gait_cycle.force, sample_time);
        handles.flexion_spline = spline(gait_time, gait_cycle.flexion, sample_time);
        handles.AP_spline = spline(gait_time, gait_cycle.AP, sample_time);
        handles.torque_spline = spline(gait_time, gait_cycle.torque, sample_time);
        
        handles.gait_time = repmat(sample_time, num_gait_cycle, 1);
        handles.gait_rep = repmat(handles.gait_spline, num_gait_cycle, 1);
        handles.flexion_rep = repmat(handles.flexion_spline, num_gait_cycle, 1);
        handles.AP_rep = repmat(handles.AP_spline, num_gait_cycle, 1);
        handles.torque_rep = repmat(handles.torque_spline, num_gait_cycle, 1);
        
        for i = 1:handles.comparison
            handles.kinematics(i).order = {'flexion_rep'; 'AP_rep'; 'torque_rep'};
            handles.kinematics(i).name = {'Sim Inputs: Flexion Angle (^o)'; 'Sim Inputs: Anterior/Posterior Force (N)'; 'Sim Inputs: Torque (Nm)'};
            handles.kinematics(i).units = {'^o'; 'N'; 'Nm'};
        end
        
        set(handles.second_axis, 'String', handles.kinematics(i).name);
        set(handles.second_axis, 'Value', 1);
        
        [handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, false);
        handles.time_reg_auto = true;
    end
end

guidata(hObject, handles);

refresh_fig(hObject, handles)


% --------------------------------------------------------------------
function updated_guidata = avg_data_Callback(hObject, eventdata, handles, start_cycle_input, end_cycle_input)
% hObject    handle to avg_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.avg_time = [];
handles.avg_senselvar = {};
handles.avg_force = {};
handles.avg_magnitude_risk = {};
handles.avg_load_risk = {};

%% If the menu option is already selected - unselect it and make sure that the slider is still within the allowable range
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')

    if get(handles.pressure_map_slider, 'Value') > handles.length_time
        set(handles.pressure_map_slider, 'Value', handles.length_time);
    end
    
    set(handles.pressure_map_slider, 'Max', handles.length_time);
    set(handles.pressure_map_slider, 'SliderStep', [1/handles.length_time 0.1]);
    
%% If the menu option is not selected - check it and calculate the average for the selected cycle range
else
    set(hObject, 'Checked', 'on')
    
    max_cycles = round(handles.length_time/handles.Tl*handles.T);
    if nargin == 3
        time_span =  (inputdlg({['Start Cycle [From End (Max value = ' num2str(max_cycles) ' (first cycle))]:'], 'End Cycle (min value = 1 (last cycle)):'}, 'Movie Frame Span',1, {num2str(round(handles.length_time/handles.Tl*handles.T)), '1'}));
    else
        time_span = {num2str(start_cycle_input) num2str(end_cycle_input)};
    end
      
    if ~isempty(time_span)
        %Calculate the elements that fall within the cycles selected to be
        %averaged
        start_cycle = handles.window_size*(max_cycles-str2num(time_span{1}));
        end_cycle = handles.window_size*(max_cycles-str2num(time_span{2}));
        handles.range_plotting = [1, handles.window_size]; % set plotting range based on the average data
       
        for sample_tracker = 1:length(handles.senselvar) %goes across the different tekscan files open
            for averager = 1:handles.window_size %goes across one window length
                var_temp = handles.senselvar{sample_tracker};
                
                handles.avg_time = handles.T*(1:handles.window_size); %calculates the current cycle time based on the sampling rate
                handles.avg_time_order{sample_tracker} = 1:handles.window_size; %sets the order of the stress profiles for each tekscan file (default in order from 1 to the number of samples per cycle)
                handles.avg_senselvar{sample_tracker}(:,:,averager) = mean(var_temp(:,:,handles.time_order{sample_tracker}(start_cycle+averager:handles.window_size:end_cycle+averager)),3); %calculates the average stress value for each sensel at the current timepoint
                handles.std_senselvar{sample_tracker}(:,:,averager) = std(var_temp(:,:,handles.time_order{sample_tracker}(start_cycle+averager:handles.window_size:end_cycle+averager)),0,3); %calculates the stress standard deviation for each sensel at the current timepoint
                handles.avg_force{sample_tracker}(averager) = mean(handles.force{sample_tracker}(handles.time_order{sample_tracker}(start_cycle+averager:handles.window_size:end_cycle+averager))); %calculates the average total force for the current timepoint
                handles.std_force{sample_tracker}(averager) = std(handles.force{sample_tracker}(handles.time_order{sample_tracker}(start_cycle+averager:handles.window_size:end_cycle+averager))); %calcules the total force standard deviation for the current timepoint
                
                if handles.mag_calced %calculate the averages for the comparisons if they have been calculated
                    for var_outer_count = 1:handles.comparison
                        for var_inner_count = 1:handles.comparison
                            if  handles.mag_calced
                                handles.avg_magnitude_risk{var_outer_count,var_inner_count}(:,:,averager) = mean(handles.magnitude_risk{var_outer_count,var_inner_count}(:,:,(start_cycle+averager:handles.window_size:end_cycle+averager)),3);
                                handles.std_magnitude_risk{var_outer_count,var_inner_count}(:,:,averager) = std(handles.magnitude_risk{var_outer_count,var_inner_count}(:,:,(start_cycle+averager:handles.window_size:end_cycle+averager)),0,3);
                            end
                        end
                    end
                end
                
            end
        end
        
        if get(handles.pressure_map_slider, 'Value') > handles.window_size
            set(handles.pressure_map_slider, 'Value', handles.window_size-1);
        end
        
        set(handles.pressure_map_slider, 'Max', handles.window_size);
        set(handles.pressure_map_slider, 'SliderStep', [1/handles.window_size 0.1]);
    else
        set(hObject, 'Checked', 'off')
    end
    
    if nargin == 3
        handles.start_cycle = str2num(time_span{1});
        handles.end_cycle = str2num(time_span{2});
    else
        handles.start_cycle = start_cycle_input;
        handles.end_cycle = end_cycle_input;
    end
end


updated_guidata = handles;

guidata(hObject, handles);

refresh_fig(hObject, handles)




function cycle_time_Callback(hObject, eventdata, handles)
% hObject    handle to cycle_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cycle_time as text
%        str2double(get(hObject,'String')) returns contents of cycle_time as a double

handles.Tl = str2double(get(handles.cycle_time, 'String')); %Gait Cycle time (s)

handles.window_size = round(handles.Fs*handles.Tl);  %Sets default window size (Based on 1 cycle/2 sec recording data at 10 Hz)
handles.range_plotting = [1, handles.window_size]; % sets default range of frames based on new cycle time
guidata(hObject, handles);

refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function cycle_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cycle_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in second_axis.
function second_axis_Callback(hObject, eventdata, handles)
% hObject    handle to second_axis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns second_axis contents as cell array
%        contents{get(hObject,'Value')} returns selected item from second_axis

refresh_fig(hObject, handles)

% --- Executes during object creation, after setting all properties.
function second_axis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to second_axis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function registration_Callback(hObject, eventdata, handles)
% hObject    handle to registration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function diff_pattern_Callback(hObject, eventdata, handles)
% hObject    handle to diff_pattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
num_gait_cycle = round(handles.length_time/handles.Tl*handles.T);

[Gfile, Gpath]=uigetfile(...
    {'*.mat','Matlab files(*.mat)';...
    '*.*',  'All Files(*.*)'}, ...
    'Pick a Gait Cycle file');

if ~isequal(Gfile,0)
    set(handles.show_derivs, 'Visible', 'off')
    
    gait_cycle = load([Gpath Gfile]); %open gait cycle file
    
    gait_time = (linspace(0,handles.Tl,numel(gait_cycle.force)))';
    sample_time = (linspace(handles.T, handles.Tl, handles.window_size))';
    handles.gait_spline = spline(gait_time, gait_cycle.force, sample_time);
    handles.flexion_spline = spline(gait_time, gait_cycle.flexion, sample_time);
    handles.AP_spline = spline(gait_time, gait_cycle.AP, sample_time);
    handles.torque_spline = spline(gait_time, gait_cycle.torque, sample_time);
    
    handles.gait_time = repmat(sample_time, num_gait_cycle, 1);
    handles.gait_rep = repmat(handles.gait_spline, num_gait_cycle, 1);
    handles.flexion_rep = repmat(handles.flexion_spline, num_gait_cycle, 1);
    handles.AP_rep = repmat(handles.AP_spline, num_gait_cycle, 1);
    handles.torque_rep = repmat(handles.torque_spline, num_gait_cycle, 1);
    
    for i = 1:handles.comparison
        handles.kinematics(i).order = {'flexion_rep'; 'AP_rep'; 'torque_rep'};
        handles.kinematics(i).name = {'Sim Inputs: Flexion Angle (^o)'; 'Sim Inputs: Anterior/Posterior Force (N)'; 'Sim Inputs: Torque (Nm)'};
        handles.kinematics(i).units = {'^o'; 'N'; 'Nm'};
    end
    
    set(handles.second_axis, 'String', handles.kinematics(i).name);
    set(handles.second_axis, 'Value', 1);
    
    [handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, false);
    handles.time_reg_auto = true;
    
    guidata(hObject, handles);
    
    refresh_fig(hObject, handles)
end


% --------------------------------------------------------------------
function save_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_quad_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_quad_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, pathfile]=uiputfile(...
    {'*.csv','Comma Separated File (*.csv)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Current Map Quadrant Statistics', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);

    map_quad_LP_stats(1,:) = {'Time [s]' 'LP_AC Mean [Pa]' 'LP_AC Max [Pa]' 'LP_AC Loc X Max Stress [mm]' 'LP_AC Loc Y Max Stress [mm]' 'LP_AC Min [Pa]' 'LP_AC Loc X Min Stress [mm]' 'LP_AC Loc Y Min Stress [mm]' 'LP_AC Sum [Pa]'...
        'LP_PC Mean [Pa]' 'LP_PC Max [Pa]' 'LP_PC Loc X Max Stress [mm]' 'LP_PC Loc Y Max Stress [mm]' 'LP_PC Min [Pa]' 'LP_PC Loc X Min Stress [mm]' 'LP_PC Loc Y Min Stress [mm]' 'LP_PC Sum [Pa]'...
        'LP_PP Mean [Pa]' 'LP_PP Max [Pa]' 'LP_PP Loc X Max Stress [mm]' 'LP_PP Loc Y Max Stress [mm]' 'LP_PP Min [Pa]' 'LP_PP Loc X Min Stress [mm]' 'LP_PP Loc Y Min Stress [mm]' 'LP_PP Sum [Pa]'...
        'LP_AP Mean [Pa]' 'LP_AP Max [Pa]' 'LP_AP Loc X Max Stress [mm]' 'LP_AP Loc Y Max Stress [mm]' 'LP_AP Min [Pa]' 'LP_AP Loc X Min Stress [mm]' 'LP_AP Loc Y Min Stress [mm]' 'LP_AP Sum [Pa]'};
    map_quad_RP_stats(1,:) = {'Time [s]' 'RP_AC Mean [Pa]' 'RP_AC Max [Pa]' 'RP_AC Loc X Max Stress [mm]' 'RP_AC Loc Y Max Stress [mm]' 'RP_AC Min [Pa]' 'RP_AC Loc X Min Stress [mm]' 'RP_AC Loc Y Min Stress [mm]' 'RP_AC Sum [Pa]'...
        'RP_PC Mean [Pa]' 'RP_PC Max [Pa]' 'RP_PC Loc X Max Stress [mm]' 'RP_PC Loc Y Max Stress [mm]' 'RP_PC Min [Pa]' 'RP_PC Loc X Min Stress [mm]' 'RP_PC Loc Y Min Stress [mm]' 'RP_PC Sum [Pa]'...
        'RP_PP Mean [Pa]' 'RP_PP Max [Pa]' 'RP_PP Loc X Max Stress [mm]' 'RP_PP Loc Y Max Stress [mm]' 'RP_PP Min [Pa]' 'RP_PP Loc X Min Stress [mm]' 'RP_PP Loc Y Min Stress [mm]' 'RP_PP Sum [Pa]'...
        'RP_AP Mean [Pa]' 'RP_AP Max [Pa]' 'RP_AP Loc X Max Stress [mm]' 'RP_AP Loc Y Max Stress [mm]' 'RP_AP Min [Pa]' 'RP_AP Loc X Min Stress [mm]' 'RP_AP Loc Y Min Stress [mm]' 'RP_AP Sum [Pa]'};

    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        map_quad_LP_stats(1,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
        map_quad_RP_stats(1,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
    end
    
    flag = 0;
    selected_condition = get(handles.condition_selector, 'Value');
    time = handles.tekvar{selected_condition}.data_a.time;
    
    for index = 1:handles.length_time
        if get(handles.risk_map_checkbox, 'Value')
            selected_comparison = get(handles.comparison_selector, 'Value');

            switch get(handles.risk_type_dropdown, 'Value')
                case 5
                    mag_roi = handles.curr_plot;
                    flag = 1;
                case 1
                    mag_roi = handles.magnitude_risk(:,:, index);
                case 2
                    mag_risk_total = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 3
                    mag_risk_total = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 4
                    max_mag_risk = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    min_mag_risk = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_risk_total = handles.magnitude_risk{selected_condition, selected_comparison}(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 6
                    max_mag_risk = max(handles.magnitude_risk,[],3);
                    min_mag_risk = min(handles.magnitude_risk,[],3);
                    mag_risk_total = handles.magnitude_risk(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total.*load_risk;
                    flag = 1;
            end
        else
            mag_roi = handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index));
        end
 
        if get(handles.both_plateaus, 'Value') || get(handles.left_plateau, 'Value')
            LP_AC = get_quadrant('LP_AC', mag_roi);
            LP_PC = get_quadrant('LP_PC', mag_roi);
            LP_PP = get_quadrant('LP_PP', mag_roi);
            LP_AP = get_quadrant('LP_AP', mag_roi);
            LP_SAVE = 1;
        else
            LP_SAVE = 0;
        end
        
        if get(handles.both_plateaus, 'Value') || get(handles.right_plateau, 'Value')
            RP_AC = get_quadrant('RP_AC', mag_roi);
            RP_PC = get_quadrant('RP_PC', mag_roi);
            RP_PP = get_quadrant('RP_PP', mag_roi);
            RP_AP = get_quadrant('RP_AP', mag_roi);
            RP_SAVE = 1;
        else
            RP_SAVE = 0;
        end

        if strcmp(get(handles.include_zero, 'Checked'), 'on') && LP_SAVE
            [LP_AC_max_loc_y, LP_AC_max_loc_x] = find(LP_AC == max(max(LP_AC(~isnan(LP_AC)))), 1);
            [LP_AC_min_loc_y, LP_AC_min_loc_x] = find(LP_AC == min(min(LP_AC(~isnan(LP_AC)))), 1);
            
            [LP_PC_max_loc_y, LP_PC_max_loc_x] = find(LP_PC == max(max(LP_PC(~isnan(LP_PC)))), 1);
            [LP_PC_min_loc_y, LP_PC_min_loc_x] = find(LP_PC == min(min(LP_PC(~isnan(LP_PC)))), 1);
            
            [LP_PP_max_loc_y, LP_PP_max_loc_x] = find(LP_PP == max(max(LP_PP(~isnan(LP_PP)))), 1);
            [LP_PP_min_loc_y, LP_PP_min_loc_x] = find(LP_PP == min(min(LP_PP(~isnan(LP_PP)))), 1);
            
            [LP_AP_max_loc_y, LP_AP_max_loc_x] = find(LP_AP == max(max(LP_AP(~isnan(LP_AP)))), 1);
            [LP_AP_min_loc_y, LP_AP_min_loc_x] = find(LP_AP == min(min(LP_AP(~isnan(LP_AP)))), 1);
            
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(LP_AC(~isnan(LP_AC))))) num2str(max(max(LP_AC(~isnan(LP_AC))))) num2str(LP_AC_max_loc_x) num2str(LP_AC_max_loc_y) num2str(min(min(LP_AC(~isnan(LP_AC))))) num2str(LP_AC_min_loc_x) num2str(LP_AC_min_loc_y) num2str(sum(sum(LP_AC(~isnan(LP_AC)))))...
                num2str(mean(mean(LP_PC(~isnan(LP_PC))))) num2str(max(max(LP_PC(~isnan(LP_PC))))) num2str(LP_PC_max_loc_x) num2str(LP_PC_max_loc_y) num2str(min(min(LP_PC(~isnan(LP_PC))))) num2str(LP_PC_min_loc_x) num2str(LP_PC_min_loc_y) num2str(sum(sum(LP_PC(~isnan(LP_PC)))))...
                num2str(mean(mean(LP_PP(~isnan(LP_PP))))) num2str(max(max(LP_PP(~isnan(LP_PP))))) num2str(LP_PP_max_loc_x) num2str(LP_PP_max_loc_y) num2str(min(min(LP_PP(~isnan(LP_PP))))) num2str(LP_PP_min_loc_x) num2str(LP_PP_min_loc_y) num2str(sum(sum(LP_PP(~isnan(LP_PP)))))...
                num2str(mean(mean(LP_AP(~isnan(LP_AP))))) num2str(max(max(LP_AP(~isnan(LP_AP))))) num2str(LP_AP_max_loc_x) num2str(LP_AP_max_loc_y) num2str(min(min(LP_AP(~isnan(LP_AP))))) num2str(LP_AP_min_loc_x) num2str(LP_AP_min_loc_y) num2str(sum(sum(LP_AP(~isnan(LP_AP)))))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_quad_LP_stats(index+1, :) = temp_map_stats;
        elseif LP_SAVE
            [LP_AC_max_loc_y, LP_AC_max_loc_x] = find(LP_AC == max(max(LP_AC(~isnan(LP_AC)))), 1);
            [LP_AC_min_loc_y, LP_AC_min_loc_x] = find(LP_AC == min(min(LP_AC(~isnan(LP_AC) & LP_AC ~= 0))), 1);

            [LP_PC_max_loc_y, LP_PC_max_loc_x] = find(LP_PC == max(max(LP_PC(~isnan(LP_PC)))), 1);
            [LP_PC_min_loc_y, LP_PC_min_loc_x] = find(LP_PC == min(min(LP_PC(~isnan(LP_PC) & LP_PC ~= 0))), 1);
            
            [LP_PP_max_loc_y, LP_PP_max_loc_x] = find(LP_PP == max(max(LP_PP(~isnan(LP_PP)))), 1);
            [LP_PP_min_loc_y, LP_PP_min_loc_x] = find(LP_PP == min(min(LP_PP(~isnan(LP_PP) & LP_PP ~= 0))), 1);
            
            [LP_AP_max_loc_y, LP_AP_max_loc_x] = find(LP_AP == max(max(LP_AP(~isnan(LP_AP)))), 1);
            [LP_AP_min_loc_y, LP_AP_min_loc_x] = find(LP_AP == min(min(LP_AP(~isnan(LP_AP) & LP_AP ~= 0))), 1);
            
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(LP_AC(~isnan(LP_AC))))) num2str(max(max(LP_AC(~isnan(LP_AC))))) num2str(LP_AC_max_loc_x) num2str(LP_AC_max_loc_y) num2str(min(min(LP_AC(~isnan(LP_AC) & LP_AC ~= 0)))) num2str(LP_AC_min_loc_x) num2str(LP_AC_min_loc_y) num2str(sum(sum(LP_AC(~isnan(LP_AC)))))...
                num2str(mean(mean(LP_PC(~isnan(LP_PC))))) num2str(max(max(LP_PC(~isnan(LP_PC))))) num2str(LP_PC_max_loc_x) num2str(LP_PC_max_loc_y) num2str(min(min(LP_PC(~isnan(LP_PC) & LP_PC ~= 0)))) num2str(LP_PC_min_loc_x) num2str(LP_PC_min_loc_y) num2str(sum(sum(LP_PC(~isnan(LP_PC)))))...
                num2str(mean(mean(LP_PP(~isnan(LP_PP))))) num2str(max(max(LP_PP(~isnan(LP_PP))))) num2str(LP_PP_max_loc_x) num2str(LP_PP_max_loc_y) num2str(min(min(LP_PP(~isnan(LP_PP) & LP_PP ~= 0)))) num2str(LP_PP_min_loc_x) num2str(LP_PP_min_loc_y) num2str(sum(sum(LP_PP(~isnan(LP_PP)))))...
                num2str(mean(mean(LP_AP(~isnan(LP_AP))))) num2str(max(max(LP_AP(~isnan(LP_AP))))) num2str(LP_AP_max_loc_x) num2str(LP_AP_max_loc_y) num2str(min(min(LP_AP(~isnan(LP_AP) & LP_AP ~= 0)))) num2str(LP_AP_min_loc_x) num2str(LP_AP_min_loc_y) num2str(sum(sum(LP_AP(~isnan(LP_AP)))))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_quad_LP_stats(index+1, :) = temp_map_stats;
        end

        if strcmp(get(handles.include_zero, 'Checked'), 'on') && RP_SAVE
            [RP_AC_max_loc_y, RP_AC_max_loc_x] = find(RP_AC == max(max(RP_AC(~isnan(RP_AC)))), 1);
            [RP_AC_min_loc_y, RP_AC_min_loc_x] = find(RP_AC == min(min(RP_AC(~isnan(RP_AC)))), 1);
            
            [RP_PC_max_loc_y, RP_PC_max_loc_x] = find(RP_PC == max(max(RP_PC(~isnan(RP_PC)))), 1);
            [RP_PC_min_loc_y, RP_PC_min_loc_x] = find(RP_PC == min(min(RP_PC(~isnan(RP_PC)))), 1);
            
            [RP_PP_max_loc_y, RP_PP_max_loc_x] = find(RP_PP == max(max(RP_PP(~isnan(RP_PP)))), 1);
            [RP_PP_min_loc_y, RP_PP_min_loc_x] = find(RP_PP == min(min(RP_PP(~isnan(RP_PP)))), 1);
            
            [RP_AP_max_loc_y, RP_AP_max_loc_x] = find(RP_AP == max(max(RP_AP(~isnan(RP_AP)))), 1);
            [RP_AP_min_loc_y, RP_AP_min_loc_x] = find(RP_AP == min(min(RP_AP(~isnan(RP_AP)))), 1);
            
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(RP_AC(~isnan(RP_AC))))) num2str(max(max(RP_AC(~isnan(RP_AC))))) num2str(RP_AC_max_loc_x) num2str(RP_AC_max_loc_y) num2str(min(min(RP_AC(~isnan(RP_AC))))) num2str(RP_AC_min_loc_x) num2str(RP_AC_min_loc_y) num2str(sum(sum(RP_AC(~isnan(RP_AC)))))...
                num2str(mean(mean(RP_PC(~isnan(RP_PC))))) num2str(max(max(RP_PC(~isnan(RP_PC))))) num2str(RP_PC_max_loc_x) num2str(RP_PC_max_loc_y) num2str(min(min(RP_PC(~isnan(RP_PC))))) num2str(RP_PC_min_loc_x) num2str(RP_PC_min_loc_y) num2str(sum(sum(RP_PC(~isnan(RP_PC)))))...
                num2str(mean(mean(RP_PP(~isnan(RP_PP))))) num2str(max(max(RP_PP(~isnan(RP_PP))))) num2str(RP_PP_max_loc_x) num2str(RP_PP_max_loc_y) num2str(min(min(LP_PP(~isnan(RP_PP))))) num2str(RP_PP_min_loc_x) num2str(RP_PP_min_loc_y) num2str(sum(sum(RP_PP(~isnan(RP_PP)))))...
                num2str(mean(mean(LP_AP(~isnan(RP_AP))))) num2str(max(max(LP_AP(~isnan(RP_AP))))) num2str(RP_AP_max_loc_x) num2str(RP_AP_max_loc_y) num2str(min(min(LP_AP(~isnan(RP_AP))))) num2str(RP_AP_min_loc_x) num2str(RP_AP_min_loc_y) num2str(sum(sum(RP_AP(~isnan(RP_AP)))))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_quad_RP_stats(index+1, :) = temp_map_stats;
        elseif RP_SAVE
            RP_AC(RP_AC == 0) = 1e-20;
            [RP_AC_max_loc_y, RP_AC_max_loc_x] = find(RP_AC == max(max(RP_AC(~isnan(RP_AC)))), 1);
            [RP_AC_min_loc_y, RP_AC_min_loc_x] = find(RP_AC == min(min(RP_AC(~isnan(RP_AC) & RP_AC ~= 0))), 1);
            
            RP_PC(RP_PC == 0) = 1e-20;
            [RP_PC_max_loc_y, RP_PC_max_loc_x] = find(RP_PC == max(max(RP_PC(~isnan(RP_PC)))), 1);
            [RP_PC_min_loc_y, RP_PC_min_loc_x] = find(RP_PC == min(min(RP_PC(~isnan(RP_PC) & RP_PC ~= 0))), 1);
            
            RP_PP(RP_PP == 0) = 1e-20;
            [RP_PP_max_loc_y, RP_PP_max_loc_x] = find(RP_PP == max(max(RP_PP(~isnan(RP_PP)))), 1);
            [RP_PP_min_loc_y, RP_PP_min_loc_x] = find(RP_PP == min(min(RP_PP(~isnan(RP_PP) & RP_PP ~= 0))), 1);
            
            RP_AP(RP_AP == 0) = 1e-20;
            [RP_AP_max_loc_y, RP_AP_max_loc_x] = find(RP_AP == max(max(RP_AP(~isnan(RP_AP)))), 1);
            [RP_AP_min_loc_y, RP_AP_min_loc_x] = find(RP_AP == min(min(RP_AP(~isnan(RP_AP) & RP_AP ~= 0))), 1);
            
            temp_map_stats = {num2str(time(index)) num2str(mean(mean(RP_AC(~isnan(RP_AC))))) num2str(max(max(RP_AC(~isnan(RP_AC))))) num2str(RP_AC_max_loc_x) num2str(RP_AC_max_loc_y) num2str(min(min(RP_AC(~isnan(RP_AC) & RP_AC ~= 0)))) num2str(RP_AC_min_loc_x) num2str(RP_AC_min_loc_y) num2str(sum(sum(RP_AC(~isnan(RP_AC)))))...
                num2str(mean(mean(RP_PC(~isnan(RP_PC))))) num2str(max(max(RP_PC(~isnan(RP_PC))))) num2str(RP_PC_max_loc_x) num2str(RP_PC_max_loc_y) num2str(min(min(RP_PC(~isnan(RP_PC) & RP_PC ~= 0)))) num2str(RP_PC_min_loc_x) num2str(RP_PC_min_loc_y) num2str(sum(sum(RP_PC(~isnan(RP_PC)))))...
                num2str(mean(mean(RP_PP(~isnan(RP_PP))))) num2str(max(max(RP_PP(~isnan(RP_PP))))) num2str(RP_PP_max_loc_x) num2str(RP_PP_max_loc_y) num2str(min(min(RP_PP(~isnan(RP_PP) & RP_PP ~= 0)))) num2str(RP_PP_min_loc_x) num2str(RP_PP_min_loc_y) num2str(sum(sum(RP_PP(~isnan(RP_PP)))))...
                num2str(mean(mean(RP_AP(~isnan(RP_AP))))) num2str(max(max(RP_AP(~isnan(RP_AP))))) num2str(RP_AP_max_loc_x) num2str(RP_AP_max_loc_y) num2str(min(min(RP_AP(~isnan(RP_AP) & RP_AP ~= 0)))) num2str(RP_AP_min_loc_x) num2str(RP_AP_min_loc_y) num2str(sum(sum(RP_AP(~isnan(RP_AP)))))};
            if strcmp(get(handles.pattern_register, 'Checked'), 'on')
                temp_map_stats(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
            end
            
            map_quad_RP_stats(index+1, :) = temp_map_stats;
        end
                
        if flag == 1
            break;
        end
    end
    
    if LP_SAVE
        csvwrite([pathfile 'LP_' file], map_quad_LP_stats)
    end
    
    if RP_SAVE
        csvwrite([pathfile 'RP_' file], map_quad_RP_stats)
    end
end

% --------------------------------------------------------------------
function save_all_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_all_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.*',  'All Files(*.*)'}, ...
    'Base Filename', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    avg_flag = get(handles.avg_data, 'checked');
    max_cycles = round(handles.length_time/handles.Tl*handles.T);

    if strcmp(avg_flag, 'off')
        if max_cycles > 5 % If there is at least 6 cycles to average from
            handles.start_cycle = 5; % use 5th to last cycle
            handles.end_cycle = 2; % use 2nd to last cycle
        elseif max_cycles > 1 % if max_cycles is less than 6 but greater than 1
            handles.start_cycle = max_cycles-1; % choose the second cycle as the start
            handles.end_cycle = 2; % use second to last cycle as start
        end
        
        guidata(hObject, handles);
    end

    %% For selected ROI
    if handles.curr_select_flag == 1
        handles.base_file = [file '_ROI_stats.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_ROI_CA.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);

        handles.base_file = [file '_ROI_WCoC.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
                        
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        handles.avg_force; %don't know why but is necessary for the handles to be updated TC
        set(handles.avg_data, 'checked', 'on');
        guidata(hObject, handles);
        
        handles.base_file = [file '_ROI_stats_avg.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_ROI_CA_avg.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_ROI_WCoC_avg.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
        
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        set(handles.avg_data, 'checked', avg_flag);
        guidata(hObject, handles);
    else
    %% Both Plateaus
        set(handles.avg_data, 'checked', 'off');
        set(handles.both_plateaus, 'Value', true);
        handles = parse_tekscan_map(hObject, handles);
        handles.base_file = [file '_total_stats.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_total_CA.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_total_WCoC.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
               
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        handles.avg_force; %don't know why but is necessary for the handles to be updated TC
        set(handles.avg_data, 'checked', 'on');
        guidata(hObject, handles);
        
        handles.base_file = [file '_total_stats_avg.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_total_CA_avg.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_total_WCoC_avg.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
        
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        set(handles.avg_data, 'checked', 'off');
        guidata(hObject, handles);

        %% Right Plateau
        set(handles.right_plateau, 'Value', true);
        handles = parse_tekscan_map(hObject, handles);
        handles.base_file = [file '_lateral_stats.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_lateral_CA.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_lateral_WCoC.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
               
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        handles.avg_force; %don't know why but is necessary for the handles to be updated TC
        set(handles.avg_data, 'checked', 'on');
        guidata(hObject, handles);
        
        handles.base_file = [file '_lateral_stats_avg.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_lateral_CA_avg.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_lateral_WCoC_avg.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
        
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        set(handles.avg_data, 'checked', 'off');
        guidata(hObject, handles);
       
        %% Left Plateau
        set(handles.left_plateau, 'Value', true);
        handles = parse_tekscan_map(hObject, handles);
        handles.base_file = [file '_medial_stats.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_medial_CA.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_medial_WCoC.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
                
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        handles.avg_force; %don't know why but is necessary for the handles to be updated TC
        set(handles.avg_data, 'checked', 'on');
        guidata(hObject, handles);

        handles.base_file = [file '_medial_stats_avg.csv'];
        guidata(hObject, handles);
        save_map_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_medial_CA_avg.csv'];
        guidata(hObject, handles);
        save_contact_stats_Callback(hObject, 140, handles);
        
        handles.base_file = [file '_medial_WCoC_avg.csv'];
        guidata(hObject, handles);
        save_centroid_Callback(hObject, 140, handles);
        
        handles = avg_data_Callback(handles.avg_data, 140, handles, handles.start_cycle, handles.end_cycle);
        set(handles.avg_data, 'checked', 'off');
        set(handles.both_plateaus, 'Value', true);
        handles = parse_tekscan_map(hObject, handles);
        guidata(hObject, handles);

        refresh_fig(hObject, handles);      
    end
end
    
% --------------------------------------------------------------------
function save_sector_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_sector_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.csv','Comma Separated File (*.csv)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Current Map Sector Statistics', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        map_sector_LP_AC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_MC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_PC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_AP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_MP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_PP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        
        map_sector_RP_AC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_MC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_PC_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_AP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_MP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_PP_stats(1,:) = {'Percent Gait' 'Flexion Angle [deg]' 'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
    else
        map_sector_LP_AC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_MC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_PC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_AP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_MP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_LP_PP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        
        map_sector_RP_AC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_MC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_PC_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_AP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_MP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
        map_sector_RP_PP_stats(1,:) = {'Time [s]' 'Mean [Pa]' 'Max [Pa]' 'Loc X Max Stress [mm]' 'Loc Y Max Stress [mm]' 'Min [Pa]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [Pa]' 'Contact Area [mm^2]'};
    end
    
    flag = 0;
    selected_condition = get(handles.condition_selector, 'Value');
    time = handles.tekvar{selected_condition}.data_a.time;
    
    for index = 1:handles.length_time
        if get(handles.risk_map_checkbox, 'Value')
            selected_comparison = get(handles.comparison_selector, 'Value');

            switch get(handles.risk_type_dropdown, 'Value')
                case 5
                    mag_roi = handles.curr_plot;
                    flag = 1;
                case 1
                    mag_roi = handles.magnitude_risk(:,:, index);
                case 2
                    mag_risk_total = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 3
                    mag_risk_total = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 4
                    max_mag_risk = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    min_mag_risk = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
                    mag_risk_total = handles.magnitude_risk{selected_condition, selected_comparison}(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total;
                    flag = 1;
                case 6
                    max_mag_risk = max(handles.magnitude_risk,[],3);
                    min_mag_risk = min(handles.magnitude_risk,[],3);
                    mag_risk_total = handles.magnitude_risk(:,:,1);
                    mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
                    mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
                    mag_roi = mag_risk_total.*load_risk;
                    flag = 1;
            end
        else
            mag_roi = handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index));
        end
 
        if get(handles.both_plateaus, 'Value') || get(handles.left_plateau, 'Value')
            LP_AC = get_sector('LP_AC', mag_roi);
            LP_MC = get_sector('LP_MC', mag_roi);
            LP_PC = get_sector('LP_PC', mag_roi);
            LP_PP = get_sector('LP_PP', mag_roi);
            LP_MP = get_sector('LP_MP', mag_roi);
            LP_AP = get_sector('LP_AP', mag_roi);
            
            map_sector_LP_AC_stats(index+1, :) = save_sector_stats(handles, LP_AC, time, index);
            map_sector_LP_MC_stats(index+1, :) = save_sector_stats(handles, LP_MC, time, index);
            map_sector_LP_PC_stats(index+1, :) = save_sector_stats(handles, LP_PC, time, index);
            map_sector_LP_AP_stats(index+1, :) = save_sector_stats(handles, LP_AP, time, index);
            map_sector_LP_MP_stats(index+1, :) = save_sector_stats(handles, LP_MP, time, index);
            map_sector_LP_PP_stats(index+1, :) = save_sector_stats(handles, LP_PP, time, index);
            
            LP_SAVE = 1;
        else
            LP_SAVE = 0;
        end
        
        if get(handles.both_plateaus, 'Value') || get(handles.right_plateau, 'Value')
            RP_AC = get_sector('RP_AC', mag_roi);
            RP_MC = get_sector('RP_MC', mag_roi);
            RP_PC = get_sector('RP_PC', mag_roi);
            RP_PP = get_sector('RP_PP', mag_roi);
            RP_MP = get_sector('RP_MP', mag_roi);
            RP_AP = get_sector('RP_AP', mag_roi);
            
            map_sector_RP_AC_stats(index+1, :) = save_sector_stats(handles, RP_AC, time, index);
            map_sector_RP_MC_stats(index+1, :) = save_sector_stats(handles, RP_MC, time, index);
            map_sector_RP_PC_stats(index+1, :) = save_sector_stats(handles, RP_PC, time, index);
            map_sector_RP_AP_stats(index+1, :) = save_sector_stats(handles, RP_AP, time, index);
            map_sector_RP_MP_stats(index+1, :) = save_sector_stats(handles, RP_MP, time, index);
            map_sector_RP_PP_stats(index+1, :) = save_sector_stats(handles, RP_PP, time, index);
            
            RP_SAVE = 1;
        else
            RP_SAVE = 0;
        end
                
        if flag == 1
            break;
        end
    end
    
    if LP_SAVE
        csvwrite([pathfile 'LP_AC_' file], map_sector_LP_AC_stats, 2)
        csvwrite([pathfile 'LP_MC_' file], map_sector_LP_MC_stats, 2)
        csvwrite([pathfile 'LP_PC_' file], map_sector_LP_PC_stats, 2)
        csvwrite([pathfile 'LP_AP_' file], map_sector_LP_AP_stats, 2)
        csvwrite([pathfile 'LP_MP_' file], map_sector_LP_MP_stats, 2)
        csvwrite([pathfile 'LP_PP_' file], map_sector_LP_PP_stats, 2)
    end
    
    if RP_SAVE
        csvwrite([pathfile 'RP_AC_' file], map_sector_RP_AC_stats, 2)
        csvwrite([pathfile 'RP_MC_' file], map_sector_RP_MC_stats, 2)
        csvwrite([pathfile 'RP_PC_' file], map_sector_RP_PC_stats, 2)
        csvwrite([pathfile 'RP_AP_' file], map_sector_RP_AP_stats, 2)
        csvwrite([pathfile 'RP_MP_' file], map_sector_RP_MP_stats, 2)
        csvwrite([pathfile 'RP_PP_' file], map_sector_RP_PP_stats, 2)
    end
end

function stats = save_sector_stats(handles, raw_data, time, index)

if strcmp(get(handles.include_zero, 'Checked'), 'on')
    [data_max_loc_y, data_max_loc_x] = find(raw_data == max(max(raw_data(~isnan(raw_data)))), 1);
    [data_min_loc_y, data_min_loc_x] = find(raw_data == min(min(raw_data(~isnan(raw_data)))), 1);
        
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        temp_map_stats = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index)) num2str(time(index)) num2str(mean(mean(raw_data(~isnan(raw_data))))) num2str(max(max(raw_data(~isnan(raw_data))))) num2str(data_max_loc_x) num2str(data_max_loc_y) num2str(min(min(raw_data(~isnan(raw_data))))) num2str(data_min_loc_x) num2str(data_min_loc_y) num2str(sum(sum(raw_data(~isnan(raw_data))))) num2str(4*length(curr_map(curr_map>0)))};
    else
        temp_map_stats = {num2str(time(index)) num2str(mean(mean(raw_data(~isnan(raw_data))))) num2str(max(max(raw_data(~isnan(raw_data))))) num2str(data_max_loc_x) num2str(data_max_loc_y) num2str(min(min(raw_data(~isnan(raw_data))))) num2str(data_min_loc_x) num2str(data_min_loc_y) num2str(sum(sum(raw_data(~isnan(raw_data))))) num2str(4*length(curr_map(curr_map>0)))};
    end
    
    stats = temp_map_stats;
else
    [data_max_loc_y, data_max_loc_x] = find(raw_data == max(max(raw_data(~isnan(raw_data)))), 1);
    if ~isempty(raw_data(~isnan(raw_data) & raw_data ~= 0))
        [data_min_loc_y, data_min_loc_x] = find(raw_data == min(min(raw_data(~isnan(raw_data) & raw_data ~= 0))), 1);
        data_min = min(min(raw_data(~isnan(raw_data) & raw_data ~= 0)));
    else
        data_min_loc_y = NaN; data_min_loc_x = NaN;
        data_min = 0;
    end
            
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        temp_map_stats = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index)) num2str(time(index)) num2str(mean(mean(raw_data(~isnan(raw_data))))) num2str(max(max(raw_data(~isnan(raw_data))))) num2str(data_max_loc_x) num2str(data_max_loc_y) num2str(data_min) num2str(data_min_loc_x) num2str(data_min_loc_y) num2str(sum(sum(raw_data(~isnan(raw_data))))) num2str(4*length(raw_data(raw_data>0)))};
    else
        temp_map_stats = {num2str(time(index)) num2str(mean(mean(raw_data(~isnan(raw_data))))) num2str(max(max(raw_data(~isnan(raw_data))))) num2str(data_max_loc_x) num2str(data_max_loc_y) num2str(data_min) num2str(data_min_loc_x) num2str(data_min_loc_y) num2str(sum(sum(raw_data(~isnan(raw_data))))) num2str(4*length(raw_data(raw_data>0)))};
    end
    
    stats = temp_map_stats;
end
        
% --------------------------------------------------------------------
function save_center_contact_Callback(hObject, eventdata, handles)
% hObject    handle to save_center_contact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.csv','Comma Separated File (*.csv)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Center of Contact Data', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    loc = save_center_contact(handles);
    
    csvwrite([pathfile file], loc, 2);
end

function loc = save_center_contact(handles)
selected_condition = get(handles.condition_selector, 'Value');

Left_I = 0; Left_J = 0; Right_I = 0; Right_J = 0;

rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;
time = handles.tekvar{selected_condition}.data_a.time;

loc(1,:) = {'Time' 'Left_X [mm from origin]' 'Left_Y [mm from origin]' 'Right_X [mm from origin]' 'Right_Y [mm from origin]'};

if strcmp(get(handles.pattern_register, 'Checked'), 'on')
    loc(1,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
end

if ~get(handles.risk_map_checkbox, 'Value')
    for index = 1:handles.length_time
        if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            [Left_I, Left_J] = centroid_location(abs(handles.senselvar{selected_condition}(1:rows,1:round(cols/2),handles.time_order{selected_condition}(index))), str2num(get(handles.noise_floor_edit, 'String')), false);
        end
        
        if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
            [Right_I, Right_J] = centroid_location(abs(handles.senselvar{selected_condition}(1:rows,(cols-round(cols/2)):cols,handles.time_order{selected_condition}(index))), str2num(get(handles.noise_floor_edit, 'String')), false);
        end
        
        temp_loc = {num2str(time(index)) num2str(Left_J) num2str(Left_I) num2str(Right_J+cols/2) num2str(Right_I)};
        
        if strcmp(get(handles.pattern_register, 'Checked'), 'on')
            temp_loc(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
        end
        
        loc(index+1, :) = temp_loc;
    end
else
    if get(handles.left_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [Left_I, Left_J] = centroid_location(abs(handles.curr_plot(1:rows,1:round(cols/2))), str2num(get(handles.noise_floor_edit, 'String')), false);
    end
    
    if get(handles.right_plateau, 'Value') || get(handles.both_plateaus, 'Value')
        [Right_I, Right_J] = centroid_location(abs(handles.curr_plot(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), false);
    end
    
    temp_loc = {num2str(handles.T) num2str(Left_J) num2str(Left_I) num2str(Right_J+cols/2) num2str(Right_I)};
    
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
%         temp_loc(1,end+1:end+2) = {num2str(handles.gait_time(index)/handles.Tl*100) num2str(handles.flexion_rep(index))};
    end
    
    loc(2, :) = temp_loc;
end


% --------------------------------------------------------------------
function compare_outputs_Callback(hObject, eventdata, handles)
% hObject    handle to compare_outputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function sim_output_Callback(hObject, eventdata, handles)
% hObject    handle to sim_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mocap_output_Callback(hObject, eventdata, handles)
% hObject    handle to mocap_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
num_gait_cycle = round(handles.length_time/handles.Tl*handles.T);
selected_condition = get(handles.condition_selector, 'Value');

secs_per_cycle =str2double(get(handles.cycle_time, 'String'));
sample_rate = 50; % Motion Capture Sampling Rate
time_interval = 1/sample_rate; % Motion Capture Sample Time Interval
window_length = sample_rate*secs_per_cycle; % Number of motion capture samples collected for 20 cycles (sample_rate*time_for_one_cycle*
twenty_cycles = window_length*20; % Number of motion capture samples collected for 20 cycles (sample_rate*time_for_one_cycle*
avg_start = twenty_cycles;

num_items = numel(handles.kinematics(selected_condition).order);
num_cycles_avg = 18;

% handles.kinematics(selected_condition).order = []; %Order of kinematic directions in menu
% order key: AP=1 ML=2 PD=3 IE=4 FA=5 VV=6 dAP=7 dML=8 dPD=9 dIE=10 dFA=11 dVV=12

handles.kinematics(selected_condition).AP = []; %Anterior Posterior
handles.kinematics(selected_condition).ML = []; %Medial Lateral
handles.kinematics(selected_condition).PD = []; %Proximal Distal
handles.kinematics(selected_condition).IE = []; %Interal External Rotation
handles.kinematics(selected_condition).FA = []; %Flexion Angle
handles.kinematics(selected_condition).VV = []; %Varus Valgus

[Xfile, Xpath]=uigetfile(...
    {'*.xls','Excel files(*.xls)';...
    '*.*',  'All Files(*.*)'}, ...
    'Pick a Motion Capture file', handles.path);

if ~isequal(Xfile,0)
    handles.path = Xpath;

    set(handles.show_derivs, 'Visible', 'on');
    
    [kinematics, names] = xlsread([Xpath Xfile]); %open motion capture file
    
    guidata(hObject, handles);
    
    run_samples = numel(kinematics(:,1));
    run_length = numel(kinematics(:,1))/sample_rate;

    if run_length <= 20*secs_per_cycle
        run_length = 22*secs_per_cycle;
        run_samples = run_length*sample_rate;
    end

    cycle_time = (linspace(time_interval, run_length, run_samples))';
    sample_time = (linspace(time_interval, secs_per_cycle, secs_per_cycle*sample_rate))';
      
    current_array = get(handles.second_axis, 'String');
    
    for i = 1:numel(names)
        switch names{i}
            case 'Anterior+'
                AP = kinematics(:,i); %Anterior Posterior
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'AP'),1))
                    handles.kinematics(selected_condition).order{i+num_items} = 'AP';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Anterior+/Posterior [mm]';
                    handles.kinematics(selected_condition).units{i+num_items} = 'mm';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Anterior+/Posterior)/(dt) [mm/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = 'mm/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
            case 'Lateral+'
                ML = kinematics(:,i); %Medial-Lateral (mm)              
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'ML'),1))
                    handles.kinematics(selected_condition).order{i+num_items}= 'ML';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Medial/Lateral+ [mm]';
                    handles.kinematics(selected_condition).units{i+num_items} = 'mm';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Medial/Lateral+)/(dt) [mm/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = 'mm/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
            case 'Proximal+'    
                PD = kinematics(:,i); %Proximal-Distal (mm)      
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'PD'),1))
                    handles.kinematics(selected_condition).order{i+num_items} = 'PD';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Proximal+/Distal [mm]';
                    handles.kinematics(selected_condition).units{i+num_items} = 'mm';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Proximal+/Distal)/(dt) [mm/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = 'mm/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
            case 'Int Rot+'
                IE = kinematics(:,i); %Interal-External Rotation (mm)
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'IE'),1))
                    handles.kinematics(selected_condition).order{i+num_items} = 'IE';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Internal+/External Rotation [^o]';
                    handles.kinematics(selected_condition).units{i+num_items} = '^o';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Internal+/External)/(dt) [^o/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = '^o/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
            case 'Flexion+'
                FA = kinematics(:,i); %Flexion Angle (o)                
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'FA'),1))
                    handles.kinematics(selected_condition).order{i+num_items} = 'FA';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Flexion Angle+ [^o]';
                    handles.kinematics(selected_condition).units{i+num_items} = '^o';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Flexion Angle+)/(dt) [^o/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = '^o/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
            case 'Valgus+'
                VV = kinematics(:,i); %Varus-Valgus (o)                
                if isempty(find(strcmp(handles.kinematics(selected_condition).order,'VV'),1))
                    handles.kinematics(selected_condition).order{i+num_items} = 'VV';
                    handles.kinematics(selected_condition).name{i+num_items} = 'MoCap: Varus/Valgus+ [^o]';
                    handles.kinematics(selected_condition).units{i+num_items} = '^o';
                    handles.kinematics(selected_condition).dname{i+num_items} = 'MoCap: d(Varus/Valgus+)/(dt) [^o/s]';
                    handles.kinematics(selected_condition).dunits{i+num_items} = '^o/s';
                    current_array{end+1} = handles.kinematics(selected_condition).name{i+num_items};
                end
        end
    end
               
    flexion_spline = spline(handles.gait_time(1:handles.window_size), handles.flexion_rep(1:handles.window_size), sample_time);
    
    flexion_rep = repmat(flexion_spline, ceil(run_length), 1);
    
    if run_length < window_length*num_cycles_avg
        num_cycles_avg = floor(numel(AP)/window_length)-2;
        avg_start = (num_cycles_avg+1)*window_length;
    end
    
    mean_AP = AP(avg_start-window_length+1:avg_start);
    mean_ML = ML(avg_start-window_length+1:avg_start);
    mean_PD = PD(avg_start-window_length+1:avg_start);
    mean_IE = IE(avg_start-window_length+1:avg_start);
    mean_flexion = FA(avg_start-window_length+1:avg_start);
    mean_VV = VV(avg_start-window_length+1:avg_start);
        
    for a = 2:num_cycles_avg
        mean_AP = mean_AP + AP(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
        mean_ML = mean_ML + ML(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
        mean_PD = mean_PD + PD(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
        mean_IE = mean_IE + IE(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
        mean_flexion = mean_flexion + FA(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
        mean_VV = mean_VV + VV(avg_start-a*window_length+1:avg_start-(a-1)*window_length);
    end
    
    mean_AP = mean_AP/18;
    mean_ML = mean_ML/18;
    mean_PD = mean_PD/18;
    mean_IE = mean_IE/18;
    mean_flexion = mean_flexion/18;
    mean_VV = mean_VV/18;
    
    AP = repmat(mean_AP, ceil(run_length/secs_per_cycle), 1);
    ML = repmat(mean_ML, ceil(run_length/secs_per_cycle), 1);
    PD = repmat(mean_PD, ceil(run_length/secs_per_cycle), 1);
    IE = repmat(mean_IE, ceil(run_length/secs_per_cycle), 1);
    FA = repmat(mean_flexion, ceil(run_length/secs_per_cycle), 1);
    VV = repmat(mean_VV, ceil(run_length/secs_per_cycle), 1);

    flexion_results = tekscan_time_registration(FA(1:twenty_cycles),flexion_rep(1:twenty_cycles),100,2);

%     AP_shift = [AP(flexion_results.time_shift:end); AP(1:flexion_results.time_shift-1)]; dAP = diff(AP_shift)/time_interval;
%     ML_shift = [ML(flexion_results.time_shift:end); ML(1:flexion_results.time_shift-1)]; dML = diff(ML_shift)/time_interval;
%     PD_shift = [PD(flexion_results.time_shift:end); PD(1:flexion_results.time_shift-1)]; dPD = diff(PD_shift)/time_interval;
%     IE_shift = [IE(flexion_results.time_shift:end); IE(1:flexion_results.time_shift-1)]; dIE = diff(IE_shift)/time_interval;
%     FA_shift = [FA(flexion_results.time_shift:end); FA(1:flexion_results.time_shift-1)]; dFA = diff(FA_shift)/time_interval;
%     VV_shift = [VV(flexion_results.time_shift:end); VV(1:flexion_results.time_shift-1)]; dVV = diff(VV_shift)/time_interval;
    AP_shift = [AP(flexion_results.time_shift:end); AP(1:flexion_results.time_shift-1)]; 
    dAP = deriv(AP_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);
    ML_shift = [ML(flexion_results.time_shift:end); ML(1:flexion_results.time_shift-1)]; dML = deriv(ML_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);
    PD_shift = [PD(flexion_results.time_shift:end); PD(1:flexion_results.time_shift-1)]; dPD = deriv(PD_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);
    IE_shift = [IE(flexion_results.time_shift:end); IE(1:flexion_results.time_shift-1)]; dIE = deriv(IE_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);
    FA_shift = [FA(flexion_results.time_shift:end); FA(1:flexion_results.time_shift-1)]; dFA = deriv(FA_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);
    VV_shift = [VV(flexion_results.time_shift:end); VV(1:flexion_results.time_shift-1)]; dVV = deriv(VV_shift(1:twenty_cycles),cycle_time(1:twenty_cycles),2);

    handles.kinematics(selected_condition).cycle_time = cycle_time(1:twenty_cycles);
    
    handles.kinematics(selected_condition).AP_save = AP_shift(1:twenty_cycles);
    handles.kinematics(selected_condition).ML_save = ML_shift(1:twenty_cycles);
    handles.kinematics(selected_condition).PD_save = PD_shift(1:twenty_cycles);
    handles.kinematics(selected_condition).IE_save = IE_shift(1:twenty_cycles);
    handles.kinematics(selected_condition).FA_save = FA_shift(1:twenty_cycles);
    handles.kinematics(selected_condition).VV_save = VV_shift(1:twenty_cycles);

    handles.kinematics(selected_condition).dAP_save = dAP(1:twenty_cycles);
    handles.kinematics(selected_condition).dML_save = dML(1:twenty_cycles);
    handles.kinematics(selected_condition).dPD_save = dPD(1:twenty_cycles);
    handles.kinematics(selected_condition).dIE_save = dIE(1:twenty_cycles);
    handles.kinematics(selected_condition).dFA_save = dFA(1:twenty_cycles);
    handles.kinematics(selected_condition).dVV_save = dVV(1:twenty_cycles);

    handles.kinematics(selected_condition).AP = interp1(cycle_time(1:twenty_cycles), AP_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).ML = interp1(cycle_time(1:twenty_cycles), ML_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).PD = interp1(cycle_time(1:twenty_cycles), PD_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).IE = interp1(cycle_time(1:twenty_cycles), IE_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).FA = interp1(cycle_time(1:twenty_cycles), FA_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).VV = interp1(cycle_time(1:twenty_cycles), VV_shift(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);

    handles.kinematics(selected_condition).dAP = interp1(cycle_time(1:twenty_cycles), dAP(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).dML = interp1(cycle_time(1:twenty_cycles), dML(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).dPD = interp1(cycle_time(1:twenty_cycles), dPD(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).dIE = interp1(cycle_time(1:twenty_cycles), dIE(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).dFA = interp1(cycle_time(1:twenty_cycles), dFA(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    handles.kinematics(selected_condition).dVV = interp1(cycle_time(1:twenty_cycles), dVV(1:twenty_cycles), handles.tekvar{selected_condition}.data_a.time);
    
%     set(handles.second_axis, 'String', current_array);
    
    set(handles.second_axis, 'String', handles.kinematics(selected_condition).name)
    
    guidata(hObject, handles);
    
%     figure
%     plot(handles.tekvar{selected_condition}.data_a.time, handles.kinematics(selected_condition).dAP);
%     hold on
%     plot(cycle_time(1:twenty_cycles), dAP(1:twenty_cycles), 'k--')
%     
% %     plot(cycle_time(1:twenty_cycles), flexion_results.pattern_of_interest(1:twenty_cycles));
%     plot(handles.tekvar{selected_condition}.data_a.time, handles.flexion_rep);
%     
%     hold on
% %     plot(cycle_time(1:twenty_cycles), flexion_rep(1:twenty_cycles), 'r-');
%     plot([0 handles.tekvar{selected_condition}.data_a.time(end)], [0 0], 'k');
%     plot(handles.tekvar{selected_condition}.data_a.time, handles.kinematics(selected_condition).VV, 'r--');
%     plot(handles.tekvar{selected_condition}.data_a.time, handles.kinematics(selected_condition).dVV, 'g--');
    refresh_fig(hObject, handles)
end

function out = deriv(num, denom, envelope)

if numel(num) == numel(denom)
    out(1:envelope) = NaN*ones(1,envelope); 
    out(numel(num)-envelope+1:numel(num)) = NaN*ones(1,envelope);
    for index = envelope+1:numel(num)-envelope
        out(index) = (num(index-envelope) - num(index+envelope))/(denom(index-envelope) - denom(index+envelope));
    end
else
    error('Matrix num and denom are of different lengths')
end
            
% function out = deriv(num, envelope)
% 
%     out(1:envelope) = NaN*ones(envelope,1); 
%     out(numel(num)-envelope+1:numel(num)) = NaN*ones(envelope,1);
%     
%     for index = envelope+1:numel(num)-envelope
%         out(index) = (num(index-envelope) - num(index+envelope));
%     end
    
% --------------------------------------------------------------------
function save_kinematics_Callback(hObject, eventdata, handles)
% hObject    handle to save_kinematics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.csv','Comma Separated File (*.csv)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Current Map Kinematics', handles.path);

if ~isequal(file,0)
    flag = 0;

    handles.path = pathfile;
    guidata(hObject, handles);

    kinematics_stats(1,:) = {'Time [s]' 'Percent Gait' 'Flexion Angle [o]' 'Anterior+/Posterior [mm]' 'd(Anterior+/Posterior)/dt [mm/s]' 'Medial/Lateral+ [mm]' 'd(Medial/Lateral+)/dt [mm/s]' 'Proximal+/Distal [mm]' 'd(Proximal+/Distal)/dt [mm/s]' 'Interal+/External [o]' 'd(Interal+/External)/dt [o/s]' 'Varus/Valgus+ [o]' 'd(Varus/Valgus+)/dt [o/s]'};
    
    selected_condition = get(handles.condition_selector, 'Value');
    kinematics = handles.kinematics(selected_condition);
    
    ctime = handles.tekvar{selected_condition}.data_a.time;
    cgait = handles.gait_time/handles.Tl*100;
    
    for index = 1:handles.length_time
        temp_kinematics = {num2str(ctime(index)) num2str(cgait(index)) num2str(kinematics.FA(index)) num2str(kinematics.AP(index)) num2str(kinematics.dAP(index)) num2str(kinematics.ML(index)) num2str(kinematics.dML(index)) num2str(kinematics.PD(index)) num2str(kinematics.dPD(index)) num2str(kinematics.IE(index)) num2str(kinematics.dIE(index)) num2str(kinematics.VV(index)) num2str(kinematics.dVV(index))};
        kinematics_stats(index+1, :) = temp_kinematics;
    end

    csvwrite([pathfile file], kinematics_stats)
end


% --------------------------------------------------------------------
function save_sim_Callback(hObject, eventdata, handles)
% hObject    handle to save_sim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in show_derivs.
function show_derivs_Callback(hObject, eventdata, handles)
% hObject    handle to show_derivs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_derivs
refresh_fig(hObject, handles);


% --- Executes on mouse press over axes background.
function pressure_map_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pressure_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject, handles);

window_size = handles.window_size;

curr_point = get(hObject, 'CurrentPoint');

flag = 0;
selected_condition = get(handles.condition_selector, 'Value');
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
% time = handles.tekvar{selected_condition}.data_a.time;

if strcmp(get(handles.avg_data, 'Checked'), 'on')
    senselvar = handles.avg_senselvar;
    time_order = handles.avg_time_order;
    force = handles.avg_force;
    time = handles.avg_time;
    if  handles.mag_calced
        magnitude_risk = handles.avg_magnitude_risk;
    end
    avg_on = true;
else
    senselvar = handles.senselvar;
    time_order = handles.time_order;
    force = handles.force{selected_condition};
    time = handles.tekvar{selected_condition}.data_a.time;
    if  handles.mag_calced
        magnitude_risk = handles.magnitude_risk;
    end
    avg_on = false;
end

length_time = length(time);
max_cycles = floor(length_time/window_size);

% get cycle range of interest to average
[start_cycle, end_cycle] = getCycles(handles.avg_data,handles,max_cycles);

curr_sensels = mat2cell(senselvar{selected_condition}, ones(size(senselvar{selected_condition},1),1)...
    , ones(size(senselvar{selected_condition},2),1), size(senselvar{selected_condition},3));

% gets elements within the selected range of cycles
range_of_interest = window_size*(max_cycles-start_cycle)+1:window_size*(max_cycles-end_cycle)+window_size;
num_of_cycle = length(range_of_interest)/window_size;

if get(handles.risk_map_checkbox, 'Value')
    selected_comparison = get(handles.comparison_selector, 'Value');
    comp_sensels = mat2cell(senselvar{selected_comparison}, ones(size(senselvar{selected_comparison},1),1)...
        , ones(size(senselvar{selected_comparison},2),1), size(senselvar{selected_comparison},3));
    
    switch get(handles.risk_type_dropdown, 'Value')
        case 5
            mag_roi = handles.load_risk{selected_condition, selected_comparison}(floor(curr_point(1,2)), floor(curr_point(1,1)));
            
            figure(550)
            pattern1 = reshape(curr_sensels{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
            pattern2 = reshape(comp_sensels{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
%             pattern1 = reshape(handles.sensels{selected_condition}{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
%             pattern2 = reshape(handles.sensels{selected_comparison}{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
            if avg_on
                p = plot([time' time'], [pattern1 pattern2]);
            else
                p = plot([time time], [pattern1(handles.time_order{selected_condition}) pattern2(handles.time_order{selected_comparison})]);
            end
            
            p(1).Parent.FontWeight = 'Bold';
            p(1).Parent.FontSize = 12;
            p(1).LineWidth = 1; p(2).LineWidth = 1;
            p(2).LineStyle = '-.';
            title(['\fontsize{16}Sensel: (' num2str(floor(curr_point(1,1))) ', ' num2str(floor(curr_point(1,2))) ')    Difference: ' num2str(round(mag_roi*100,1)) '%']);
            xlabel('\fontsize{16}Time [s]');
            ylabel('\fontsize{16}Stress [MPa]');
            legend(handles.tekvar_name{selected_condition}, handles.tekvar_name{selected_comparison});       
        case 1
            mag_roi = handles.magnitude_risk{selected_condition, selected_comparison}(floor(curr_point(1,2)), floor(curr_point(1,1)), index);
        case 2
            mag_risk_total = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
            mag_roi = mag_risk_total(floor(curr_point(1,2)),floor(curr_point(1,1)));
        case 3
            mag_risk_total = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
            mag_roi = mag_risk_total(floor(curr_point(1,2)),floor(curr_point(1,1)));
        case 4
            max_mag_risk = max(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
            min_mag_risk = min(handles.magnitude_risk{selected_condition, selected_comparison},[],3);
            mag_risk_total = handles.magnitude_risk{selected_condition, selected_comparison}(:,:,1);
            mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
            mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
            mag_roi = mag_risk_total(floor(curr_point(1,2)),floor(curr_point(1,1)));
            
            figure(550)
            pattern1 = reshape(handles.sensels{selected_condition}{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
            pattern2 = reshape(handles.sensels{selected_comparison}{floor(curr_point(1,2)), floor(curr_point(1,1))},length_time,1);
            diff = pattern2(handles.time_order{selected_comparison})-pattern1(handles.time_order{selected_condition});

            p = plot(handles.tekvar{selected_condition}.data_a.time, diff);
            p(1).Parent.FontWeight = 'Bold';
            p(1).Parent.FontSize = 12;
            p(1).LineWidth = 1;
            xlim([20 38.11]);
            title(['\fontsize{16}Sensel: (' num2str(floor(curr_point(1,1))) ', ' num2str(floor(curr_point(1,2))) ')    Max Diff: ' num2str(max(max(diff)))  ' MPa    Min Diff: ' num2str(min(min(diff))) ' MPa']);
            xlabel('\fontsize{16}Time [s]');
            ylabel('\fontsize{16}Stress [MPa]');
        case 6
            max_mag_risk = max(handles.magnitude_risk,[],3);
            min_mag_risk = min(handles.magnitude_risk,[],3);
            mag_risk_total = handles.magnitude_risk(:,:,1);
            mag_risk_total(max_mag_risk>abs(min_mag_risk)) = max_mag_risk(max_mag_risk>abs(min_mag_risk));
            mag_risk_total(max_mag_risk<abs(min_mag_risk)) = min_mag_risk(max_mag_risk<abs(min_mag_risk));
            mag_roi = mag_risk_total.*load_risk;
            mag_roi = mag_roi(floor(curr_point(1,2)),floor(curr_point(1,1)));
    end
else
    mag_roi = handles.senselvar{selected_condition}(floor(curr_point(1,2)),floor(curr_point(1,1)),handles.time_order{selected_condition}(index));

    if ~isnan(mag_roi)
     h = msgbox(['Force: ' num2str(mag_roi*4) ' N  |  Stress: ' num2str(mag_roi) ' MPa'], ['Sensel [' num2str(floor(curr_point(1,1))) ', ' num2str(floor(curr_point(1,2))) '] Value'], 'help', 'modal');
     uiwait(h)
    end
end



% --------------------------------------------------------------------
function polygon_selection_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.curr_select_flag = 1;
handles.inon = true;

selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

handles.roibnd = {};
axes(handles.pressure_map);
h = impoly(gca);
position = wait(h);
setColor(h,'r');
handles.in = zeros(rows,cols);
handles.roibnd{1, 1} = round([position; position(1,:)]);

for leng = 1:handles.window_size
    locs = rem(leng,handles.window_size)+(floor(leng/handles.window_size)*handles.window_size);
    handles.roibnd{1,locs} = [position; position(1,:)];
end

clear position;

handles = calc_in(hObject, handles);
        
guidata(hObject, handles)
refresh_fig(hObject, handles)

function roi_mtx = get_selection_ele(mtx, region)
% select the region of interest
% mtx is the original matrix (may contain NaNs)
% region is the logical matrix specific the region of interest,
% 1-interested, 0-not interested
% i.e. a = [4 5 34 1 0 NaN; 23 90 -2 NaN -3 87; NaN NaN 432 -8 -98 -12; 8 90 -8 -65 -10 NaN];
% b = [1 1 0 0 0 0; 0 0 1 1 0 1; 0 0 0 0 0 1; 1 1 0 1 1 0];
% roi = get_selection(a, b);
[rows, cols] = size(mtx);
for irow = 1:rows
    for icol = 1:cols
        if region(irow,icol) == 1
            roi_mtx(irow,icol) = mtx(irow,icol);
        else
            roi_mtx(irow,icol) = NaN;
        end
    end
end


% --------------------------------------------------------------------
function Plotting_Callback(hObject, eventdata, handles)
% hObject    handle to Plotting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function FrameRange_Callback(hObject, eventdata, handles)
% hObject    handle to FrameRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
else
    set(hObject, 'Checked', 'on')
end
disp('==============================================');
temps = input('please specify the range of frame for plotting,\nthe ensembled average along a complete gait cycle\nwill be plotted. eg [3201, 3800]:','s');
if isempty(temps)
    temps = '[3201, 3800]';
end
tempf = sscanf(temps, '%1s%u%1s%u%1s');
handles.range_plotting = tempf([2,4]);
fprintf('The frames will be cut from %u to %u.',handles.range_plotting(1), handles.range_plotting(2));
guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function PlotForceandArea_Callback(hObject, eventdata, handles)
% hObject    handle to PlotForceandArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% [file pathfile]=uiputfile(...
%     {'*.mat','Matlab Data File (*.mat)';...
%     '*.*',  'All Files(*.*)'}, ...
%     'Save Centroid Data', handles.path);
% handles.path = pathfile;
% guidata(hObject, handles);
% ----------Contact forces---------
file = (get(handles.condition_selector, 'String'));
file = file{get(handles.condition_selector, 'Value')};

map_stats(1,:) = {'Time [s]' 'Mean [N]' 'Max [N]' 'Loc X Max Force [mm]' 'Loc Y Max Force [mm]' 'Min [N]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [N]'};
if strcmp(get(handles.pattern_register, 'Checked'), 'on')
    map_stats(1,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
end
flag = 0;
selected_condition = get(handles.condition_selector, 'Value'); %the current trial selection in VIEW list.
time = handles.tekvar{selected_condition}.data_a.time;
frames = handles.range_plotting(1):handles.range_plotting(2);
for index = frames %1:handles.length_time
    %whs,output the pressue of the selected region of interest
    if handles.curr_select_flag == 1
        mag_roi = get_selection_ele(handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index)),handles.in);
    else
        mag_roi = handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index));
    end
    if strcmp(get(handles.include_zero, 'Checked'), 'on')
        [max_loc_y, max_loc_x] = find(mag_roi == max(max(mag_roi(~isnan(mag_roi)))), 1); %the location is the index of sencell, which is the 1/2 of absolute coordinate.
        [min_loc_y, min_loc_x] = find(mag_roi == min(min(mag_roi(~isnan(mag_roi)))), 1);
        temp_map_stats = [time(index) mean(mean(mag_roi(~isnan(mag_roi)))) max(max(mag_roi(~isnan(mag_roi)))) max_loc_x max_loc_y min(min(mag_roi(~isnan(mag_roi)))) min_loc_x min_loc_y sum(sum(mag_roi(~isnan(mag_roi))))];
        if strcmp(get(handles.pattern_register, 'Checked'), 'on')
            temp_map_stats(1,end+1:end+2) = [handles.gait_time(index)/handles.Tl*100, handles.flexion_rep(index)];
        end
        map_stats2(index, :) = temp_map_stats;
    else
        [max_loc_y, max_loc_x] = find(mag_roi == max(max(mag_roi(~isnan(mag_roi)))), 1);
        if ~isempty(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))
            [min_loc_y, min_loc_x] = find(mag_roi == min(min(mag_roi(~isnan(mag_roi) & mag_roi ~= 0))), 1);
        else
            [min_loc_y, min_loc_x] = find(mag_roi == 0,1);
        end
        temp_map_stats = [time(index) mean(mean(mag_roi(~isnan(mag_roi) & mag_roi~=0)*4)) max(max(mag_roi(~isnan(mag_roi))*4)) max_loc_x max_loc_y min(min(mag_roi(~isnan(mag_roi))*4)) min_loc_x min_loc_y sum(sum(mag_roi(~isnan(mag_roi))*4))]; %edited by WHS, before there're error when no active sensel in the selected region.
        if strcmp(get(handles.pattern_register, 'Checked'), 'on')
            temp_map_stats(1,end+1:end+2) = [handles.gait_time(index)/handles.Tl*100 handles.flexion_rep(index)];
        end
        map_stats2(index, :) = temp_map_stats;
    end
    if flag == 1
        break;
    end
end
map_stats2 = map_stats2(frames,:);
NumofCycle = round(size(map_stats2,1)/(handles.Fs*2)); %cycle is 2s
map_stats2_mean = zeros(handles.Fs*2,size(map_stats2,2));
for i = 1:NumofCycle
    map_stats2_mean = map_stats2_mean + map_stats2(1 + (i-1)*2*handles.Fs:i*2*handles.Fs, :);
end
map_stats2_mean = map_stats2_mean/NumofCycle;
map_stats2_mean = convert100(map_stats2_mean, 1:2*handles.Fs, 100);
var_name_map_stats = map_stats;
% ----------Contact area---------
var_name_contact_area(1,:) = {'Time [s]' 'Contact Area [mm^2]'};
if strcmp(get(handles.pattern_register, 'Checked'), 'on')
    var_name_contact_area(1,end+1:end+2) = {'Percent Gait' 'Flexion Angle [deg]'};
end
for index = frames %1:handles.length_time
    curr_map = handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index));
    if handles.curr_select_flag == 1
        curr_map = get_selection_ele(handles.senselvar{selected_condition}(:,:,handles.time_order{selected_condition}(index)),handles.in);
    end
    temp_contact_area = [time(index) 4*length(curr_map(curr_map>0))];
    if strcmp(get(handles.pattern_register, 'Checked'), 'on')
        temp_contact_area(1,end+1:end+2) = [handles.gait_time(index)/handles.Tl*100 handles.flexion_rep(index)];
    end
    contact_area2(index,:) = temp_contact_area;
end
contact_area2 = contact_area2(frames,:);
contact_area2_mean = zeros(handles.Fs*2,size(contact_area2,2));
for i = 1:NumofCycle
    contact_area2_mean = contact_area2_mean + contact_area2(1 + (i-1)*2*handles.Fs:i*2*handles.Fs, :);
end
contact_area2_mean = contact_area2_mean/NumofCycle;
contact_area2_mean = convert100(contact_area2_mean, 1:2*handles.Fs, 100);
%----------------------------------
plotting_map_stats(handles, map_stats2_mean, contact_area2_mean); %plot it out;
handles.map_stats2_mean{get(handles.condition_selector, 'Value')} = map_stats2_mean;
handles.contact_area2_mean{get(handles.condition_selector, 'Value')} = contact_area2_mean;
guidata(hObject, handles);
set(gcf,'name',[file '_forces'],'numbertitle','off');

saveas(gcf,[file '_forces']);

function plotting_map_stats(handles, map_stats2_mean, contact_area2_mean)
%==========================
%------------------plotting---------------------
linesize = 1.5;
mkrsize = 4;
xrange = 0:100;
toeoff = 53;
lines = {'b','-ob','g','r','m',...
    'b--','r--','g--','c--','m--',...
    'b.','r.','g.','c.','m.'}; %different line type for different variables
figure;
hold on;
map_stats(1,:) = {'Time [s]' 'Mean [N]' 'Max [N]' 'Loc X Max Force [mm]' 'Loc Y Max Force [mm]' 'Min [N]' 'Loc X Min Stress [mm]' 'Loc Y Min Stress [mm]' 'Sum [N]'};

get(handles.both_plateaus, 'Value')
subplot(3,4,1), hold on;
plot(xrange,map_stats2_mean(:,2)/4,lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Pressure (MPa)'); title('Mean Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
subplot(3,4,2), hold on;
plot(xrange,map_stats2_mean(:,3)/4,lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Pressure (MPa)'); title('Maximum Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
subplot(3,4,3), hold on;
plot(xrange,map_stats2_mean(:,9),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Force (N)'); title('Total Force'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
subplot(3,4,4), hold on;
plot(xrange,contact_area2_mean(:,2),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Area (mm^2)'); title('Contact Area'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);


subplot(3,4,5), hold on;
plot(xrange,map_stats2_mean(:,5)*2,lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Ant  (mm)   Post'); title('Loc Y of Max Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
subplot(3,4,6), hold on;
plot(xrange,map_stats2_mean(:,4)*2,lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
ylabel('Med   (mm)    Lat'); title('Loc X of Max Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);

%-----------plot the trajectories of CoS on the tibial plateau------------
set(handles.run, 'Enable', 'on');
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
selected_condition = get(handles.condition_selector, 'Value');
senselvar = handles.senselvar;
time_order = handles.time_order;
subplot(3,4,[7 8 11 12]), hold on;
contourf(gca, senselvar{selected_condition}(:,:,time_order{selected_condition}(index)),90, 'LineStyle', 'none'); %creates a contour map of the current plateau with time
colormap([0 0 0;jet])
axis equal;

    plot(map_stats2_mean(1:toeoff,4),map_stats2_mean(1:toeoff,5),'w','linewidth', 0.5); box on;
    plot(map_stats2_mean(1,4),map_stats2_mean(1,5),'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
    plot(map_stats2_mean(14,4),map_stats2_mean(14,5),'sk','linewidth',0.5, 'markersize',5,'markerfacecolor','w'); box on;
    plot(map_stats2_mean(45,4),map_stats2_mean(45,5),'ok','linewidth',0.5, 'markersize',5,'markerfacecolor','w'); box on;
    plot(map_stats2_mean(toeoff,4),map_stats2_mean(toeoff,5),'^k','linewidth',0.5, 'markersize',5,'markerfacecolor','w'); box on;

    xlabel('Med   (No. sensel)    Lat'); ylabel('Ant   (No. sensel)    Pos'); title('Trajectory of the peak stress');
clear index selected_condition senselvar time_order

%----------Plot the inputs------------
gait_cycle = load([handles.Gpath handles.Gfile]);
gait_time = (linspace(0,handles.Tl,numel(gait_cycle.force)))';
sample_time = (linspace(handles.T, handles.Tl, 100))';
axial_force = spline(gait_time, gait_cycle.force, sample_time);
flexion = spline(gait_time, gait_cycle.flexion, sample_time);
AP_force = spline(gait_time, gait_cycle.AP, sample_time);
IE_torque = spline(gait_time, gait_cycle.torque, sample_time);
subplot(3,4,9), hold on;
[AX,H1,H2] = plotyy(1:100,[axial_force AP_force],1:100,IE_torque,'plot'); %#ok<*PLOTYY> %double y-axis
set(get(AX(1),'Ylabel'),'String','Force (N)')
set(get(AX(2),'Ylabel'),'String','Torque (Nm)');
xlabel('Gait %');
title('Inputs(Axial force,AP force,IE torque)');
set(H1,'LineStyle','-','linewidth',2);
set(H2,'LineStyle',':','linewidth',2);

return


% --------------------------------------------------------------------
function PlotCOS_Callback(hObject, eventdata, handles)
% hObject    handle to PlotCOS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

file = (get(handles.condition_selector, 'String'));
file = file{get(handles.condition_selector, 'Value')};
var_cos = save_centroid(handles, handles.range_plotting(1):handles.range_plotting(2));

if get(handles.left_plateau, 'Value')
    var_cos = var_cos(2:end,4:7);
elseif get(handles.right_plateau, 'Value')
    var_cos = var_cos(2:end,8:11);
elseif get(handles.both_plateaus, 'Value')
    var_cos = var_cos(2:end,4:end);
end

for i = 1:size(var_cos,1)
    for j = 1:size(var_cos,2)
        var_cos1(i,j) = (var_cos{i,j});
    end
end
var_cos = var_cos1; clear var_cos1;
NumofCycle = round(size(var_cos,1)/(handles.Fs*2)); %cycle is 2s
var_cos_mean = zeros(handles.Fs*2,size(var_cos,2));
for i = 1:NumofCycle
    var_cos_mean = var_cos_mean + var_cos(1 + (i-1)*2*handles.Fs:i*2*handles.Fs, :);
end
var_cos_mean = var_cos_mean/NumofCycle;
var_cos_mean = convert100(var_cos_mean, 1:2*handles.Fs, 100);
plotting_cos(handles, var_cos_mean); %plot it out;
handles.var_cos_mean{get(handles.condition_selector, 'Value')} = var_cos_mean;
guidata(hObject, handles);
set(gcf,'name',[file '_CoS'],'numbertitle','off');
set(gcf,'units','normalized','position',[0.2 0.2 0.6 0.6]);


function plotting_cos(handles, var_cos_mean)
%==========================
%------------------plotting---------------------
linesize = 1.5;
mkrsize = 4;
xrange = 0:100;
toeoff = 58;
lines = {'b','-ob','g','r','m',...
    'b--','r--','g--','c--','m--',...
    'b.','r.','g.','c.','m.'}; %different line type for different variables
figure;
hold on;
if get(handles.left_plateau, 'Value')
    subplot(3,4,1), hold on;
    plot(xrange,var_cos_mean(:,1),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Perip  (mm)  Centr'); title('Medial compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,2), hold on;
    plot(xrange,var_cos_mean(:,3),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant   (mm)   Post'); title('Medial compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,3), hold on;
    plot(xrange,var_cos_mean(:,2),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Perip  (mm/s)  Centr'); title('Medial compartment ML velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,4), hold on;
    plot(xrange,var_cos_mean(:,4),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant  (mm/s)   Post'); title('Medial compartment AP velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
elseif get(handles.right_plateau, 'Value')
    subplot(3,4,5), hold on;
    plot(xrange,var_cos_mean(:,1),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Centr  (mm)   Perip'); title('Lateral compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,6), hold on;
    plot(xrange,var_cos_mean(:,3),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant   (mm)   Post'); title('Lateral compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,7), hold on;
    plot(xrange,var_cos_mean(:,2),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Centr  (mm/s)   Perip'); title('Lateral compartment ML velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,8), hold on;
    plot(xrange,var_cos_mean(:,4),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant  (mm/s)   Post'); title('Lateral compartment AP velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
elseif get(handles.both_plateaus, 'Value')
    subplot(3,4,1), hold on;
    plot(xrange,var_cos_mean(:,1),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Perip  (mm)  Centr'); title('Medial compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,2), hold on;
    plot(xrange,var_cos_mean(:,3),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant   (mm)   Post'); title('Medial compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,3), hold on;
    plot(xrange,var_cos_mean(:,2),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Perip  (mm/s)  Centr'); title('Medial compartment ML velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,4), hold on;
    plot(xrange,var_cos_mean(:,4),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant  (mm/s)   Post'); title('Medial compartment AP velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    
    subplot(3,4,5), hold on;
    plot(xrange,var_cos_mean(:,5),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Centr  (mm)   Perip'); title('Lateral compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,6), hold on;
    plot(xrange,var_cos_mean(:,7),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant   (mm)   Post'); title('Lateral compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,7), hold on;
    plot(xrange,var_cos_mean(:,6),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Centr  (mm/s)  Perip'); title('Lateral compartment ML velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,8), hold on;
    plot(xrange,var_cos_mean(:,8),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ant  (mm/s)   Post'); title('Lateral compartment AP velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);

    subplot(3,4,9), hold on;
    plot(xrange,var_cos_mean(:,9),lines{1},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ext   (Deg)    Int'); title('Femoral rotation'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
    subplot(3,4,11), hold on;
    plot(xrange,var_cos_mean(:,11),lines{2},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
    ylabel('Ext   (Deg/s)   Int'); title('Rotational velocity'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{4},'Linewidth',linesize);
end
%-----------plot the trajectories of CoS on the tibial plateau------------
set(handles.run, 'Enable', 'on');
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
selected_condition = get(handles.condition_selector, 'Value');
senselvar = handles.senselvar;
time_order = handles.time_order;
subplot(3,4,10), hold on;
%     if strcmp(get(handles.contour_on, 'Checked'), 'off')
%         curr_plot_handle = pcolor(gca, senselvar{selected_condition}(:,:,time_order{selected_condition}(index))); %creates a contour map of the current plateau with time
%     else
[~, ~] = contourf(gca, senselvar{selected_condition}(:,:,time_order{selected_condition}(index)),90, 'LineStyle', 'none'); %creates a contour map of the current plateau with time
%     end
%----------------------------------------------------------------------------------------------
%-----store the contour_map during the gait cycle for animation (synchronize with the plotting)
frames = handles.range_plotting(1):handles.range_plotting(2);
framenum_cycle = handles.Fs * handles.Tl;
NumofCycle = round(length(frames)/framenum_cycle); %cycle is 2s
clear contour_map;
for i = 1:101 % percentage of gait
    index = frames(1) + round(i/100.0*framenum_cycle);
    contour_map(:,:,i) = senselvar{selected_condition}(:,:,time_order{selected_condition}(index));
end
%----------END---------

if get(handles.both_plateaus, 'Value')
    plot(var_cos_mean(1:toeoff,1)/2,var_cos_mean(1:toeoff,3)/2,'o-m','linewidth',0.5, 'markersize',3,'markerfacecolor','m'); box on;
    plot(var_cos_mean(1:toeoff,5)/2,var_cos_mean(1:toeoff,7)/2,'o-m','linewidth',0.5, 'markersize',3,'markerfacecolor','m'); box on;
    plot(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,'o-k','linewidth',0.5, 'markersize',3,'markerfacecolor','k'); box on;
    plot(var_cos_mean(toeoff:end,5)/2,var_cos_mean(toeoff:end,7)/2,'o-k','linewidth',0.5, 'markersize',3,'markerfacecolor','k'); box on;
    plot(var_cos_mean(toeoff,1)/2,var_cos_mean(toeoff,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
    plot(var_cos_mean(toeoff,5)/2,var_cos_mean(toeoff,7)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
elseif get(handles.left_plateau, 'Value')
    plot(var_cos_mean(1:toeoff,1)/2,var_cos_mean(1:toeoff,3)/2,'o-m','linewidth',0.5, 'markersize',3,'markerfacecolor','m'); box on;
    plot(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,'o-k','linewidth',0.5, 'markersize',3,'markerfacecolor','k'); box on;
    plot(var_cos_mean(toeoff,1)/2,var_cos_mean(toeoff,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
else
    plot(var_cos_mean(1:toeoff,1)/2,var_cos_mean(1:toeoff,3)/2,'o-m','linewidth',0.5, 'markersize',3,'markerfacecolor','m'); box on;
    plot(var_cos_mean(toeoff:end,1)/2,var_cos_mean(toeoff:end,3)/2,'o-k','linewidth',0.5, 'markersize',3,'markerfacecolor','k'); box on;
    plot(var_cos_mean(toeoff,1)/2,var_cos_mean(toeoff,3)/2,'pk','linewidth',0.5, 'markersize',8,'markerfacecolor','w'); box on;
end
xlabel('Med   (No. sencell)    Lat'); ylabel('Ant   (No. sencell)    Pos'); title('Trajectory of stress center');
clear index selected_condition senselvar time_order
%----------Plot the inputs------------
gait_cycle = load([handles.Gpath handles.Gfile]);
gait_time = (linspace(0,handles.Tl,numel(gait_cycle.force)))';
sample_time = (linspace(handles.T, handles.Tl, 100))';
axial_force = spline(gait_time, gait_cycle.force, sample_time);
flexion = spline(gait_time, gait_cycle.flexion, sample_time);
AP_force = spline(gait_time, gait_cycle.AP, sample_time);
IE_torque = spline(gait_time, gait_cycle.torque, sample_time);
subplot(3,4,12), hold on;
[AX,H1,H2] = plotyy(1:100,[axial_force AP_force],1:100,IE_torque,'plot'); %double y-axis
set(get(AX(1),'Ylabel'),'String','Force (N)')
set(get(AX(2),'Ylabel'),'String','Torque (Nm)');
xlabel('Gait %');
title('Inputs(Axial force,AP force,IE torque)');
set(H1,'LineStyle','-','linewidth',2);
set(H2,'LineStyle',':','linewidth',2);
set(gcf,'units','normalized','position',[0.2 0.2 0.6 0.6]);

file = (get(handles.condition_selector, 'String'));
file = file{get(handles.condition_selector, 'Value')};
% save([file '_contourmap'],'contour_map');
return

function Plot_All_Trails_Callback(hObject, eventdata, handles)
% hObject    handle to Plot_All_Trails (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%===============================================
%#############Not working so far#################
xrange = 0:100;
num_of_trials = size(get(handles.condition_selector, 'String'),1);

choice = questdlg('Have you already plotted each trial seperately?', ...
    'Plotting all trials', ...
    'Yes','No','Yes');

% Handle response
switch choice
    case 'Yes'
        %do nothing
    case 'No'
        %plot the trials seperately, because the function need to use
        %handles.contact_map_stats2_mean, handles.contact_area2_mean and
        %handles.var_cos_mean
        %         rmfield(handles, {'contact_area2_mean', 'map_stats2_mean', 'var_cos_mean'});
        for ii = 1:num_of_trials
            set(handles.condition_selector,'Value',ii);
            guidata(hObject, handles);
            refresh_fig(hObject, handles);
            PlotCOS_Callback(hObject, eventdata, handles);
            PlotForceandArea_Callback(hObject, eventdata, handles);
        end
end
clear choice;
choice2 = questdlg('Do you want to do principal component analysis?', ...
    'PCA', ...
    'Yes','No','No');
switch choice2
    case 'Yes'
        for i = 1:num_of_trials
%             for j = 1:size(xrange,2)
                Var_collect(:,1:4,i) = handles.var_cos_mean{i}(:,[1 3 5 7]); %the first variable for i trial.
                Var_collect(:,5:6,i) = handles.map_stats2_mean{i}(:,[2 3]);
                Var_collect(:,7,i) = handles.map_stats2_mean{i}(:,9)/.100;
                Var_collect(:,8,i) = handles.contact_area2_mean{i}(:,2)./100;
%             end
        end
        disp('=====================');
        disp('Results of principal component analysis');
        [~,~]=SMaRT_v2(Var_collect(:,1:4,:),1:num_of_trials) %#ok<NOPRT>
        aa = 1;
    case 'No'
        %do nothing
end

% selected_condition = get(handles.condition_selector, 'Value');
lines = {'b','k','c','g','r',...
    'b--','k--','c--','g--','r--',...
    'b.','k.','c.','g.','r.'}; %different line type for different variables
mkrsize = 4;
linesize = 1.5;
toeoff = 58;
figure;
for ii = [1, 2, 3, 4] %1:num_of_trials
    var_cos_mean = handles.var_cos_mean{ii};
    map_stats2_mean = handles.map_stats2_mean{ii};
    contact_area2_mean = handles.contact_area2_mean{ii};

    if get(handles.left_plateau, 'Value')
        subplot(3,4,1), hold on;
        plot(xrange,var_cos_mean(:,1),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Perip  (mm)  Centr'); title('Medial compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,2), hold on;
        plot(xrange,var_cos_mean(:,3),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Ant   (mm)   Post'); title('Medial compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);

        subplot(3,4,5), hold on;
        plot(xrange,map_stats2_mean(:,2)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Mean Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,6), hold on;
        plot(xrange,map_stats2_mean(:,3)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Maximum Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,7), hold on;
        plot(xrange,map_stats2_mean(:,9),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Force (N)'); title('Total Force'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,8), hold on;
        plot(xrange,contact_area2_mean(:,2),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Area (mm^2)'); title('Contact Area'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
    elseif get(handles.right_plateau, 'Value')
        subplot(3,4,1), hold on;
        plot(xrange,var_cos_mean(:,1),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Centr  (mm)  Perip'); title('Lateral compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,2), hold on;
        plot(xrange,var_cos_mean(:,3),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Ant   (mm)   Post'); title('Lateral compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);

        subplot(3,4,5), hold on;
        plot(xrange,map_stats2_mean(:,2)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Mean Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,6), hold on;
        plot(xrange,map_stats2_mean(:,3)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Maximum Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,7), hold on;
        plot(xrange,map_stats2_mean(:,9),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Force (N)'); title('Total Force'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,8), hold on;
        plot(xrange,contact_area2_mean(:,2),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Area (mm^2)'); title('Contact Area'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
    elseif get(handles.both_plateaus, 'Value')
        subplot(3,4,1), hold on;
        h(:,ii) = plot(xrange,var_cos_mean(:,1),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Perip  (mm)  Centr'); title('Medial compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,2), hold on;
        plot(xrange,var_cos_mean(:,3),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Ant   (mm)   Post'); title('Medial compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        
        subplot(3,4,3), hold on;
        plot(xrange,var_cos_mean(:,5),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Centr  (mm)  Perip'); title('Lateral compartment ML'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,4), hold on;
        plot(xrange,var_cos_mean(:,7),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Ant   (mm)   Post'); title('Lateral compartment AP'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        
        subplot(3,4,5), hold on;
        plot(xrange,map_stats2_mean(:,2)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Mean Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,6), hold on;
        plot(xrange,map_stats2_mean(:,3)/4,lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Pressure (MPa)'); title('Maximum Pressure'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,7), hold on;
        plot(xrange,map_stats2_mean(:,9),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Force (N)'); title('Total Force'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
        subplot(3,4,8), hold on;
        plot(xrange,contact_area2_mean(:,2),lines{ii},'linewidth',linesize, 'markersize',mkrsize); box on; grid on;
        ylabel('Area (mm^2)'); title('Contact Area'); xlabel('Gait %'); xLimits = get(gca,'YLim'); plot([toeoff, toeoff],[xLimits(1) xLimits(2)],lines{5},'Linewidth',linesize);
    end
end
legend(h(1,:),get(handles.condition_selector, 'String'));
set(gcf,'name','All trials together','numbertitle','off');
set(gcf,'units','normalized','position',[0.2 0.2 0.6 0.6]);
aa = 1;


function deriv = fivepointderiv(inparam, freq)
%This function calculates the 5 point derivative of any parameter.
% INPUTS
% freq    - frames/sec
% inparam - any input parameter whose derivative is required. Array with
%           columns  = n-co-ords and rows = number of frames
% OUTPUT
% deriv   - 5 point derivative of inparam. Array with columns = n co-ords
%           and rows = number of frames as in inparam.
%           unit(deriv) = unit(inparam)/sec
len = size(inparam, 1); %get # of frame

%derivative at frames 1 & 2
deriv(1,:)=(-inparam(3,:)+4*inparam(2,:)-3*inparam(1,:))*freq/2;
deriv(2,:)=deriv(1,:);

%for all the frame in between
for i=3:(len-2)
    deriv(i,:)=(-inparam(i+2,:)+8*inparam(i+1,:)-8*inparam(i-1,:)+inparam(i-2,:))*freq/12;
end

%derivative at last 2 frames
deriv(len,:)=(inparam(len-2,:)-4*inparam(len-1,:)+3*inparam(len,:))*freq/2;
deriv(len-1,:)=deriv(len,:);
%12 comes from -(2)+8(1)-8(-1)+(-2)=12
return

function [p, t]=convert100(y, x, num_t)
% interpolate the vector with more data points. 
x_interval = (x(length(x))-x(1))/num_t;
x1=x(1):x_interval:x(length(x));
t_interval = 100/num_t;
t = 0:t_interval:100;
p = interp1(x,y,x1);

% example:
% x = 0:10; 
% y = sin(x); 
% xi = 0:.25:10; 
% yi = interp1(x,y,xi); 
% plot(x,y,'o',xi,yi,'--')


% --- Executes on button press in AlignMedialFnc.
function AlignMedialFnc_Callback(hObject, eventdata, handles)
% hObject    handle to AlignMedialFnc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;
%framenum = handles.tekvar{selected_condition}.header.end_frame;
framenum = size(handles.senselvar{1,selected_condition},3);

prompt = {'Enter x (left(-)-right(+)):','Enter y (up(-)-down(+)):'};
dlg_title = 'Input for cartilage-on-cartilage center of medial (left) compartment';
num_lines = 1;
def = {'0','0'}; %default shift values
answer = inputdlg(prompt,dlg_title,num_lines,def);
x_adjust = round(str2num(answer{1}));
y_adjust = round(str2num(answer{2}));
tekscan_outline = handles.tekvar{selected_condition}.data_a.sensel(:,:,1);
tekscan_outline(~isnan(tekscan_outline)) = 0;

for i = 1:framenum  
    if y_adjust < 0
        newpcolor = [handles.senselvar{1,selected_condition}(1-y_adjust:rows, 1:15, i); zeros(abs(y_adjust), 15)];
    elseif y_adjust > 0
        newpcolor = [zeros(abs(y_adjust), 15); handles.senselvar{1,selected_condition}(1:rows-y_adjust, 1:15, i)];
    else
        newpcolor = handles.senselvar{1,selected_condition}(1:rows, 1:15, i);
    end
    
    if x_adjust < 0
        newpcolor = [newpcolor(1:rows, 1-x_adjust:15) zeros(rows, abs(x_adjust))];
    elseif x_adjust > 0
        newpcolor = [zeros(rows, abs(x_adjust)) newpcolor(1:rows, 1:15-x_adjust)];
    end
%     newpcolor = circshift(handles.senselvar{1,selected_condition}(1:rows,1:13,i), [y_adjust,x_adjust]);
    newpcolor = newpcolor + tekscan_outline(1:rows,1:15);
    
    newpcolor(isnan(newpcolor)) = 0;
    newpcolor = newpcolor + tekscan_outline(1:rows,1:15);
    handles.senselvar{1,selected_condition}(1:rows,1:15,i) = newpcolor;
    handles.tekvar{1,selected_condition}.data_a.sensel(1:rows,1:15,i) = newpcolor;
    for irow = 1:rows
        for icol = 1:15
            handles.sensels{1,selected_condition}{irow,icol}(1,1,i) = newpcolor(irow,icol);
        end
    end
end
guidata(hObject, handles);
refresh_fig(hObject, handles);


%         [Right_I Right_J] = centroid_location(abs(handles.curr_plot(1:rows,(cols-round(cols/2)):cols)), str2num(get(handles.noise_floor_edit, 'String')), false);


% --- Executes on button press in AlignLateralFnc.
function AlignLateralFnc_Callback(hObject, eventdata, handles)
% hObject    handle to AlignLateralFnc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% hObject    handle to AlignMedialFnc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;
%framenum = handles.tekvar{selected_condition}.header.end_frame;
framenum = size(handles.senselvar{1,selected_condition},3);

prompt = {'Enter x (left(-)-right(+)):','Enter y (up(-)-down(+)):'};
dlg_title = 'Input for cartilage-on-cartilage center of lateral (right) compartment';
num_lines = 1;
def = {'0','0'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
x_adjust = round(str2num(answer{1}));
y_adjust = round(str2num(answer{2}));
tekscan_outline = handles.tekvar{selected_condition}.data_a.sensel(:,:,1);
tekscan_outline(~isnan(tekscan_outline)) = 0;

for i = 1:framenum
    if y_adjust < 0
        newpcolor = [handles.senselvar{1,selected_condition}(1-y_adjust:rows, 23:cols, i); zeros(abs(y_adjust), cols-23+1)];
    elseif y_adjust > 0
        newpcolor = [zeros(abs(y_adjust), cols-23+1); handles.senselvar{1,selected_condition}(1:rows-y_adjust, 23:cols, i)];
    else
        newpcolor = handles.senselvar{1,selected_condition}(1:rows, 23:cols, i);
    end
    
    if x_adjust < 0
        newpcolor = [newpcolor(1:rows, 1-x_adjust:end) zeros(rows, abs(x_adjust))];
    elseif x_adjust > 0
        newpcolor = [zeros(rows, abs(x_adjust)) newpcolor(1:rows, 1:end-x_adjust)];
    end
%     newpcolor = circshift(handles.senselvar{1,selected_condition}(1:rows,23:cols,i), [y_adjust,x_adjust]);
    newpcolor = newpcolor + tekscan_outline(1:rows,23:cols);
    
    newpcolor(isnan(newpcolor)) = 0;
    newpcolor = newpcolor + tekscan_outline(1:rows,23:cols);
    handles.senselvar{1,selected_condition}(1:rows,23:cols,i) = newpcolor;
    handles.tekvar{1,selected_condition}.data_a.sensel(1:rows,23:cols,i) = newpcolor;
    for irow = 1:rows
       for icol = 23:cols
           handles.sensels{1,selected_condition}{irow,icol}(1,1,i) = newpcolor(irow,icol-22);
       end
    end
end
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function save_mapvalues_Callback(hObject, eventdata, handles)
% hObject    handle to save_mapvalues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.mat','Matlab File(*.mat)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Current Stress Map', handles.path);

if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);

    index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider

    selected_condition = get(handles.condition_selector, 'Value');

    if strcmp(get(handles.avg_data, 'Checked'), 'on')
        senselvar = handles.avg_senselvar;
        time_order = handles.avg_time_order;
    else
        senselvar = handles.senselvar;
        time_order = handles.time_order;
    end
    
    map_values = senselvar{selected_condition}(:,:,time_order{selected_condition}(index));
    row_spacing = handles.tekvar{selected_condition}.header.row_spacing;
    col_spacing = handles.tekvar{selected_condition}.header.col_spacing;
    sensor_type = handles.tekvar{selected_condition}.header.sensor_type;
    
    save([pathfile file], 'map_values', 'row_spacing', 'col_spacing', 'sensor_type');
end


% --------------------------------------------------------------------
function polygon_edit_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
locs = rem(index,handles.window_size);
if locs == 0
    locs = handles.window_size;
end

origi_size = size(handles.roibnd{1,locs}(1:end-1,:));
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

axes(handles.pressure_map);
h = impoly(gca, handles.roibnd{1,locs}(1:end-1,:)); %#ok<*IMPOLY>
position = wait(h);
setColor(h,'r');

if (size(position,1)<origi_size(1) && length(find(~ismember(handles.roibnd{1,locs}(1:end-1,:), position, 'rows')))==(origi_size(1)-size(position,1)))
    choice = questdlg('Remove same points in all frames?', ...
        'Remove Points:', ...
        'Yes','No','No');
    
    switch choice
        case 'Yes'
            for fl = 1:size(handles.roibnd,2)
                handles.roibnd{1,fl} = handles.roibnd{1,fl}(ismember(handles.roibnd{1,locs}(1:end-1,:), position, 'rows'),:);
                handles.roibnd{1,fl} = [handles.roibnd{1,fl}; handles.roibnd{1,fl}(1,:)];
            end   
    end
elseif (size(position,1)>origi_size(1) && length(find(~ismember(position, handles.roibnd{1,locs}(1:end-1,:), 'rows')))==(size(position,1)-origi_size(1)))
    choice = questdlg('Add same point in all frames?', ...
        'Add Points:', ...
        'Yes', 'No', 'No');
    
    switch choice
        case 'Yes'
            found_locs = find(~ismember(position, handles.roibnd{1,locs}(1:end-1,:), 'rows'));
            for fl = 1:size(handles.roibnd,2)
                handles.roibnd{1,fl} = handles.roibnd{1,fl}(1:end-1,:);
                for add_loc = length(found_locs):-1:1
                    handles.roibnd{1,fl}(add_loc+1:end+1,:) = handles.roibnd{1,fl}(add_loc:end,:);
                    handles.roibnd{1,fl}(add_loc,:) = position(add_loc,:);
                    handles.roibnd{1,fl} = [handles.roibnd{1,fl}; handles.roibnd{1, fl}(1,:)];
                end
            end
    end
else
    handles.roibnd{1,locs} = [position; position(1,:)];
end

handles = calc_in(hObject, handles);
guidata(hObject, handles)
refresh_fig(hObject, handles)

% --------------------------------------------------------------------
function polygon_remove_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear handles.in handles.roibnd
handles.curr_select_flag = 0;

guidata(hObject, handles)
refresh_fig(hObject, handles)

% --------------------------------------------------------------------
function polygon_open_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uigetfile(...
    {'*.roi',  'All Files(*.*)'}, ...
    'Base Filename', handles.path);

load([pathfile file], '-mat'); %#ok<*LOAD>
handles.curr_select_flag = 1;

if ~exist('inon', 'var')
    handles.inon = true;
else
    handles.inon = inon;
end

selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

handles.roibnd = save_polygon;

handles = calc_in(hObject, handles);

index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
locs = rem(index,handles.window_size);
if locs == 0
    locs = handles.window_size;
end

guidata(hObject, handles)
refresh_fig(hObject, handles)

% --------------------------------------------------------------------
function polygon_save_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, pathfile]=uiputfile(...
    {'*.roi',  'All Files(*.*)'}, ...
    'Base Filename', handles.path);

if ~isequal(file,0) && handles.curr_select_flag == 1
    handles.path = pathfile;
    guidata(hObject, handles);
        
    save_polygon = handles.roibnd;
    inon = handles.inon;
    
    save([pathfile file], 'save_polygon', 'inon', '-mat');
end

% --------------------------------------------------------------------
function polygon_copy_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_copy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function polygon_fcopy_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_fcopy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
locs = rem(index,handles.window_size);
if locs == 0
    locs = handles.window_size;
end

selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

axes(handles.pressure_map);
if locs+1 <= handles.window_size
    replace_loc = locs+1;
else
    replace_loc = 1;
end

handles.roibnd{1,replace_loc} = handles.roibnd{1,locs};

y = linspace(1,rows,rows); x = linspace(1,cols,cols);
[X, Y] = meshgrid(x,y); clear x y
handles.in(:,:,replace_loc) = inpolygon(X,Y,handles.roibnd{1,locs}(:,1),handles.roibnd{1,locs}(:,2));

for irow = 1:rows
    for icol = 1:cols
        if handles.in(irow,icol,replace_loc) == 1
            handles.curr_select(irow,icol) = handles.curr_plot(irow,icol);
        else
            handles.curr_select(irow,icol) = NaN;
        end
    end
end

if index+1 <= handles.length_time
    set(handles.pressure_map_slider, 'Value', index+1); %sets the current value of the slider forward 1
end

guidata(hObject, handles)
refresh_fig(hObject, handles)


% --------------------------------------------------------------------
function polygon_rcopy_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_rcopy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
locs = rem(index,handles.window_size);
if locs == 0
    locs = handles.window_size;
end

selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

axes(handles.pressure_map);
if locs-1 >= 1
    replace_loc = locs-1;
else
    replace_loc = handles.window_size;
end

handles.roibnd{1,replace_loc} = handles.roibnd{1,locs};

y = linspace(1,rows,rows); x = linspace(1,cols,cols);
[X, Y] = meshgrid(x,y); clear x y
handles.in(:,:,replace_loc) = inpolygon(X,Y,handles.roibnd{1,locs}(:,1),handles.roibnd{1,locs}(:,2));

for irow = 1:rows
    for icol = 1:cols
        if handles.in(irow,icol,replace_loc) == 1
            handles.curr_select(irow,icol) = handles.curr_plot(irow,icol);
        else
            handles.curr_select(irow,icol) = NaN;
        end
    end
end

if index-1 >= 0
    set(handles.pressure_map_slider, 'Value', index-1); %sets the current value of the slider backward 1
end

guidata(hObject, handles)
refresh_fig(hObject, handles)


% --------------------------------------------------------------------
function polygon_all_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
locs = rem(index,handles.window_size);
if locs == 0
    locs = handles.window_size;
end

selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

axes(handles.pressure_map);
for replace_loc = 1:handles.window_size
    handles.roibnd{1,replace_loc} = handles.roibnd{1,locs};
    y = linspace(1,rows,rows); x = linspace(1,cols,cols);
    [X, Y] = meshgrid(x,y); clear x y
    handles.in(:,:,replace_loc) = inpolygon(X,Y,handles.roibnd{1,locs}(:,1),handles.roibnd{1,locs}(:,2));
end

guidata(hObject, handles)
refresh_fig(hObject, handles)


% --------------------------------------------------------------------
function surf_on_Callback(hObject, eventdata, handles)
% hObject    handle to surf_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off')
else
    set(hObject, 'Checked', 'on')
    set(handles.contour_on, 'Checked', 'off')
end

guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function save_mat_Callback(hObject, eventdata, handles)
% hObject    handle to save_mat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% re-export takscan pressure map as .MAT file.
% can either export whole map or just ROI

[file, pathfile]=uiputfile(...
    {'*.mat','MAT File(*.mat)';...
    '*.*',  'All Files(*.*)'}, ...
    'Save Pressure Map MAT', handles.path);

    
%ensures 'Cancel' wasn't pressed and then save movie for the tekscan file
%currently selected
if ~isequal(file,0)
    handles.path = pathfile;
    guidata(hObject, handles);
    
    selected_condition = get(handles.condition_selector, 'Value');
    
    %get raw data to export as MAT
    header = handles.tekvar{selected_condition}.header;
    data_a = handles.tekvar{selected_condition}.data_a;
    time_order = handles.time_order{selected_condition};
    
    % check if an ROI is present
    if handles.curr_select_flag == 1
        % setup index for ROI repeat
        for w = 1:handles.window_size
            loc_ind(w) = w;
        end
        loc_ind = [handles.window_size loc_ind]; %make first value the same as last (rem = 0)
        
        for w = 1:size(data_a.sensel,3)
            data_a.sensel(:,:,w) = data_a.sensel(:,:,time_order(w)) .* handles.in(:,:,loc_ind(rem(w,handles.window_size)+1));
        end
    end   

    save([pathfile file], 'header', 'data_a');
end


% --------------------------------------------------------------------
function polygon_selection_auto_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_selection_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % handles.curr_select_flag = 1;

global peak sigma_x sigma_y a_x a_y start gauss_img; %#ok<NUSED>

handles.curr_select_flag = 1;
handles.inon = true;

B = 1/159*[2 4 5 4 2; 4 9 12 9 4; 5 12 15 12 5; 4 9 12 9 4; 2 4 5 4 2];

%initalization
selected_condition = get(handles.condition_selector, 'Value');
rows = handles.tekvar{selected_condition}.header.rows;
cols = handles.tekvar{selected_condition}.header.cols;

index = round(get(handles.pressure_map_slider, 'Value')); %gets the current frame
%selects ROI, stores vertices of polygon in handles.roibnd, creates binary
%map (in) of frame with the ROI in ones and everything else in zeros
handles.roibnd = {};
axes(handles.pressure_map);
h = impoly(gca); 
position = wait(h);
setColor(h,'r');
handles.roibnd{1, 1} = [position; position(1,:)];
y = linspace(1,rows,rows); x = linspace(1,cols,cols);
[X, Y] = meshgrid(x,y); clear x y
in = inpolygon(X,Y,handles.roibnd{1,1}(:,1),handles.roibnd{1,1}(:,2));

%Gaussian Constants
sigma_x = 8;
sigma_y = 8;

%uses activecontour (snake algorithm) to seperate foreground from
%background using a Chan-Vese region-based energy model. The peak and it's
%location within the foreground (snake) is then stored. 
for leng = index:index+handles.window_size
    locs = rem(leng,handles.window_size)+1;
    curr_img=handles.tekvar{1,1}.data_a.sensel(:,:,handles.time_order{selected_condition}(leng));
    curr_img(isnan(curr_img)) = 0;
    ROI=curr_img.*in;
    snake=activecontour(ROI,in); 
    peak = max(max(ROI.*snake));
    [Y_loc, X_loc]=ind2sub(size(ROI.*snake),find((ROI.*snake)==peak));         %#ok<*SZARLOG>
%a convolusion is performed to find the Gaussian curve
    gauss_img = conv2(curr_img, B, 'same'); 
    gauss_img = gauss_img.*snake;
    a_x = X_loc(1)-6;
    a_y = Y_loc(1)-8;

% minimizes SSE by changing sigma_x, sigma_y
    z = fminsearch('poisson_eq2',[sigma_x sigma_y]);

    gauss_val = zeros(rows,cols);

    for kx = 1:cols
        for ky = 1:rows
            if (kx-a_x) <= 0 || (ky-a_y) <= 0
                gauss_val(ky,kx) = 0;
            else
                gauss_val(ky,kx) = peak*((sigma_x)^(kx-a_x)*exp(-1*sigma_x)/factorial(abs(round(kx-a_x))))*((sigma_y)^(ky-a_y)*exp(-1*sigma_y)/factorial(abs(round(ky-a_y))));
            end
        end
    end

    cc_region = zeros(size(gauss_val));
    cc_region(gauss_val>=max(max(gauss_val))*0.25) = 1; %anything above 25% of max is set as the cartilage-cartilage region
    
    handles.roibnd{1, locs} = cell2mat(bwboundaries(cc_region)); %saves vertices of ROI for every frame in a gait cycle
    handles.roibnd{1, locs} = [handles.roibnd{1, locs}(:,2) handles.roibnd{1, locs}(:,1)];
end

handles = calc_in(hObject, handles);
guidata(hObject, handles)
refresh_fig(hObject, handles)


% --------------------------------------------------------------------
function STAPLE_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to STAPLE_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fle, pth] = uigetfile('*.ROI', 'MultiSelect', 'on', handles.path);

% check if a file was selected
if ~isequal(fle,0)
    handles.path = pth;
    guidata(hObject, handles);
    
    % get current selected condition and size of the Tekscan map
    selected_condition = get(handles.condition_selector, 'Value');
    rows = handles.tekvar{selected_condition}.header.rows;
    cols = handles.tekvar{selected_condition}.header.cols;

    %number of files loaded
    num_files = numel(fle);

    % load all selected files
    for w = 1:num_files
        t{w} = load([pth fle{w}], '-mat');
    end
    
    % number of frames per ROI (assumes all ROIs have same number of
    % frames)
    window_size = numel(t{1}.save_polygon);
    var=handles.tekvar{selected_condition}.data_a.sensel(:,:,handles.time_order{selected_condition});
    win_var = var(:,:,window_size+1:window_size*2);

    % initialize cell array to the size of a cycle
    in = cell(window_size,1);
   
    % convert ROI to binary image map
    for w = 1:num_files
        for leng = 1:window_size
            
            % find all points with ROI
            y = linspace(1,rows,rows); x = linspace(1,cols,cols);
            [X, Y] = meshgrid(x,y); clear x y
            
            %check if imported ROIs should be rounded before generating
            %STAPLE ROI
            if strcmp(get(handles.round_ROI, 'Checked'), 'on')
                t{w}.in(:,:,leng) = inpolygon(X,Y,round(t{w}.save_polygon{leng}(:,1)),round(t{w}.save_polygon{leng}(:,2)));
            else
                t{w}.in(:,:,leng) = inpolygon(X,Y,t{w}.save_polygon{leng}(:,1),t{w}.save_polygon{leng}(:,2));
            end
            
            % get sensels in ROI for current frame
            curr_in = t{w}.in(:,:,leng);
            
            % reorganize matrix for input into STAPLE function
            in{leng} = [in{leng} curr_in(:)];
        end
    end

    %% staple
    %gets the dimensions of 1 frame
    imageDims=size(curr_in);
    
    %concatenates each frame for each loaded ROI and gets the staple ROI
    %for each frame
    for leng = 1:window_size        
        [W, ~, ~] = STAPLE(in{leng}); % calculate STAPLE ROI
        handles.in(:,:,leng) = reshape((W >= .5), imageDims); % reorganizes STAPLE output back into sensor map
        ROIS = cell2mat(bwboundaries(handles.in(:,:,leng))); % takes STAPLE calculated region and turns into boundary points
        
        % make sure that there are points to store
        if ~isempty(ROIS)
            handles.roibnd{1,leng} = [ROIS(:,2) ROIS(:,1)];
        else
            handles.roibnd{1,leng} = [0 0];
        end
    end
    
    % set flag for ROI enabled and refreshes the GUI
    handles.curr_select_flag = 1;
    
    if ~isfield(t{1}, 'inon')
        handles.inon = true;
    else
        handles.inon = t{1}.inon; % assume the same for all drawn ROIs
    end
    guidata(hObject, handles);
    refresh_fig(hObject, handles)
end


% --------------------------------------------------------------------
function round_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to round_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
else
    set(hObject, 'Checked', 'on');
end

handles = calc_in(hObject, handles);
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
else
    set(hObject, 'Checked', 'on');
end

guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function show_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to show_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
else
    set(hObject, 'Checked', 'on');
end

guidata(hObject, handles);
refresh_fig(hObject, handles);



function ncc_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to ncc_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ncc_thresh as text
%        str2double(get(hObject,'String')) returns contents of ncc_thresh as a double


% --- Executes during object creation, after setting all properties.
function ncc_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ncc_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function polygon_invert_Callback(hObject, eventdata, handles)
% hObject    handle to polygon_invert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.curr_select_flag == 1
    choice = questdlg('Keep enclosed shape?', ...
        'Enclosed Shape', ...
        'Yes', 'No', 'No');
    
    if strcmpi(choice, 'yes')
        for leng = 1:length(handles.roibnd)
            new_roi = [0, 0; 0, handles.tekvar{1}.header.rows; handles.tekvar{1}.header.cols, handles.tekvar{1}.header.rows; handles.tekvar{1}.header.cols, 0; 0, 0; NaN, NaN; handles.roibnd{leng}];
            handles.roibnd{leng} = new_roi;
        end
    else
        choice = questdlg('Close ROI on:', ...
            'Invert ROI', ...
            'Left','Right','Right');
        
        if strcmpi(choice, 'left')
            for leng = 1:length(handles.roibnd)
                roi_rows = length(handles.roibnd{leng});
                [top_x, top_y, top_ind] = getClosestPoint([min(handles.roibnd{leng}(:,1)), max(handles.roibnd{leng}(:,2))], handles.roibnd{leng}(1:end-1,:));
                [bot_x, ~, bot_ind] = getClosestPoint(min(handles.roibnd{leng}), handles.roibnd{leng}(1:end-1,:));
                
                new_roi = [top_x, top_y];
                new_roi = [new_roi; top_x, handles.tekvar{1}.header.rows];
                new_roi = [new_roi; handles.tekvar{1}.header.cols, handles.tekvar{1}.header.rows];
                new_roi = [new_roi; handles.tekvar{1}.header.cols, 0];
                new_roi = [new_roi; bot_x, 0];
                if top_ind > bot_ind
                    if bot_ind == 1
                        inds = 1:top_ind;
                    else
                        inds = [bot_ind:-1:1, roi_rows-1:-1:top_ind];
                    end
                else
                    if top_ind == 1
                        inds = bot_ind:-1:1;
                    else
                        inds = [bot_ind:roi_rows-1, 1:top_ind];
                    end
                end
                
                new_roi = [new_roi; handles.roibnd{leng}(inds,:)];
                handles.roibnd{leng} = new_roi;
            end
        else
            for leng = 1:length(handles.roibnd)
                roi_rows = length(handles.roibnd{leng});
                [top_x, top_y, top_ind] = getClosestPoint(max(handles.roibnd{leng}), handles.roibnd{leng}(1:end-1,:));
                [bot_x, ~, bot_ind] = getClosestPoint([max(handles.roibnd{leng}(:,1)), min(handles.roibnd{leng}(:,2))], handles.roibnd{leng}(1:end-1,:));
                
                new_roi = [top_x, top_y];
                new_roi = [new_roi; top_x, handles.tekvar{1}.header.rows];
                new_roi = [new_roi; 0, handles.tekvar{1}.header.rows];
                new_roi = [new_roi; 0, 0];
                new_roi = [new_roi; bot_x, 0];
                if top_ind > bot_ind
                    if bot_ind == 1
                        inds = 1:top_ind;
                    else
                        inds = [bot_ind:-1:1, roi_rows-1:-1:top_ind];
                    end
                else
                    if top_ind == 1
                        inds = bot_ind:-1:1;
                    else
                        inds = [bot_ind:roi_rows-1, 1:top_ind];
                    end
                end
                
                new_roi = [new_roi; handles.roibnd{leng}(inds,:)];
                handles.roibnd{leng} = new_roi;
            end
        end
    end
    
    handles.inon = false;
    handles = calc_in(hObject, handles);
    handles.curr_select_flag = 1;
    guidata(hObject, handles);
    refresh_fig(hObject, handles)
end


% --------------------------------------------------------------------
function highlight_Color_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function highlight_Yellow_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Yellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'on');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.65;
guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function highlight_Orange_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Orange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'on');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.75;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Cyan_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Cyan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'on');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.4;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Red_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Red (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'on');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.8;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Green_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Green (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'on');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.5;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Blue_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Blue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'on');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.2;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Purple_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Purple (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'on');
set(handles.highlight_Black, 'Checked', 'off');

handles.highlight = 0.1;
guidata(hObject, handles);
refresh_fig(hObject, handles);

% --------------------------------------------------------------------
function highlight_Black_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_Black (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.highlight_Yellow, 'Checked', 'off');
set(handles.highlight_Orange, 'Checked', 'off');
set(handles.highlight_Cyan, 'Checked', 'off');
set(handles.highlight_Red, 'Checked', 'off');
set(handles.highlight_Green, 'Checked', 'off');
set(handles.highlight_Blue, 'Checked', 'off');
set(handles.highlight_Purple, 'Checked', 'off');
set(handles.highlight_Black, 'Checked', 'on');

handles.highlight = 0;
guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function ROI_Callback(hObject, eventdata, handles)
% hObject    handle to ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function highlight_transp_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_transp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

num = 'a';

while ~isnumeric(num)
    num = inputdlg('Input transparency level [0..1]:');
    num = str2num(num{1});
end

handles.h_transp = num;
guidata(hObject, handles);
refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function magDiv_risk_Callback(hObject, eventdata, handles)
% hObject    handle to magDiv_risk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.time_reg_auto
    [handles.time_order, handles.time_shift_by] = time_registration(hObject, handles, false);
    handles.time_reg_auto = true;
    guidata(hObject, handles);
end
handles.total_magnitude_risk = magnitude_risk(handles, 'div');
handles.magnitude_risk = handles.total_magnitude_risk;
forComp = cell2mat(handles.magnitude_risk);
handles.min_mag_crange = min(min(min(forComp(~isinf(forComp)))));
handles.max_mag_crange = max(max(max(forComp(~isinf(forComp)))));
handles.mag_calced = 1;

set(handles.risk_map_checkbox, 'Visible', 'on');
set(handles.mag_diff_scale, 'Enable', 'on')
set(handles.risk_type_dropdown, 'Visible', 'off');
set(handles.risk_map_checkbox, 'Value', false);

guidata(hObject,handles);


% --------------------------------------------------------------------
function maxmin_map_Callback(hObject, eventdata, handles)
% hObject    handle to maxmin_map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index = round(get(handles.pressure_map_slider, 'Value')); %gets the current value of the slider
selected_condition = get(handles.condition_selector, 'Value');

if strcmp(get(handles.avg_data, 'Checked'), 'on')
    senselvar = handles.avg_senselvar;
    time_order = handles.avg_time_order;
    force = handles.avg_force;
    time = handles.avg_time;
    if  handles.mag_calced
        magnitude_risk = handles.avg_magnitude_risk;
    end
else
    senselvar = handles.senselvar;
    time_order = handles.time_order;
    force = handles.force{selected_condition};
    time = handles.tekvar{selected_condition}.data_a.time;
    if  handles.mag_calced
        magnitude_risk = handles.magnitude_risk;
    end
end

if handles.curr_select_flag == 1
    loc = rem(index,handles.window_size);
    if loc == 0
        loc = handles.window_size;
    end
    curr_select = senselvar{selected_condition}*NaN;
    curr_select(handles.in(:,:,:) == 1) = senselvar{selected_condition}(handles.in(:,:,:) == 1);
else
    curr_select = senselvar{selected_condition};
end

max_map = max(curr_select,[],3);

fig = figure;
if strcmp(get(handles.surf_on, 'Checked'), 'on')
    curr_plot_handle = surf(max_map); %creates a contour map of the current plateau with time
    view(2);
elseif strcmp(get(handles.contour_on, 'Checked'), 'off')
    curr_plot_handle = pcolor(max_map); %creates a map of the current plateau with time
    curr_plot_handle.LineStyle = 'none';
else
    [~, curr_plot_handle] = contourf(max_map,90, 'LineStyle', 'none'); %#ok<ASGLU> %creates a interpolated contour map of the current plateau with time
end

%% Figure formatting
set(fig.Children,'XTick', 0:2:(handles.tekvar{selected_condition}.header.cols+1))
set(fig.Children,'YTick', 0:2:(handles.tekvar{selected_condition}.header.rows+1))
xlim(fig.Children,[0 handles.tekvar{selected_condition}.header.cols+1]);
ylim(fig.Children,[0 handles.tekvar{selected_condition}.header.rows+1]);
set(fig.Children,'YDir', 'reverse');
title(['Max Stress [MPa]: ' num2str(max(max(max_map)))]);
cmap = colormap(jet(255));
cmap = [0 0 0; cmap];
colormap(cmap);
caxis([handles.min_crange handles.max_crange]);
grid('off')
axis off

% --------------------------------------------------------------------
function com_pat_Callback(hObject, eventdata, handles)
% hObject    handle to com_pat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function roi_training_Callback(hObject, eventdata, handles)
% hObject    handle to roi_training (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Opens Gui to select expert ROI

if strcmpi(get(hObject, 'Checked'), 'on') % if training module item is checked uncheck
    set(hObject, 'Checked', 'off');
    set(handles.senspec_popupmenu, 'Visible', 'Off');
    set(handles.stats04, 'String', '');
    set(handles.senspec_save, 'Enable', 'Off');
else   
    %%Initialize Variables
    selected_condition = get(handles.condition_selector, 'Value'); % get current selected tekscan map
    window_size = handles.window_size;
    rows = handles.tekvar{selected_condition}.header.rows;
    cols = handles.tekvar{selected_condition}.header.cols;
    
    if strcmp(get(handles.avg_data, 'Checked'), 'on') % Use average data
        senselvar = handles.avg_senselvar;
        time_order = handles.avg_time_order;
        time = handles.avg_time;
    else % Use all cycle data
        senselvar = handles.senselvar;
        time_order = handles.time_order;
        time = handles.tekvar{selected_condition}.data_a.time;
    end
    
    %% Begin Sensitivity/Specificity Analysis
    % load expert ROI, should be a single ROI file
    [expert_file, path]=uigetfile(...
        {'*.roi', 'ROI data';...
        '*.*',  'All Files'}, ...
        'Load Expert ROI');
    
    handles.path = path;
    guidata(hObject, handles);
    
    % Code to open and parse selected Tekscan file
    if ~isequal(expert_file,0) % checks that cancel isn't pressed for expert ROI

        handles.curr_select_flag = 0;
        set(hObject, 'Checked', 'on');
        
        load(fullfile(path,expert_file), '-mat');
        handles.exproibnd = save_polygon;

        if ~exist('inon', 'var') % older ROI saves do not contain this variable if it is not there default to true
            handles.inon = true;
        else
            handles.inon = inon;
        end
        
        handles.expin = training_calc_in(hObject, handles, handles.exproibnd);

        % set expert matrix
        num_windows = length(time)/handles.window_size;
        expin = repmat(handles.expin,1,1,num_windows);
        curr_select = senselvar{selected_condition}.*NaN;
        expoverlay = curr_select;
        expoverlay(expin == 1 & senselvar{selected_condition}(:,:,time_order{selected_condition})>0) = 0.3;

        % Expert positive and negatives
        t = senselvar{selected_condition}(:,:,time_order{selected_condition});
        t(~isnan(t) & t>0) = -1;
        t(t==0) = NaN;
        t(expoverlay>0) = 1;
        
        % load trainee ROIs
        [trainee_files, path]=uigetfile(...
            {'*.roi', 'ROI data';...
            '*.*',  'All Files'},  ...
            'Load Expert ROI', ...
            'MultiSelect', 'on');
        
        if ~isequal(trainee_files,0) % checks that cancel isn't pressed for trainee ROI
            if iscell(trainee_files)
                files2Comp = cell(numel(trainee_files));
                handles.trainroibnd = cell(numel(trainee_files),1);
                handles.trainin = cell(numel(trainee_files),1);
                trainoverlay = cell(numel(trainee_files));
                file_names = cell(numel(trainee_files),1);
                handles.sens = cell(numel(trainee_files),1);
                handles.spec = cell(numel(trainee_files),1);

                % load all selected ROIs
                for w = 1:numel(trainee_files)
                    files2Comp{w} = load(fullfile(path,trainee_files{w}), '-mat');
                    file_names{w} = strtok(trainee_files{w}, '.');
                    handles.trainroibnd{w} = files2Comp{w}.save_polygon;
                    handles.trainin{w} = training_calc_in(hObject, handles, handles.trainroibnd{w});
                    
                    %set trainee matrix
                    trainin = repmat(handles.trainin{w},1,1,num_windows);
                    trainoverlay{w} = curr_select;
                    trainoverlay{w}(trainin == 1 & senselvar{selected_condition}(:,:,time_order{selected_condition})>0) = 0.4;
                    
                    % Trainee positive and negatives
                    u = senselvar{selected_condition}(:,:,time_order{selected_condition});
                    u(~isnan(u) & u>0) = -2;
                    u(u==0) = NaN;
                    u(trainoverlay{w}>0) = 1;
                    
                    Tpos = sum(sum(t==u)); % true positives
                    Tneg = sum(sum(t==-1 & u==-2)); % true negatives
                    Fneg = sum(sum(t==1 & u==-2)); % false negatives
                    Fpos = sum(sum(t==-1 & u==1)); % false positives
                    
                    handles.sens{w} = Tpos./(Fneg+Tpos);
                    handles.spec{w} = Tneg./(Fpos+Tneg);
                end
                
                set(handles.senspec_popupmenu, 'String', file_names);
                set(handles.senspec_popupmenu, 'Value', 1);
            else
                % Load trainee's ROI
                files2Comp = load(fullfile(path,trainee_files), '-mat');
                set(handles.senspec_popupmenu, 'String', strtok(trainee_files, '.'));
                set(handles.senspec_popupmenu,'Value', 1);
                handles.trainroibnd = files2Comp.save_polygon;
                handles.trainin = training_calc_in(hObject, handles, handles.trainroibnd);
                                
                %set trainee matrix
                trainin = repmat(handles.trainin,1,1,num_windows);
                trainoverlay = curr_select;
                trainoverlay(trainin == 1 & senselvar{selected_condition}(:,:,time_order{selected_condition})>0) = 0.4;
                
                % Trainee positive and negatives
                u = senselvar{selected_condition}(:,:,time_order{selected_condition});
                u(~isnan(u) & u>0) = -2;
                u(u==0) = NaN;
                u(trainoverlay>0) = 1;
                               
                Tpos = sum(sum(t==u)); % true positives
                Tneg = sum(sum(t==-1 & u==-2)); % true negatives
                Fneg = sum(sum(t==1 & u==-2)); % false negatives
                Fpos = sum(sum(t==-1 & u==1)); % false positives
                
                handles.sens = Tpos./(Fneg+Tpos);
                handles.spec = Tneg./(Fpos+Tneg);
            end
            
            set(handles.senspec_popupmenu, 'Visible', 'On');
            set(handles.senspec_save, 'Enable', 'On');
        end
    else
        set(hObject, 'Checked', 'Off');
        set(handles.senspec_save, 'Enable', 'Off');
    end
    
    guidata(hObject, handles);
end
refresh_fig(hObject, handles);


% --- Executes on selection change in senspec_popupmenu.
function senspec_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to senspec_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns senspec_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from senspec_popupmenu
refresh_fig(hObject, handles);

% --- Executes during object creation, after setting all properties.
function senspec_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to senspec_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function senspec_save_Callback(hObject, eventdata, handles)
% hObject    handle to senspec_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, pathfile]=uiputfile(...
    {'*.csv','Comma Separated File(*.csv)';... %allows user to save data as a .csv
    '*.*',  'All Files(*.*)'}, ...
    'Save Sensitivity/Specificity', handles.path);

if ~isequal(file,0) %if the file is open
    handles.path = pathfile;
    guidata(hObject, handles);
    selected_condition = get(handles.condition_selector, 'Value');

    sensspec(1,:) = {'Frame' 'Sensitivity' 'Specificity'}; %initialize column headers
    if iscell(get(handles.senspec_popupmenu, 'String'))
        curr_ROI = get(handles.senspec_popupmenu, 'Value');
        for frames = 1:length(handles.sens{curr_ROI})
                sensspec(frames+1,:) = {num2str(frames) sprintf('%.3f', handles.sens{curr_ROI}(frames)) sprintf('%.3f', handles.spec{curr_ROI}(frames))};
        end
    else
        for frames = 1:length(handles.sens)
                sensspec(frames+1,:) = {num2str(frames) sprintf('%.3f', handles.sens(frames)) sprintf('%.3f', handles.spec(frames))};
        end
    end
    
    csvwrite([pathfile file], sensspec, 2) %write data to csv file
end


% --------------------------------------------------------------------
function convForce_menu_Callback(hObject, eventdata, handles)
% hObject    handle to convForce_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
else
    set(hObject, 'Checked', 'on');
end

refresh_fig(hObject, handles);


% --------------------------------------------------------------------
function diffRegions_Callback(hObject, eventdata, handles)
% hObject    handle to diffRegions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Map3D_Callback(hObject, eventdata, handles)
% hObject    handle to Map3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
    close(handles.fig3D)
else
    set(hObject, 'Checked', 'on');
    handles.fig3D = figure;
    handles.ax3D = axes(handles.fig3D);
    guidata(hObject,handles);
end

refresh_fig(hObject, handles);


% --- Executes on button press in useMaxSat_checkbox.
function useMaxSat_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to useMaxSat_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useMaxSat_checkbox
selected_condition = get(handles.condition_selector, 'Value');

if get(hObject, 'Value') == 1
    handles.persat = 0.02;
    handles.min_crange = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.saturation_pressure*handles.persat;
    set(handles.noise_floor_edit, 'String', num2str(handles.min_crange));
    set(handles.noise_floor_edit, 'Enable', 'off');
    set(handles.use1MaxSat_checkbox, 'Value', 0);
    handles.useMaxSat = true;
    guidata(hObject,handles);
else
    set(handles.noise_floor_edit, 'Enable', 'on');
    handles.useMaxSat = false;
end

refresh_fig(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over useMaxSat_checkbox.
function useMaxSat_checkbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to useMaxSat_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selected_condition = get(handles.condition_selector, 'Value');

if get(hObject, 'Value') == 1
    handles.persat = 0.02;
    handles.min_crange = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.saturation_pressure*handles.persat;
    set(handles.noise_floor_edit, 'String', num2str(handles.min_crange));
    set(handles.noise_floor_edit, 'Enable', 'off');
    handles.useMaxSat = true;
    guidata(hObject,handles);
else
    set(handles.noise_floor_edit, 'Enable', 'on');
    handles.useMaxSat = false;
end

refresh_fig(hObject, handles);

% --- Executes on button press in use1MaxSat_checkbox.
function use1MaxSat_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to use1MaxSat_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use1MaxSat_checkbox
selected_condition = get(handles.condition_selector, 'Value');

if get(hObject, 'Value') == 1
    handles.persat = 0.01;
    handles.min_crange = handles.tekvar{selected_condition}.header.row_spacing*handles.tekvar{selected_condition}.header.saturation_pressure*handles.persat;
    set(handles.noise_floor_edit, 'String', num2str(handles.min_crange));
    set(handles.noise_floor_edit, 'Enable', 'off');
    set(handles.useMaxSat_checkbox, 'Value', 0);
    handles.useMaxSat = true;
    guidata(hObject,handles);
else
    set(handles.noise_floor_edit, 'Enable', 'on');
    handles.useMaxSat = false;
end

refresh_fig(hObject, handles);