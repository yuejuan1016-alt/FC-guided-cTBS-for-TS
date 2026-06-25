function A_imagelist = list_image_files(Pathname,filter_feature)
%-----------------------------------------------------------
% Return image filenames under Pathname that match the optional prefix filter.
% Supported formats: .nii, .nii.gz, and .img.
% Adapted from RESTplus-style image list helpers.

if nargin<= 1
    filter_feature = '';
end

nii_list = {dir([Pathname,filesep,[filter_feature '*.nii']])};
nii_list = {nii_list{1}(:).name};
niigz_list = {dir([Pathname,filesep,[filter_feature '*.nii.gz']])};
niigz_list = {niigz_list{1}(:).name};
img_list = {dir([Pathname,filesep,[filter_feature '*.img']])};
img_list = {img_list{1}(:).name};


if isempty(nii_list)&&isempty(niigz_list)&& ...
   isempty(img_list)
   A_imagelist = {};  
elseif ~isempty(nii_list)
    A_imagelist = nii_list;
elseif ~isempty(img_list)
    A_imagelist = img_list;
elseif ~isempty(niigz_list)
    A_imagelist = niigz_list;
else
    warning('no brain image');
end

end
