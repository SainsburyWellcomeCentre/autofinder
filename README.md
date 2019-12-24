# autofinder
Test of algorithm to image only a sample and not surrounding tissue using serial-section 2-photon imaging. 


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
>> pStack = boundingBoxesFromLastSection.test.stackToGroundTruth(imStack,'/pathTo/recipeFile',nSamples)

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
The is necessary for subsequent evaluation steps but is not necessary to run the automatic tissue-finding code. 
This is done with:

```
pStack=boundingBoxesFromLastSection.test.genGroundTruthBorders(pStack,7)
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
