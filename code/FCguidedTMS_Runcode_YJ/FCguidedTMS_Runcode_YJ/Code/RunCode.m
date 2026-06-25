clc;clear;

% Last Modified by 21-6-2024 16:52:12 yuejuan1016@gmail.com
% FC-guided TMS target validation workflow.
%% 1. Parameters to edit

codeRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeRoot);

Startpath='/Users/yuejuan/Desktop/sub008'; %Starting directory
Subdirname='sub008'; 
T1filename = 'sub008_T1_mprage_iso_20240617102827_2_Crop_1.nii'; % T1 filename in T1NewSegment or T1Img/<subject>.
FC_Step_1 = fullfile(codeRoot,'Step1_AR2.mat');
FC_Step_2 = fullfile(codeRoot,'Step2_SCF.mat');
FC_Step_3 = fullfile(codeRoot,'Step3_FC.mat');
TPMpath = '/Users/yuejuan/Downloads/data_software/spm12_v7771/tpm/TPM.nii'; % Update this to your local SPM TPM.nii path.
Templatedir = fullfile(projectRoot,'mask'); % Template directory. Put stimulation and effect-region masks here.
radius = 2; % Sphere radius.
coordinates = [-12 -21 -1]; % Sphere center coordinates in native space.
Template_stimulation_target='Left_M1.nii'; % Stimulation target mask in standard space.
Interp = 0; % for MNI template to native space
TimePoints = 500; % Number of time points.
TR = 1; % TR in seconds.
RemoveFirstTimePoints = 10; % Number of initial time points to remove; update according to the dataset.

if RemoveFirstTimePoints >= TimePoints
    error('RemoveFirstTimePoints must be smaller than TimePoints.');
end

requiredConfigFiles = {FC_Step_1,FC_Step_2,FC_Step_3,fullfile(Templatedir,Template_stimulation_target)};
for ifile = 1:numel(requiredConfigFiles)
    if ~exist(requiredConfigFiles{ifile},'file')
        error('Required file not found: %s.',requiredConfigFiles{ifile});
    end
end
clear ifile requiredConfigFiles

%% 1. Data transformation, removing first N time points, slice timing, and realignment
load(FC_Step_1);
Cfg.WorkingDir=Startpath;
Cfg.DataProcessDir=Startpath;
Cfg.StartingDirName='FunRaw';
Cfg.SubjectID = {Subdirname}; 
Cfg.TimePoints = TimePoints;
Cfg.TR = TR;
Cfg.RemoveFirstTimePoints = RemoveFirstTimePoints;
Volumenumber = Cfg.TimePoints - Cfg.RemoveFirstTimePoints;
disp(['===================' 'Step 1. Data preprocessing for ' '==================='  [Subdirname] '==================='])
mat_name=['FC_Step_1_' Subdirname '.mat'];
save_path=[Startpath filesep mat_name];save(save_path,'Cfg');
DPARSFA_run(save_path);
disp('Resting_Step_1 operation completed')
clear Cfg

%% 2. T1 file setting

destination_file_seg=fullfile(Startpath,'T1NewSegment');
if ~exist(destination_file_seg,'dir')
    mkdir(destination_file_seg);
end
SegT1file=fullfile(destination_file_seg,T1filename);
if ~exist(SegT1file,'file')
    StructT1_Reference=fullfile(Startpath,'T1Img',Subdirname,T1filename);
    if exist(StructT1_Reference,'file')
        copyfile(StructT1_Reference,destination_file_seg);
    else
        error('T1 file not found. Expected either %s or %s.',SegT1file,StructT1_Reference);
    end
end

%% 3. coregister AR to T1Img (First check!)
meanra=dir([Startpath filesep 'RealignParameter' filesep Subdirname filesep 'mean*']);
if isempty(meanra)
    error('No mean realigned image was found under %s.',fullfile(Startpath,'RealignParameter',Subdirname));
elseif numel(meanra)>1
    warning('Multiple mean realigned images were found. Using the first one: %s.',meanra(1).name);
