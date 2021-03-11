function csvwrite(filename, cellarray, flag)
% save data as CSV
%filename is the path and filename to save to
%cellarray is the data to save stored as a cell array
%flag determines if the data has a row data to save as decimal

if flag == 1
    fid=fopen(filename,'wt');
    
    [rows, ~] = size(cellarray);
    csvFun = @(str)sprintf('%d,',str);
    csvFun1 = @(str)sprintf('%s,',str);
    xchar = cellfun(csvFun, cellarray(1:end,:), 'UniformOutput', false);
    titlechar = cellfun(csvFun1, cellarray(1,:), 'UniformOutput', false);
    
    for index = 1:rows
        if index == 1
            lchar = strcat(titlechar{1,:});
            lchar = strcat(lchar(1:end-1),'\n');
            fprintf(fid,lchar);
        else
            lchar = strcat(xchar{index,:});
            lchar = strcat(lchar(1:end-1),'\n');
            fprintf(fid,lchar);
        end
    end
    
    fclose(fid);
else
    fid=fopen(filename,'wt');
    
    [rows, ~] = size(cellarray);
    csvFun = @(str)sprintf('%s,',str);
    xchar = cellfun(csvFun, cellarray, 'UniformOutput', false);
    
    for index = 1:rows
        lchar = strcat(xchar{index,:});
        lchar = strcat(lchar(1:end-1),'\n');
        fprintf(fid,lchar);
    end
    
    fclose(fid);
end