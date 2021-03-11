function [I, J] = centroid_location(pmap, noise_floor, weight)

% Variables: I, w and y are the rows
% Variables: J, q and x are the cols

%% Variable Initialization
centroid_y = 0;
centroid_x = 0;
counter = 0;

[row, col] = size(pmap);

%% Calculates the Weighted Center of Contact Stress (WCOCS)
for w = 1:row
    for q = 1:col
        
        % only calculate data above set noise threshold
        if ~isnan(pmap(w,q)) && pmap(w,q) > noise_floor
            if weight
                weight_factor = pmap(w,q);
            else
                weight_factor = 1;
            end

            counter = counter + (weight_factor); % keeps tally of number of data points used
            centroid_y = centroid_y + w*weight_factor; % add sensel y location weighted by stress
            centroid_x = centroid_x + q*weight_factor; % add sensel x location weigthed by stress
        end
    end
end

I = centroid_y/counter; % get average y location
J = centroid_x/counter; % get average x location