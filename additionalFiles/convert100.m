% converts a function from any range to from 0%~100% (such as a gati circle)
% bu Gao Bo, Feb 27, 2006

function [p, t]=convert100(y, x, num_t)

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