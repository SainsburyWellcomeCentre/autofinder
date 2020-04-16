# Output Statistics
This document describes the output structures and descriptive statistics produced by this package. 


## boundingBoxesFromLastSection
Returns a structure with the following fields


`BoundingBoxes` - A cell array of bounding boxes in the form: is [x y width height]. 
`BoundingBox` - Used by runOnStackStruct (NOT SURE WHY)
`notes` - An optional string for keeping observations
`tThresh` - Absolute threshold used for computing the binary image

`origPixelSize` - Number of microns per pixel of the original image
`rescaledPixelSize` - Number of microns per pixel of the downsampled image used for the analysis
`rescaledRatio` - origPixelSize/rescaleTo
`imSize` - The full size of the image in which the ROIs were found. Reflects downsampling.




 
`BoundingBoxSqMM` - A vector of length(BoundingBoxes) listing the sq mm of each bounding box.
`meanBoundingBoxSqMM` - mean of all bounding box areas: `mean(out.BoundingBoxSqMM)`
`totalBoundingBoxSqMM` - Sum of all bounding box areas: `sum(out.BoundingBoxSqMM)`
`propImagedAreaCoveredByBoundingBox` - The proportion of the original FOV covered by bounding boxes.


