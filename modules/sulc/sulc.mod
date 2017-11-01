#!/usr/bin/env bash

###################################################################
#   ✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡   #
###################################################################

###################################################################
# SPECIFIC MODULE HEADER
# This module computes a basic sulcal depth estimate.
###################################################################
mod_name_short=sulc
mod_name='SULCAL DEPTH MODULE'
mod_head=${XCPEDIR}/core/CONSOLE_MODULE_AFGR

###################################################################
# GENERAL MODULE HEADER
###################################################################
source ${XCPEDIR}/core/constants
source ${XCPEDIR}/core/functions/library.sh
source ${XCPEDIR}/core/parseArgsMod

###################################################################
# MODULE COMPLETION
###################################################################
completion() {
   source ${XCPEDIR}/core/auditComplete
   source ${XCPEDIR}/core/updateQuality
   source ${XCPEDIR}/core/moduleEnd
}





###################################################################
# OUTPUTS
###################################################################
define         sulcalDepth          ${outdir}/${prefix}_sulcalDepth

derivative     sulcalDepthOuter     ${prefix}_sulcalDepthOuter
derivative     sulcalDepthInner     ${prefix}_sulcalDepthInner

derivative_set sulcalDepthOuter     Statistic        mean
derivative_set sulcalDepthInner     Statistic        mean

require image mask
require image segmentation

<<DICTIONARY

sulcalDepth
   The voxelwise map of sulcal depth values.

DICTIONARY










if ! is_image ${sulcalDepth[cxt]}
   then
   ################################################################
   # Determine whether a MICCAI/OASIS parcellation is available for
   # the current subject. If it is, use this as the basis for
   # sulcal depth estimation. Otherwise, warp hemispheric masks
   # backwards from MNI.
   ################################################################
   atlas_parse miccai
   if is_image ${a[Map]}
      then
      hemisphere_args="-l ${a[Map]}"
   else
      warpspace ${BRAINSPACE}/MNI/MNI-1x1x1LeftHemisphere.nii.gz \
         ${intermediate}-lh.nii.gz \
         MNI:${space[sub]} \
         NearestNeighbor
      warpspace ${BRAINSPACE}/MNI/MNI-1x1x1RightHemisphere.nii.gz \
         ${intermediate}-rh.nii.gz \
         MNI:${space[sub]} \
         NearestNeighbor
      hemisphere_args="-h ${intermediate}-lh.nii.gz -r ${intermediate}-rh.nii.gz"
   fi
   ################################################################
   # Compute mean distance from the convex hull / dural surface. In
   # this prototype, we approximate the convex hull as the brain
   # mask. Then intersect mean distance with the GM edge based on
   # the segmentation.
   ################################################################
   exec_xcp    val2mask.R              \
      -i       ${segmentation[cxt]}    \
      -v       ${sulc_gm_val[cxt]}     \
      -o       ${intermediate}-gm-mask.nii.gz
   exec_xcp    val2mask.R              \
      -i       ${segmentation[cxt]}    \
      -v       ${sulc_wm_val[cxt]}     \
      -o       ${intermediate}-wm-mask.nii.gz
   exec_xcp    sulcalDepth             \
      ${hemisphere_args}               \
      -g       ${intermediate}-gm-mask.nii.gz \
      -w       ${intermediate}-wm-mask.nii.gz \
      -i       ${intermediate}         \
      -o       ${sulcalDepth[cxt]}
fi





completion
