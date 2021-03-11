function data = onfly_tekscan_asf2mat_tc_hw(file,path, new_old)
%% Parse Tekscan for Data, Initialize Output Filenames
%now we are using new file format new_old = 'N'
if exist('path','var')
	[header, s]=parse_tekscan_asf([path file], new_old);
else
	[header, s]=parse_tekscan_asf(file);
end

%% Initialize variables
time=(0:header.end_frame-header.start_frame)'.*header.seconds_per_frame;	% time(frame)

% Save Data whole sensor
data_a.time=time;
data_a.sensel=s;

%% Save Bulk Information in Matlab Struct
data.header = header;
data.data_a = data_a;
% save(mat_name,'header','data_a');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [header, P_xyt]=parse_tekscan_asf(file, new_old)
%% parse_tekscan_asf
% Parser for tekscan ascii output
% Inputs
%	file - FULL filename
% Outputs
%	header - struct with tekscan header data (25 fields indepedent of tekscan file)
%	P_xyt - Pressure(x,y,time). Size determined through header data

%% Open file (custom format requires low level i/o)
fid=fopen(file);

%% Parse Header Data
% num_flag determines whether header section should be parsed as a number
if strcmpi(new_old, 'N')
    hdr_names={...
        'data_type'; 'version'; 'hardware'; 'map_version'; 'hw_type'; 'filename'; 'sensor_type'; 'rows';...
        'cols'; 'row_spacing_mm'; 'col_spacing_mm'; 'sensel_area_mm2'; 'noise_treshold';...
        'seconds_per_frame'; 'micro_second'; 'time'; 'scale_factor'; 'exponent';...
        'saturation_pressure_MPa'; 'calibration_point_1'; 'calibration_mode_1'; 'calibration_point_2'; 'calibration_mode_2'; 'calibration_info'; 'sensitivity';...
        'start_frame'; 'end_frame'; 'units'; 'mirror_row'; 'mirror_col';...
        'ascii_data'};
    num_flag=[...
        0; 0; 0; 0; 0; 0; 0; 1;...
        1; 1; 1; 1; 1;...
        1; 1; 0; 1; 1;...
        1; 0; 0; 0; 0; 0; 0;...
        1; 1; 0; 1; 1;...
        0];
else
    hdr_names={...
        'data_type'; 'version'; 'filename'; 'sensor_type'; 'rows';...
        'cols'; 'row_spacing_mm'; 'col_spacing_mm'; 'sensel_area_mm2'; 'noise_treshold';...
        'seconds_per_frame'; 'micro_second'; 'time'; 'scale_factor'; 'exponent';...
        'saturation_pressure_MPa'; 'calibration_point_1'; 'calibration_point_2'; 'calibration_info'; 'sensitivity';...
        'start_frame'; 'end_frame'; 'units'; 'mirror_row'; 'mirror_col';...
        'ascii_data'};
    num_flag=[...
        0; 0; 0; 0; 1;...
        1; 1; 1; 1; 1;...
        1; 1; 0; 1; 1;...
        1; 0; 0; 0; 0;...
        1; 1; 0; 1; 1;...
        0];
end

% Parse raw data for header information
for i=1:length(hdr_names)
	temp=fgetl(fid);
	[~, value]=strtok(temp);
	header.(hdr_names{i})=deblank(strtrim(value));
	if num_flag(i)==1
		value=strtok(header.(hdr_names{i}));
		header.(hdr_names{i})=str2double(value);
	end
end
clear text rem i

%% Parse Pressure Data
%edited by Hongsheng on 11/28/12, change the read-in format from cell to double array to
%speed it up.
P_xyt_format=repmat('%n',1,header.cols);	% Row wise data format
% P_xyt=cell(header.rows,...
% 	header.cols,...
% 	header.end_frame-header.start_frame+1);	% Initialize P_xyt
P_xyt = zeros(header.rows,...
	header.cols,...
	header.end_frame-header.start_frame+1);	% Initialize P_xyt
P_xyt(:,:,:) = NaN;

% First frame handled separately (behavior issues btwn i/o functions)
temp=textscan(fid,P_xyt_format,header.rows,'Delimiter',',','treatAsEmpty',{'B','b'},'Headerlines',2,'CollectOutput',1);
P_xyt(:,:,1)=temp{:,:};

% Remaining frames are handled through for loop
for i=2:size(P_xyt,3)
	temp=textscan(fid,P_xyt_format,header.rows,'Delimiter',',','treatAsEmpty',{'B','b'},'Headerlines',3,'CollectOutput',1);
	P_xyt(:,:,i)=temp{1}(:,:);
end

%% Close file
fclose(fid);
end