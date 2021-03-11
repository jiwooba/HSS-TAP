function [row, col, row_loc] = getClosestPoint(point, ROI)
%compute Euclidean distances
distances = sum(bsxfun(@minus, ROI, point).^2,2);
%find the smallest distance and use that as an index into ROI
row_loc = find(distances==min(distances));
closest = ROI(distances==min(distances),:);
row = closest(1);
col = closest(2);