end
meanrafile=[meanra(1).folder filesep meanra(1).name];
ra=dir([Startpath filesep 'FunImgAR' filesep Subdirname filesep 'ra*']);
if isempty(ra)
    error('No realigned functional image was found under %s.',fullfile(Startpath,'FunImgAR',Subdirname));
elseif numel(ra)>1
    warning('Multiple realigned functional images were found. Using the first one as a 4D image: %s.',ra(1).name);
end
rafile=[ra(1).folder filesep ra(1).name];
for i=1:Volumenumber
    others_rapath = strcat(rafile,',',num2str(i));
    others_ra_allfile{i,1} = others_rapath;
end
matlabbatch{1}.spm.spatial.coreg.estimate.ref = {[SegT1file ',1']};
matlabbatch{1}.spm.spatial.coreg.estimate.source = {[meanrafile ',1']};
matlabbatch{1}.spm.spatial.coreg.estimate.other = others_ra_allfile;
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
spm_jobman('run',matlabbatch);
clear i
clear matlabbatch;
disp('FunImgAR coregister completed')

% Select the image to be reoriented
P = spm_select(1, 'image', 'First check: Coregister!');

% Call the function
spm_image('Display', P);

% Prompt the user to continue
disp('Please check the image in SPM display window. Press any key to continue once checked.');
pause;  % This will pause execution until the user presses a key

%% 4. T1 New Segment

% matlabbatch{1}.spm.spatial.preproc.channel.vols = {[SegT1file ',1']};
% matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
% matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
% matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[TPMpath ',1']};
% matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
% matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[TPMpath ',2']};
% matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
% matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[TPMpath ',3']};
% matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
% matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[TPMpath ',4']};
% matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
% matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[TPMpath ',5']};
% matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
% matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[TPMpath ',6']};
% matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
% matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
% matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
% matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
% matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
% matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
% matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
% matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
% matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
% matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];
% spm_jobman('run',matlabbatch);
% clear matlabbatch;
% disp('T1 New Segment completed');

%% 5. Covariate Template Coregister to original space
[Dpabi_Path,~,~] = fileparts(which('dpabi.m'));
if isempty(Dpabi_Path)
    [Dpabi_Path,~,~] = fileparts(which('DPABI.m'));
end
if isempty(Dpabi_Path)
    error('DPABI was not found on the MATLAB path. Add DPABI and its dependencies before running this script.');
end
TemplatePath = fullfile(Dpabi_Path,'Templates');
MasksName{1,1}=[TemplatePath,filesep,'BrainMask_05_91x109x91.img'];
MasksName{2,1}=[TemplatePath,filesep,'CsfMask_07_91x109x91.img'];
MasksName{3,1}=[TemplatePath,filesep,'WhiteMask_09_91x109x91.img'];
MasksName{4,1}=[TemplatePath,filesep,'GreyMask_02_91x109x91.img'];
for imask = 1:4
    priorMaskFile = MasksName{imask,1};
    if ~exist(priorMaskFile,'file')
        error('Required DPABI template mask not found: %s.',priorMaskFile);
    end
    [~,Maskname,~] = fileparts(priorMaskFile);
    WarpedMaskPath = fullfile(Startpath,'Masks','WarpedMasks');
    WarpedMaskName = fullfile(WarpedMaskPath,[Subdirname '_' Maskname '.nii']);
    RefFilename = list_image_files(fullfile(Startpath,'FunImgAR',Subdirname));
    if isempty(RefFilename)
        error('No reference functional image was found under %s.',fullfile(Startpath,'FunImgAR',Subdirname));
    end
    RefFile = fullfile(Startpath,'FunImgAR',Subdirname,RefFilename{1});
    iydef_Filename = list_image_files(fullfile(Startpath,'T1NewSegment'),'iy');
    if isempty(iydef_Filename)
        error('No inverse deformation field iy*.nii was found under %s. Run or provide SPM New Segment outputs first.',fullfile(Startpath,'T1NewSegment'));
    end
    iydef = fullfile(Startpath,'T1NewSegment',iydef_Filename{1});
    if ~exist(WarpedMaskPath, 'dir')
        mkdir(WarpedMaskPath);
    end
    normalize_write_to_reference(priorMaskFile,WarpedMaskName,RefFile,iydef,Interp);
