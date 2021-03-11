function data = onfly_tekscan_csv2mat(file,path)
%% Parse Tekscan for Data, Initialize Output Filenames
%now we are using new file format new_old = 'N'
if exist('path','var')
	[header, s]=parse_tekscan_csv([path file]);
else
	[header, s]=parse_tekscan_csv(file);
end

%% Initialize variables
time=(0:header.end_frame-header.start_frame)'.*header.seconds_per_frame;	% time(frame)

% Save Both Plateaus
data_a.time=time;
data_a.sensel=s;

%% Save Bulk Information in Matlab Struct
data.header = header;
data.data_a = data_a;
% save(mat_name,'header','data_a');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [header, P_xyt]=parse_tekscan_csv(file)
%% parse_tekscan_csv
% Parser for tekscan ascii output
% Inputs
%	file - FULL filename
% Outputs
%	header - struct with tekscan header data (25 fields indepedent of tekscan file)
%	P_xyt - Pressure(x,y,time). Size determined through header data

%% Open file (custom format requires low level i/o)
fid=fopen(file);

%% Parse Header Data
% hdr_names determines whether header section should be stored
% header values can be found by opening files in a text editor
    hdr_names={...
        'rows'; 'cols'; 'row_spacing'; 'col_spacing'; 'sensel_area';...
        'noise_treshold'; 'seconds_per_frame'; 'micro_second'; 'scale_factor';...
        'exponent'; 'saturation_pressure_MPa';...
        'start_frame'; 'end_frame'; 'mirror_row'; 'mirror_col';...
        };

    temp=fgetl(fid);
    [name, value]=strtok(temp);

% Parse raw data for header information
while ~strcmpi(name, 'frame') && ~strcmpi(name, '') && ~strcmpi(name, ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,')
	temp_value=deblank(strtrim(value));
    if ismember(lower(name), hdr_names)
		value=strtok(temp_value);
		header.(lower(name))=str2double(value);
	end
	temp=fgetl(fid);
	[name, value]=strtok(temp);
end
clear text rem i

%% Parse Pressure Data
%edited by Hongsheng on 11/28/12, change the read-in format from cell to double array to
%speed it up.
P_xyt_format=repmat('%n',1,header.cols);	% Row wise data format

P_xyt = zeros(header.rows,...
	header.cols,...
	header.end_frame-header.start_frame+1);	% Initialize P_xyt
P_xyt(:,:,:) = NaN;

% First frame handled separately (behavior issues btwn i/o functions)
temp=textscan(fid,P_xyt_format,header.rows,'Delimiter',',','treatAsEmpty',{'B','b'},'Headerlines',1,'CollectOutput',1);
P_xyt(:,:,1)=temp{:,:};

% Remaining frames are handled through for loop
for i=2:size(P_xyt,3)
   temp=textscan(fid,P_xyt_format,header.rows,'Delimiter',',','treatAsEmpty',{'B','b'},'Headerlines',3,'CollectOutput',1);
   if header.rows > size(temp{1},1)
       println('Short!');
   end
   P_xyt(:,:,i)=temp{1}(:,:);
end

%% Close file
fclose(fid);
