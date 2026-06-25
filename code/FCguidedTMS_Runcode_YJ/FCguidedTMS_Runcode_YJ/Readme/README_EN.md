# FC-Guided TMS Target Calculation Workflow

This package contains a MATLAB workflow for FC-guided TMS target validation and target calculation using SPM and DPABI/DPARSFA.

## Requirements

- MATLAB with SPM12 available on the MATLAB path.
- DPABI/DPARSFA available on the MATLAB path.
- Subject-level resting-state fMRI data prepared in the expected DPARSFA folder structure.
- A T1 image available either in `T1NewSegment` or in `T1Img/<subject_id>`.
- The inverse deformation field `iy*.nii` from SPM New Segment in `T1NewSegment`.

## Files

- `Code/RunCode.m`: Main workflow script.
- `Code/Step1_AR2.mat`: DPARSFA configuration for initial preprocessing.
- `Code/Step2_SCF.mat`: DPARSFA configuration for smoothing, nuisance regression, and filtering.
- `Code/Step3_FC.mat`: DPARSFA configuration for functional connectivity calculation.
- `Code/list_image_files.m`: Helper for listing NIfTI/Analyze image files.
- `Code/normalize_write_to_reference.m`: Helper for applying inverse deformation fields to masks/templates.
- `mask/Left_M1.nii`: Example stimulation target mask in standard space.

## How to Run

1. Add the `Code` folder to the MATLAB path.
2. Open `RunCode.m`.
3. Edit the parameter block at the top of the script:
   - `Startpath`
   - `Subdirname`
   - `T1filename`
   - `TPMpath`
   - `radius`
   - `coordinates`
   - `TimePoints`
   - `TR`
   - `RemoveFirstTimePoints`
4. Run `RunCode.m` in MATLAB.
5. During execution, SPM display windows will appear for manual checks. The window title indicates the current check, such as coregistration or template-to-native-space validation.
6. After each SPM display check, return to the MATLAB command window. When the message `Please check the image in SPM display window. Press any key to continue once checked.` appears, press any key to continue.
7. After the workflow finishes, inspect the FC maps and rank the results to identify the final TMS stimulation target.

## Notes

- The script now resolves the bundled `Step*.mat` files and the `mask` folder relative to this project, so those paths usually do not need to be edited.
- `TPMpath` is still machine-specific and should point to the local SPM12 `TPM.nii` file.
- If `iy*.nii` is missing from `T1NewSegment`, run SPM New Segment first or provide the existing inverse deformation field.
- The workflow expects realigned functional images in `FunImgAR/<subject_id>` after the first DPARSFA step.
- If multiple realigned functional images are found, the current script uses the first file as a 4D image and prints a warning. Confirm that this matches your data format.