end

%% 6. Template write to original space, Second check!
oldTemplatepath = Templatedir;
newTemplatepath = strcat(Startpath,filesep,'Template_Write2origin');
if ~exist(newTemplatepath,'dir')
    mkdir(newTemplatepath);
end
copyfile(oldTemplatepath,newTemplatepath);
norm_iy_path = [Startpath filesep 'T1NewSegment'];
dir_norm_iy_path = dir([norm_iy_path filesep 'iy*.nii']);
if isempty(dir_norm_iy_path)
    error('No inverse deformation field iy*.nii was found under %s.',norm_iy_path);
elseif numel(dir_norm_iy_path)>1
    warning('Multiple inverse deformation fields were found. Using the first one: %s.',dir_norm_iy_path(1).name);
end
norm_def_path = [norm_iy_path filesep dir_norm_iy_path(1).name];
norm_stimulationtarget = [Templatedir,filesep,Template_stimulation_target];
orig_stimulationtarget = [newTemplatepath,filesep,'Ori' Template_stimulation_target];
normalize_write_to_reference(norm_stimulationtarget,orig_stimulationtarget,RefFile,norm_def_path,Interp);
orig_effectiveregion = fullfile(newTemplatepath, ['Orig_Sphere_Radius' num2str(radius) '_Coord' num2str(coordinates(1)) '_' num2str(coordinates(2)) '_' num2str(coordinates(3)) '.nii']);
y_Sphere(coordinates, radius, RefFile, orig_effectiveregion);
disp('Template write to origin completed')

% Select the image to be checked
P = spm_select(1, 'image', 'Second check: Template write to original space!');

% Call the function to display the image
spm_image('Display', P);

% Prompt the user to continue
disp('Please check the image in SPM display window. Press any key to continue once checked.');
pause;  % This will pause execution until the user presses a key

% The remaining workflow will not run until the user presses a key.

%% 7. Smooth, nuisance regression, filtering
load(FC_Step_2) 
Cfg.WorkingDir=Startpath;
Cfg.DataProcessDir=Startpath;
Cfg.StartingDirName='FunImgAR'; 
Cfg.SubjectID = {Subdirname}; 
Cfg.TimePoints = Volumenumber;
Cfg.TR = TR;
disp(['===================' 'Step 2. Data preprocessing for ' '==================='  [Subdirname] '==================='])
mat_name=['FC_Step_2_' Subdirname '.mat'];
save_path=[Startpath filesep mat_name];save(save_path,'Cfg');
DPARSFA_run(save_path);
disp('Resting_Step_2 operation completed');
clear Cfg

%% 8. FC calculation
load(FC_Step_3) 
Cfg.WorkingDir=Startpath;
Cfg.DataProcessDir=Startpath;
Cfg.StartingDirName='FunImgARSCF'; 
Cfg.SubjectID = {Subdirname}; 
Cfg.TimePoints = Volumenumber;
Cfg.TR = TR;
Cfg.MaskFile = [WarpedMaskPath filesep Subdirname '_BrainMask_05_91x109x91.nii'];
Cfg.CalFC.ROIDef{1,1} = orig_effectiveregion;
disp(['===================' 'Step 3. Data preprocessing for ' '==================='  [Subdirname] '==================='])
mat_name=['FC_Step_3_' Subdirname '.mat'];
save_path=[Startpath filesep mat_name];
save(save_path,'Cfg');
DPARSFA_run(save_path);
disp('Resting_Step_3 operation completed');
disp('Congratulations, the FC-guided TMS workflow is complete. Please check the data.');
