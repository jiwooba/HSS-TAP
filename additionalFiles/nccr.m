function [ccr, lag] = nccr(matx, template, plot_corr)
% Pre: Input the matrix to be compared (matx), the template curve matrix (template)
%      and true/false as to whether to plot the correlation curves
%      (plot_corr; mainly for troubleshooting)
%Post: Outputs the normalized cross-correlation curve vector (ccr)

%% Initialize Variables
window_size = length(template);
ccr = [];
length_matx = length(matx);
template_mean = mean(template(1:window_size));
template_sqsum = sum((template(1:window_size)-template_mean).^2);

%% Calculate Normalized Cross-Correlation Between Two Sensels

%=====Version 1: Tony's version, compute the correlation by loops
% for start = 1:length_matx-window_size
%     num = sum((matx(start:start+window_size-1)-mean(matx(start:start+window_size-1))).*(template-mean(template)));
%     denom = sum((matx(start:start+window_size-1)-mean(matx(start:start+window_size-1))).^2);
%     if denom == 0 || mean(template)==0
%         ccr(start) = 0;
%     else
%         ccr(start) = num/sqrt(denom*sum((template-mean(template)).^2));
%     end
% %     if plot_corr && max(matx)>0.1
% %         figure(301)
% %         plot(template(1:length_matx-start+1),'r--')
% %         hold on
% %         plot(matx(start:length_matx))
% %         title(['cross match'])
% %         axis([0 window_size 0 1])
% %         hold off
% %         drawnow
% %     end
%     % Plot overlay of template with current loading pattern
%     if plot_corr && max(matx)>0.1
%         figure(301)
%         plot(template(1:window_size),'r--')
%         hold on
%         plot(matx(start:window_size+start-1))
%         title(['cross match'])
%         axis([0 window_size 0 1])
%         hold off
%         drawnow
%     end
% end
% aa = 1;
%=======Version 2: Sean edited, computer the ncc using the xcorr
% TC: NOTE - xcorr performs just cross correlation. Adding the 'coeff' 
% parameter only normalizes the output to have a maximum value of 1 but 
% still only uses cross correlation! Meaning it takes magnitude into 
% account so need to normalize the template and pattern of
% interest before comparing to perform NCC. 01/29/2017
norm_matx = (matx(1:window_size)-mean(matx(1:window_size)))/std(matx(1:window_size)); % 01/29/2017 TC: Normalize pattern of interest (POI) using the following equation (POI - mean(POI))/STDEV(POI)
norm_template = (template - mean(template))/std(template); % 01/29/2017 TC: Normalize template using the following equation (template - mean(template)/STDEV(template)

[ccr, lag] = xcorr(norm_matx,norm_template, 'coeff');
if size(ccr,1) > 1
%     ccr1 = [ccr(1); ccr; ccr(end)];
    ccr = ccr';
else
%     ccr1 = [ccr(1) ccr ccr(end)];
    ccr = ccr;
end
 clear ccr1;

%% Plot Normalized Cross-Correlations if plot_corr is set to true
if plot_corr
    figure(300)
    plot(ccr,'.--')
    hold on
    plot([0 length(ccr)], [.8 .8], 'k--')
    hold off
    title(['NCC of Sensel...'])
    axis([0 length(ccr) -1 1])
end

end