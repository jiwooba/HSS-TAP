function tekscan_parse = open_tekscan(file, pathfile)   
% opens and parses Tekscan .asf, .csv and .mat files

[~, file_post] = strtok(file, '.');

% Parse Tekscan file
if strcmpi(file_post, '.asf') || strcmpi(file_post, '.csv') % Uses appropriate header depending on tekscan I-Scan Version
    tekscan_parse = onfly_tekscan_2mat(file, pathfile); % open either a .asf or .csv Tekscan file
else
    tekscan_parse = open([pathfile file]); % assumes open a pre-parsed .mat file
end