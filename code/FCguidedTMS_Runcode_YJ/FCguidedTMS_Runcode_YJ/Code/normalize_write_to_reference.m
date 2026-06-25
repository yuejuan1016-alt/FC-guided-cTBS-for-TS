function normalize_write_to_reference(priorMaskFile,OutFile,RefFile,iyParameterFile,Interp)
% FORMAT y_NormalizeWrite(SourceFile,OutFile,RefFile,ParameterFile,Interp)
%   Adapted from DPABI.
%   SPM12 New Segment workflow.
%   Applies an SPM12 New Segment deformation field.
%   priorMaskFile - source filename (SPM prior template)
%   OutFile - output filename
%   RefFile - reference file to get the voxsize and bounding box
%   ParameterFile - the parameter for normalization. Usually *seg_inv_sn.mat genereated by T1 image segmentation
%   Interp - interpolation method. 0: Nearest Neighbour. 1: Trilinear.
%__________________________________________________________________________
% Written by YAN Chao-Gan 101010 for DPARSF.
% State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University, China, 100875
% ycg.yan@gmail.com
% Revised by YAN Chao-Gan, 120203. Check if the dimension appropriate. If not (in the case that the RefFile has rotation), then reslice to the same dimension.
% Revised by YAN Chao-Gan, 150706. SPM12 compatible.

if nargin<=4
    Interp=1;
end

% Convert the template to a NIfTI file before normalization.
[SourcePath, SourceFileName, SourceExtn] = fileparts(priorMaskFile);
[Data Head]=y_Read(priorMaskFile);
Head.pinfo = [1;0;0];
y_Write(Data,Head,OutFile);


% YAN Chao-Gan, 120822. No longer write to temp dir
% TempFileName=[tempdir,filesep,SourceFileName,SourceExtn];
% y_Write(Data,Head,TempFileName);

%[ProgramPath, fileN, extn] = fileparts(which('DPARSFA_run.m'));
% [DPABIPath, fileN, extn] = fileparts(which('DPABI.m'));
% ProgramPath=fullfile(DPABIPath, 'DPARSF');
% % [SPMversionText,c]=spm('Ver');
% % SPMversion=str2double(SPMversionText(end-1:end));
% if isnan(SPMversion)
%     SPMversion=str2double(SPMversionText(end));
% end
% 
% SPMJOB = load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
% %load([ProgramPath,filesep,'Jobmats',filesep,'Normalize_Write.mat']);
[mn, mx, voxsize]= y_GetBoundingBox(RefFile);

matlabbatch{1}.spm.spatial.normalise.write.subj.def = {iyParameterFile};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {OutFile};
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [mn;mx];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = voxsize;
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = Interp;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
spm_jobman('run',matlabbatch);


% Check if the dimension appropriate. If not (in the case that the RefFile has rotation), then reslice to the same dimension.
% YAN Chao-Gan, 120203.
[Path, FileName, Extn] = fileparts(OutFile); %[Path, FileName, Extn] = fileparts(TempFileName);
if isempty(Path)
    Path=pwd;
end
[Data Head]=y_Read([Path,filesep,'w',FileName, Extn]);

[RefData,RefVox,RefHeader]=y_ReadRPI(RefFile,1);
if ~isequal(size(Data), size(RefData))
    y_Reslice([Path,filesep,'w',FileName, Extn],[Path,filesep,'rw',FileName, Extn],RefVox,Interp, RefFile);
    [Data Head]=y_Read([Path,filesep,'rw',FileName, Extn]);
    delete([Path,filesep,'rw',FileName, Extn]); % Delete the temp file
end


Head.pinfo = [1;0;0];
y_Write(Data,Head,OutFile);

delete([Path,filesep,'w',FileName, Extn]); % Delete the temp file
