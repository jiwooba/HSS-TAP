function map2surf(ax, surfm, dataX, dataY, marker)
% Take 2d data and map to a surface
F = griddedInterpolant(surfm);
[Xq,Yq] = ndgrid(dataX, dataY);
Vq = F(Yq',Xq');
z3D = Vq(logical(eye(size(Vq))));
z3D(isnan(z3D)) = 0;
hold(ax, "on");
plot3(ax, dataX,dataY,z3D, marker, 'LineWidth', 3);
hold(ax,"off");