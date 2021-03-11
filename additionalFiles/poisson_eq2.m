function SSE = poisson_eq2(params)
global tekscan_data peak sigma_x sigma_y a_x a_y start gauss_img;
% peak = params(5);
sigma_x = params(1);
sigma_y = params(2);
% a_x = params(3);
% a_y = params(4);
[rows, cols] = size(gauss_img(:,:));
SSE = 0;

%seperates medial/lateral max/min
if (a_x+8) < cols/2
    max_cols = cols/2;
    min_cols = 1;
else
    max_cols = cols;
    min_cols = cols/2;
end

%why 10
min_x = round(a_x)-10;
max_x = round(a_x)+10;
min_y = round(a_y)-10;
max_y = round(a_y)+10;
% min_x = 1;
% max_x = cols;
% min_y = 1;
% max_y = rows;

%if outside boundary make boundary
if min_x < min_cols
    min_x = min_cols;
end
if max_x > max_cols
    max_x = max_cols;
end
if min_y < 1
    min_y = 1;
end
if max_y > rows
    max_y = rows;
end

for x = min_x:max_x
    for y = min_y:max_y
        if (x-a_x) <= 0 || (y-a_y) <= 0
            w = 0;
        else
            w = peak*((sigma_x)^(x-a_x)*exp(-1*sigma_x)/factorial(round(x-a_x)))*((sigma_y)^(y-a_y)*exp(-1*sigma_y)/factorial(round(y-a_y)));
        end
        curr_sensel = gauss_img(y,x);
        if ~isnan(curr_sensel)
            SSE = SSE + (curr_sensel - w)^2;
        end
        
%         figure(1)
%         pcolor(tekscan_data.data_l.sensel(:,:,105));
%         hold on
%         plot3(x,y,gauss_val, 'o')
%         drawnow
    end
end