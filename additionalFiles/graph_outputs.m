% So you want to put the two files in the same directory as the rest of the
% code for the tekscan program since it uses some of the functions.  
% Run the program “charcurvefinder.m” first to find all characteristic curves.
% After the program is done running you have to right click on the variable
% “corr_patterns” and then save it as a mat file.  The program 
% “char_curve_output.m” just outputs the figures and saves them.
clc; clear;

counter = 1;
tracker = 0;

output_files = {'CA', 'stats', 'WCoC'};
stats_comps = {'Time [s]', 'Mean [N]', 'Max [N]', 'Loc X Max Force [mm]', 'Loc Y Max Force [mm]', 'Min [N]', 'Loc X Min Stress [mm]', 'Loc Y Min Stress [mm]', 'Sum [N]', 'Percent Gait', 'Flexion Angle [deg]'};
CA_comps = {'Time [s]', 'Contact Area [mm^2]', 'Meniscus Contact Area [mm^2]', 'Percent Gait', 'Flexion Angle [deg]'};
WCoC_comps = {'Time [s]', 'Percent Gait', 'Flexion Angle [deg]', 'Medial_X [mm from origin]', 'Medial_dX/dt [mm/s]', 'Medial_Y [mm from origin]', 'Medial_dY/dt [mm/s]', 'Lateral_X [mm from origin]', 'Lateral_dX/dt [mm/s]', 'Lateral_Y [mm from origin]', 'Lateral_dY/dt [mm/s]', 'Slope between ML COS', 'Intercept between ML COS', 'Rotation of ML COS [o/s]'};

%%--------location of individual files----------
loc = 'C:\Users\chento\SkyDrive\HSS DATA\Cartilage R01\20180126 Cadaveric Knees\ISO Char Curves\';

kneeID = {'Knee 01','Knee 03','Knee 04',...
    'Knee 05', 'Knee 06', 'Knee 07'...
    'Knee 08'...
    };

conditionID = {'Intact', 'Defect', '10PVA', '20PVA',...
    '10PVATi', '20PVATi'};

groups = {'total', 'medial', 'lateral', 'medial_MC_ROI', 'medial_CC_ROI', 'lateral_MC_ROI', 'lateral_CC_ROI'};

choice = questdlg('Use Average Data?', ...
    'Average Data', ...
    'Yes','No','Yes');

if strcmpi(choice, 'yes')
    endFile = '_avg';
else
    endFile = '';
end

while counter <=  size(kneeID,2)
    t = [loc, kneeID{counter}];
    currdir{counter}.folder = t;
    if rel_abs ==1
        txtfiles = dir(fullfile(currdir{counter}.folder, '*.rel')); %relative stress curves
    else
        txtfiles = dir(fullfile(currdir{counter}.folder, '*.txt')); %absolute stress curves
    end
    currdir{counter}.txtfiles = txtfiles; 
    currdir{counter}.txtfiles(1).ncc_value = [];
    currdir{counter}.txtfiles(1).flag = [];
    currdir{counter}.shift = 1;
    
    rightleft{counter} = 'Left'; %because there is no differences
    
    counter = counter + 1;
end