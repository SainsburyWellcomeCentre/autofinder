# autofinder
Test of algorithm to image only a sample and not surrounding tissue using serial-section 2-photon imaging. 
We have over 150 acquisitions, many have multiple samples so in total there are over 300 samples. 
Almost all samples are rat or mouse brains.
Testing proceeds in phases:

* **Phase One** is brains that have few or no obvious problems for the auto-ROI and are 100% expected to work without unusual user intervention.

* **Phase Two** Are samples which are particularly awkward but we would like to get working before moving on to implementing this in BakingTray. Once Phase Two is complete, we move to the BakingTray implementation. Phase Two includes cases where the  laser intensity changed during acquisition, spinal cord acquisitions, low SNR acquisitions. 

* **Phase Three** samples are those where user intervention of some sort is necessary. This includes acquisitions where one or more samples is not visible at all initially. It also includes acquisitions where the sample legitimately vanishes (e.g. PMT switched off due to user error, sample block unglued, etc). 

* **Deferred Samples** are those that we will worry about once everything above worked. e.g. this includes BS data with large numbers of duplicate tiles. Hopefully this can be fixed by Vidrio. 


# Generating pStack files
The command `boundingBoxesFromLastSection.test.runOnStackStruct(pStack)` calculates bounding boxes for 
a whole image stack. 
The input argument `pStack` is a structure which needs to be generated by the user. 
It's a good idea to generate these and store to disk in some reasonable way. 
e.g. Inside sub-directories divided up however makes sense, such as one directory containing all acquisitions of single samples, one with two samples, etc. 
To generate the pStack files do the following


We will work with imaging stacks (`imStack`, below) obtained from the BakingTray preview stacks. 

```
>> nSamples=2;
>> pStack = boundingBoxesFromLastSection.groundTruth.stackToGroundTruth(imStack,'/pathTo/recipeFile',nSamples)

pStack = 

  struct with fields:

               imStack: [1138x2826x192 int16]
                recipe: [1x1 struct]
    voxelSizeInMicrons: 8.1855
     tileSizeInMicrons: 1.0281e+03
              nSamples: 2
             binarized: []
               borders: {}

```

There are two empty fields (`binarized` and `borders`) in the `pStack` structure. 
These need to be populated with what we will treat as a proxy for ground truth: which regions actually contain brain.
This is necessary for subsequent evaluation steps but is not necessary to run the automatic tissue-finding code. 
This is done with:

```
pStack=boundingBoxesFromLastSection.groundTruth.genGroundTruthBorders(pStack,7)
```

And the results visualised with:
```
>> volView(pStack.imStack,[1,200],pStack.borders)  
```

Correct any issues you see by any means necessary. 

# Generating bounding boxes from a stack structure
```
>> OUT=boundingBoxesFromLastSection.test.runOnStackStruct(pStack)
```

Visualise it:
```
>> b={{OUT.BoundingBoxes},{},{}}
>> volView(pStack.imStack,[1,200],b)
```

# Evaluating results
First ensure you have run analyses on all samples. 
Run the test script on one directory:

```
>> boundingBoxesFromLastSection.test.runOnAllInDir('stacks/singleBrains')
```

You can optionally generate a text file that sumarises the results:
```
>> boundingBoxesFromLastSection.test.evaluateDir('tests/191211_1545')
```

To visualise the outcome of one sample:
```
>> load LIC_003_previewStack.mat 
>> load tests/191211_1545/log_LIC_003_previewStack.mat
>> b={{testLog.BoundingBoxes},{},{}};
>> volView(pStack.imStack,[1,200],b);
```

To run on all directories containing sample data within the stacks sub-directory do:
```
>> boundingBoxesFromLastSection.test.runOnAllInDir
```


## How it works
The general idea is that bounding boxes around sample(s) are found in the current section (`n`), expanded by about 200 microns, then applied to section `n+1`. 
When section `n+1` is imaged, the bounding boxes are re-calculated as before.
This approach takes into account the fact that the imaged area of most samples changes during the acquisition. 
Because the acquisition is tiled and we round up to the nearest tile, we usually end up with a border of more than 200 microns. 
In practice, this avoids clipping the sample in cases where it gets larger quickly as we section through it. 
There is likely no need to search for cases where sample edges are clipped in order to add tiles. 
We image rectangular bounding boxes rather than oddly shaped tile patterns because in most cases our tile size is large. 


### Implementation
`imStack` is a downsampled stack that originates from the preview images of a BakingTray serial section 2p acquisition. 
To calculate the bounding boxes for section 11 we would run:
```
boundingBoxesFromLastSection(imStack(:,:,10))
```

The function will return an image of section 10 with the bounding boxes drawn around it. 
It uses default values for a bunch of important parameters, such as pixel size.
Of course in reality these bounding boxes will need to be evaluated with respect to section 11. 
To perform this exploration we can run the algorithm on the whole stack.
To achieve this we load a "pStack" structure, as produced by `boundingBoxesFromLastSection.test.runOnStackStruct`, above. 
Then, as described above, we can run:
```
 boundingBoxesFromLastSection.test.runOnStackStruct(pStack)
```

How does `boundingBoxesFromLastSection` actually give us back the bounding boxes when run the first time (i.e. not in a loop over a stack)? 
It does the following:
* Median filter the stack with a 2D filter
* On the first section, derives a threshold between brain and no-brain by using the median plus a few SDs of the border pixels. 
We can do this because the border pixels will definitely contain no brain the first time around. 
* On the first section we now binarize the image using the above threshold and do some morphological filtering to tidy it up and to expand the border by 200 microns. This is done by the internal function `binarizeImage`. 
* This binarized image is now fed to the internal function `getBoundingBoxes`, which calls `regionProps` to return a bounding box. 
It also: removes very small boxes, provides a hackish fix for the missing corner tile, then sorts the bounding boxes in order of ascending size. 
* Next we use the external function `boundingBoxesFromLastSection.mergeOverlapping` to merge bounding boxes in cases where the is is appropriate. This function is currently problematic as it exhibits some odd behaviours that can cause very large overlaps between bounding boxes. 
* Finally, bounding boxes are expanded to the nearest whole tile and the merging is re-done. 


## Making summaries
`boundingBoxesFromLastSection.test.evaluateBoundingBoxes` works on a stats structure saved by 
`boundingBoxesFromLastSection.test.runOnAllInDir`. We can do the whole test directory with
`boundingBoxesFromLastSection.test.evaluateDir`. 
