%In this example, we first simulate scan and rescan connectivity matrices 
%for 20 subjects, using random normals with signal (across-subject) 
%variance of 0.1^2 and noise (within-subject) variance of 0.1^2 (on the 
%Normal scale).  We apply the inverse Fisher transform to obtain 
%correlations.
%
%We then use the function mat2UT to extract the upper-triangle of each
%matrix.  This is done because the shrinkIt function expects a matrix of
%size m-by-n, where m is the number of variables observed for each subject
%and n is the number of subjects. 
%
%We use the shrinkIt function to apply shrinkage.  This function requires
%two measures for each subject (scan and rescan), as well as the total scan
%time (across scan and rescan) per subject.  It then estimates the optimal 
%degree of shrinkage, which depends on the estimated signal and noise
%variance.  The estimated noise variance depends on the total scan time per
%subject. 

%% ADD PATH TO SHRINKIT TOOLBOX 

addpath '~/matlab_toolboxes/shrinkIt/'


%% POINT TO DATA AND GET FILE NAMES

data_dir = '/dcs01/oasis/hpc/HCP500_Parcellation_Timeseries_Netmats/Results/node_timeseries/3T_Q1-Q6related468_MSMsulc_d300_ts2';
fnames = dir(data_dir); %get list of files
fnames = fnames(3:end); %remove . and ..
n = numel(fnames); %number of subjects



%% SET FUNCTION(S) TO APPLY TO DATA

%single function example: compute VxV correlation matrix
fun_single = 'corrcoef';

%multiple function example: compute upper triangle of VxV correlation matrix, then Fisher-transform
fun_multiple = {'corrcoef', 'mat2UT', 'fish'};


%% LOOP THROUGH SUBJECTS TO CREATE DATA MATRICES

cd(data_dir)
for ii = 1:n
    
    ii
    
    % READ IN TIME SERIES DATA
    
    fnamei = fnames(ii);
    fnamei = fnamei.name;
    
    %data stored as text files
    Yi = readtable(fnamei, 'Delimiter',' ','ReadVariableNames', false);
    Yi1 = Yi(1:1200,:); %visit 1, LR acquisition
    Yi2 = Yi(2401:3600,:); %visit 2, LR acquisition
    
    % SPLIT TIME SERIES DATA USING SPLIT_TS()
    % COMPUTE UT OF CORRELATION MATRIX
    
    %single function example: 
    %split data and compute VxV correlation matrix for each split
    [X1i X2i] = split_ts(Yi1, fun_single);
    
    %multiple function example:
    %split data and compute upper triangle of VxV correlation matrix for each split
    [X1i X2i] = split_ts(Yi1, fun_multiple);


    % COMPUTE ESTIMATE FROM SECOND VISIT FOR RELIABILITY ANALYSIS
    X_visit2i = fish(mat2UT(corrcoef(table2array(Yi2))));

    
    % COMBINE SUBJECTS
    
    if(ii==1) 
        %initialize group arrays for each split
        [X1 X2 X_visit2] = deal(zeros([size(X1i), n]));
    end

    %add current subject to group arrays:
    %X's have dimensions (p1,p2,...,pk,n), so use (:,:,...,:,ii) to index subject ii 
    index = repmat({':'},1,ndims(X1)); %(:,:,...,:,:)
    index{end} = ii;                   %(:,:,...,:,ii)

    X1(index{:}) = X1i;
    X2(index{:}) = X2i;
    X_visit2(index{:}) = X_visit2i;
    
end

%remove superfluous dimensions (of size 1)
X1 = squeeze(X1);
X2 = squeeze(X2);
X_visit2 = squeeze(X_visit2);



%% PERFORM SHRINKAGE

% RUN shrinkIt TO OBTAIN SHRINKAGE ESTIMATE X (m-by-n MATRIX) AND SHRINKAGE PARAMETER

%Assume each subject has 10 minutes of scan time total
%(two 5-minute scans, or one 10-minute scan split in two)

[X_shrink lambda var_within var_between] = shrinkIt(X1, X2);


% VISUALIZE VARIANCE COMPONENTS & DEGREE OF SHRINKAGE

