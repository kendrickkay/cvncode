function cvnalignEPItoT1(subjectid,outputdir,meanfunctional,mcmask,wantaffine,tr)

% function cvnalignEPItoT1(subjectid,outputdir,meanfunctional,mcmask,wantaffine,tr)
%
% <subjectid> is like 'C0001'
% <outputdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/freesurferalignment'
% <meanfunctional> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocess/mean.nii'
% <mcmask> (optional) is {mn sd} with the mn and sd outputs of defineellipse3d.m.
%   If [] or not supplied, we prompt the user to determine these with the GUI.
% <wantaffine> (optional) is whether to use affine (instead of rigid-body). Default: 0.
% <tr> (optional) is the starting point to use. Default is to use a built-in default.
% <forcemanual> (optional) force the function to write out manual alignment
% only, disabling auto alignment.
%
% Perform alignment of the <meanfunctional> to the T1 anatomy. In the alignment, there is a pause for the 
% user to inspect and modify the ellipse mask that is placed on the <meanfunctional>.
% The ellipse should focus on cortex and it is okay to leave some air around the brain.
% After that, there is a pause for the user to get a rough initial seed for the alignment.
%
% Registration is automatically performed using a rigid-body (or affine) transformation
% and a mutual information metric (this is necessary due to the differring 
% tissue contrast of T1 vs EPI. Note that there is an initial guess for the 
% alignment, and this may need to be revisited as the need arises.
%
% Note that when the user is setting up the initial seed, if the user sets the variable
% wantmanual=1, then the auto-alignment will be skipped when dbcont is issued.
%
% Alignment parameters ('tr', 'T') and 'mcmask' are saved to alignment.mat in <outputdir>.
% Diagnostic images of the alignment quality are written to <outputdir>.
% We also write out EPIalignedtoT1.nii.gz to <outputdir>. This is the mean functional
%   that has been resliced to match the T1 (and saved using the T1 as a template).
%
% history:
% - 2017/11/18 - New version that works for T1 only without T2 images (generated by CR)
%                New default alignment seed values entered. These are optimized for Nova 1x32k 2mm
%                whole brain protocol

% input
if ~exist('mcmask','var') || isempty(mcmask)
  mcmask = [];
end
if ~exist('wantaffine','var') || isempty(wantaffine)
  wantaffine = 0;
end
if ~exist('tr','var') || isempty(tr)
  tr = [];
end
if ~exist('forcemanual','var') || isempty(forcemanual)
  forcemanual = 0;
end

% make directory
mkdirquiet(outputdir);

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);

% load the T1 anatomy
vol1orig = load_untouch_nii(gunziptemp(t1nifti));
vol1size = vol1orig.hdr.dime.pixdim(2:4);
vol1 = double(vol1orig.img);
vol1(isnan(vol1)) = 0;
vol1 = fstoint(vol1);  % this is necessary to get the surfaces to match the anatomy
fprintf('vol1 has dimensions %s at %s mm.\n',mat2str(size(vol1)),mat2str(vol1size));

% load the mean functional
vol2orig = load_untouch_nii(gunziptemp(meanfunctional));
vol2size = vol2orig.hdr.dime.pixdim(2:4);
vol2 = double(vol2orig.img);
vol2(isnan(vol2)) = 0;
fprintf('vol2 has dimensions %s at %s mm.\n',mat2str(size(vol2)),mat2str(vol2size));

% manually define ellipse to be used in the auto alignment
if isempty(mcmask)
  [f,mn,sd] = defineellipse3d(vol2);
  mcmask = {eval(mat2str(mn,6)) eval(mat2str(sd,6))};
  fprintf('mcmask = %s;\n',cell2str(mcmask));
else
  mn = mcmask{1};
  sd = mcmask{2};
end

% deal with default tr
if isempty(tr)
  tr = maketransformation([0 0 0],[1 2 3],[124 120 132],[1 2 3],[0 0 90],size(vol2),size(vol2).*vol2size,[-1 1 1],[0 0 0],[0 0 0],[0 0 0]);
end

% start the alignment
alignvolumedata(vol1,vol1size,vol2,vol2size,tr);

% pause to do some manual alignment (to get a reasonable starting point)
clear wantmanual;
keyboard;
tr = alignvolumedata_exporttransformation;  % report to the user to save just in case

% if the user sets wantmanual to 1, then we will stop instead of proceeding with auto-alignment!

% well, if the user wanted manual alignment, let it through
if exist('wantmanual','var') && wantmanual

  % do nothing

% otherwise, do auto-alignment
else  

  % auto-align (mutual information)
  if wantaffine
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4],[],[],[],1);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[4 4 4],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2],[],[],[],1);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 2],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
  else
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
  end

  % record transformation
  tr = alignvolumedata_exporttransformation;

end

% convert the transformation to a matrix
T = transformationtomatrix(tr,0,vol1size);
fprintf('T=%s;\n',mat2str(T));

% write tr and T to a .mat file
save(sprintf('%s/alignment.mat',outputdir),'tr','T','mcmask');

% get slices from T1 to match EPI
anatmatch1 = extractslices(vol1,vol1size,vol2,vol2size,tr);

% get slices from EPI to match T1
epimatch =   extractslices(vol1,vol1size,vol2,vol2size,tr,1);

% inspect the alignment
makeimagestack3dfiles(vol2,              sprintf('%s/epi', outputdir),[2 2 2],[0 0 -1],[],1);
makeimagestack3dfiles(anatmatch1,        sprintf('%s/anat',outputdir),[2 2 2],[0 0 -1],[],1);
makeimagestack3dfiles(inttofs(epimatch), sprintf('%s/epimatchedtoT1',outputdir),[5 5 5],[-1 1 0],[],1);

% save NIFTI file (EPI matched to the T1)
vol1orig.img = inttofs(cast(epimatch,class(vol1orig.img)));
file0 = sprintf('%s/EPIalignedtoT1.nii',outputdir);
save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);

% save NIFTI file (T1 matched to the EPI)
vol2orig.img = cast(anatmatch1,class(vol2orig.img));
file0 = sprintf('%s/T1alignedtoEPI.nii',outputdir);
save_untouch_nii(vol2orig,file0); gzip(file0); delete(file0);

%%%%%%%%%%%%%%%%%%%%%%%% JUNK:

% temp = imresizedifferentfov(vol2,vol2size(1:2),sizefull(vol2,2),vol2size(1:2));