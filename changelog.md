
## Changelog

* v2 Does well with single brains and multiple brains where the individual brains have bounding boxes that are not going to overlap. 
Once bounding boxes overlap we begin to get odd and major failures. 
For instance, whole brains sudenly are excluded. 
An example of this is `threeBrains/AF_C2_2FPPVs_previewStack.mat` with `tThreshSD=4` -- irrespective of threshold we lose the bottom brain from section 17 to section 18. 
The problem lies with `mergeOverlapping`. 
The bounding boxes are correctly found but the merge step produces a bad result when applied to the tile-corrected output.
I believe it is losing a ROI when doing the merge comparisons because it's failing to correctly do comparisons with more than 2 ROIs.

* v3 Fixed issues relating to multiple sample ROIs. 
The main problems were that `mergeOverlapping` was deleteing ROIs and that the final bounding-box generation step had a tendency to merge ROIs that should not have been merged. 

* v4 Corrects the [issue with merge leading to imaging the same brain twice](https://github.com/raacampbell/autofinder/issues/14). 
I then ran the algorithm on all samples and looked at the results. We have the following failure modes that need addressing:
  - Ten acquisitions show mild to moderate failure to image the very posterior part of cortex when it appears. This is very severe in an additional three more: ~~HMV_NN01~~, ~~AL_029~~ and ~~AL023~~.
  - ~~One acquisition shows persistent issues finding all the brain: HMV_OIs04_OIs05. This is potentially serious since we don't know this happens.~~ Fixed 
  - One acquisition (AF_PCA_19_20_22_25) has a brain where we start imaging very caudal indeed. The spinal cord appears before cerebellum and it takes a few sections until cerebellum is imaged. Minor data loss.
  - ~~Two acquisitions show a thresholding issue where the brain is found in section 1 but subsequent ones are empty:~~ ~~AF_4C2s~~ and ~~AF_C2_2FPPVs~~. This would not lead to data loss, only annoyance. Fixed.
  - ~~Two acquisitions suddenly fail to find the tissue mid way through acqisition~~: ~~C2vGvLG1~~ and ~~CC_125_1__125_2~~. This would not lead to data loss, only annoyance. Fixed
  - ~~Two acquisitions of 4 brains each lose one brain because it wasn't visible at the start of the acquisition. Not serious because we can solve this via user intervention before acquisition starts.~~ Phase 2 
  - ~~Two acquisitions fail due to sudden loss of the tissue for whatever reason: sample_972991_972992, FERRET~~. Not a problem with the algorithm. The microscope would just stop and send a Slack message. 
  No data loss due to algorithm. Phase 2 
  - Other thresholding failures include: ~~LUNG_MACRO (bright tissue at edge?)~~ Basically fixed., ~~OI06_OI07 (very little brain found and it just gives up -- faint?)~~ Fixed.

* v5
  - Increasing the border from 100 to 300 microns helps a lot with the posterior cortex failure. Detailed examination pending, but it's positive.
  - The sudden unexpected failures were due to a bug that is now fixed.
  - One of the acquisitions which initially had no brain is now fine after the pixel change: a tiny bit of tissue was present and now crosses threshold. 
  
* v6
Generally pretty good performance. Increased the pool of acquisitions from 65 to about 114. 
Removed one sample where laser power was changed. 
The main thing to sort out now is [whether the evaluation is using the correct borders](https://github.com/raacampbell/autofinder/issues/35). 

* v7
Increase to 127 samples in main pool plus another 25 in the phase 2 pool, which we'll worry about later. 
That includes 7 where there was just one or more samples not visible at the start, 2 where the sample vanishes part way due to an acquisition problem, the eye, and 7 which simply have too many duplicate tiles due to BS with large number of averages.  
What we need to do right now is address the problem with [low SNR acquisitions](https://github.com/raacampbell/autofinder/issues/40).

* v8 and v8.5
Deal with lowSNR acquisitions and also enables the rolling threshold, which sorts out a few other problems. 
The main sticking point now is what to do with brains such as `SW_BY319_2_3_4`, which do badly beuse [the laser power was changed mid-way](https://github.com/raacampbell/autofinder/issues/33) through the acquisition. 
The rolling threshold does not cover this adquately as implemented. Working on the [occluded brain issue](https://github.com/raacampbell/autofinder/issues/33) might help the low laser power. 
In some ways they are related. 

* v9
The major change here is an algorithm to locate tiling in the binarised image and use this to indicate that the threshold is too low. 
This has fixed two cases of rat brains where the whole agar block is being imaged: the autothresh now correctly finds the brain in the block and doesn't draw a border around the agar. 
In the process of doing this, the four samples where we changed laser power a lot just magically work. So that's good. 
However, it turns out that one of the spinal cord samples balloons due to a large laser power increase. This is described in [Issue #50](https://github.com/raacampbell/autofinder/issues/50). 
To fix that, I think we need to first address [Issue #38](https://github.com/raacampbell/autofinder/issues/38), which is that for initially setting the `tThreshSD` based upon ROI edge pixels not FOV edge pixels. 

* v10
All stacks that are needed now pass criteria! We have 133 acquisitions that are acquired perfectly or "good enough". 120 of them lose no more than two or three tiles of tissue. Three of them lose about thirty tiles. We will now move to Phase 3. The first job will be to tidy the code and refactor so it can be incorporated into BT. 

* v11.1
The big clean up starts!. We keep a detailed log of changes here.
In v11.1 we clean up the major and very obvious things, ensuring that output is identical and unchanged to reference. 
17/04/2020
Delete unused functions:
+boundingBoxesFromLastSection/growBoundingBoxIfSampleClipped.m
+boundingBoxesFromLastSection/findROIEdgeClipping.m

Now ./+boundingBoxesFromLastSection/boundingBoxAreaFromImage.m is only called by mergeOverlapping so
we move that to an in-line function and delete the external function file.

Rename getImageStats to getForegroundBackgroundPixels and take out code that calculates things we never need. 
Remove meanForeground and meanBackground stats from boundingBoxesFromLastSection. Never used.
Remove not needed second expansion step in mergeOverlapping and remove the associated setting. 

Improve reporting of evaluation results and fix a bug that was causing the file list to be in the wrong order.

* v11.1
New output structure for functions: se OutputStatistics.md
Rename boundingBoxesFromLastSection to autoROI
Rename evaluateBoundingBoxes to evaluateROIs
Everything now passes the test. At this point we can try integrating this into BT. 