X_visit1 = (X1 + X2)./2; %visit 1 raw estimate (fisher-transformed)
var_within_true = (1/2)*var(X_visit2 - X_visit1, 0, 2);

maxv = max([max(var_within(:)),max(var_between(:)),max(var_within_true(:))])*.4;


figure
h = subplot(2,2,1);
image(UT2mat(var_within, 0),'CDataMapping','scaled')
colorbar; caxis([0,maxv]); axis off;
title('Within-Subject Variance (Estimated)')
h = subplot(2,2,2);
image(UT2mat(var_within_true, 0),'CDataMapping','scaled')
colorbar; caxis([0,maxv]); axis off;
title('Within-Subject Variance (True)')
h = subplot(2,2,3);
image(UT2mat(var_between, 0),'CDataMapping','scaled')
colorbar; caxis([0,maxv]); axis off;
title('Between-Subject Variance')
h = subplot(2,2,4);
image(UT2mat(lambda, 0),'CDataMapping','scaled')
colorbar; caxis([0,1]); axis off;
title('Degree of Shrinkage')


% VISUALIZE RSFC ESTIMATES & RELIABILITY

X_shrink = unfish(X_shrink); %inverse Fisher-transform to obtain Pearson correlations
X_avg = (unfish(X1) + unfish(X2))/2;
X_visit2 = unfish(X_visit2);

figure
h = subplot(3,3,1);
image(UT2mat(X_avg(:,1), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 1 Raw Estimate')
h = subplot(3,3,2);
image(UT2mat(X_avg(:,2), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 2 Raw Estimate')
h = subplot(3,3,3);
image(UT2mat(X_avg(:,3), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 3 Raw Estimate')
h = subplot(3,3,4);
image(UT2mat(X_shrink(:,1), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 1 Shrinkage Estimate')
h = subplot(3,3,5);
image(UT2mat(X_shrink(:,2), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 2 Shrinkage Estimate')
h = subplot(3,3,6);
image(UT2mat(X_shrink(:,3), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 3 Shrinkage Estimate')
h = subplot(3,3,7);
image(UT2mat(X_visit2(:,1), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 1 Raw Estimate (Visit 2)')
h = subplot(3,3,8);
image(UT2mat(X_visit2(:,2), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 2 Raw Estimate (Visit 2)')
h = subplot(3,3,9);
image(UT2mat(X_visit2(:,3), 1),'CDataMapping','scaled')
colormap parula; caxis([-.5,.5]); axis off; %colorbar; 
title('Subject 3 Raw Estimate (Visit 2)')

set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0 0 12 10]);
saveas(gcf, '~/Shrinkage/plots/Example_RSFC.png')



% COMPUTE VISIT 2 MSE OF RAW AND SHRINKAGE ESTIMATES

%MSE across all connections for each subject
MSE_raw = mean((X_avg - X_visit2).^2);
MSE_shrink = mean((X_shrink - X_visit2).^2);

%Percent change in MSE due to shrinkage (negative = reduction in MSE, improved reliability)
mean((MSE_shrink - MSE_raw)./MSE_raw)

sqerr_raw = (X_avg - X_visit2).^2;
sqerr_shrink = (X_shrink - X_visit2).^2;
sqerr_raw = mean(sqerr_raw, 2); %median across subjects
sqerr_shrink = mean(sqerr_shrink, 2); %median across subjects
sqerr_change = 100*(sqerr_shrink - sqerr_raw)./sqerr_raw; %negative = reduction in MSE

figure
h = subplot(1,3,1);
image(UT2mat(sqerr_raw, 0),'CDataMapping','scaled')
caxis([0,.03]); axis off; colorbar; 
title('Squared Error, Raw Estimates')
h = subplot(1,3,2);
image(UT2mat(sqerr_shrink, 0),'CDataMapping','scaled')
caxis([0,0.03]); axis off; colorbar; 
title('Squared Error, Shrinkage Estimates')
h = subplot(1,3,3);
image(UT2mat(sqerr_change, 0),'CDataMapping','scaled')
caxis([-30,30]); axis off; colorbar; 
title('% Change due to Shrinkage')


