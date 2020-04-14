function settings = readSettings(readFromYaml)
% Read settings (from yaml if desired


if nargin<1
    readFromYaml=false;
end


if readFromYaml
    % Look for file
    settingsFname = fullfile( fileparts(mfilename('fullpath')), 'settings.yml');

    if exist(settingsFname,'file')
        settings = yaml.ReadYaml(settingsFname);
    end

    if ~isempty(settings)
        return
    else
        % read defaults and write to file
        settings = returnSettings;
        yaml.WriteYaml(settingsFname,settings);
    end
else
    settings = returnSettings;
end




function settings = returnSettings
    % The following are used in boundingBoxesFromLastSection
    settings.main.medFiltRawImage = 5; 
    settings.main.doTiledMerge=true; %Mainly for debugging
    settings.main.tiledMergeThresh=1.05;
    settings.main.secondExpansion=false;
    settings.main.defaultThreshSD=7; %This appears both in boundingBoxesFromLastSection and in runOnStackStruct

    % The following are used in boundingBoxesFromLastSection > binarizeImage
    settings.mainBin.removeNoise = true; % Noise removal: targets electrical noise
    settings.mainBin.medFiltBW = 5;
    settings.mainBin.primaryShape = 'disk';
    settings.mainBin.primaryFiltSize = 50; %in microns
    settings.mainBin.expansionShape = 'square';
    settings.mainBin.doExpansion = true; % Expand binarized image 
    settings.mainBin.expansionSize = 600;  %in microns

    % The following are used in boundingBoxesFromLastSection > getBoundingBoxes
    settings.mainGetBB.minSizeInSqMicrons = 15000;


    % The following are used in boundingBoxesFromLastSection.mergeOverlapping
    settings.mergeO.mergeThresh=1.3; %This is the default value

    % The following are used in boundingBoxesFromLastSection.runOnStackStruct
    settings.stackStr.rescaleTo=50; 


    settings.autoThresh.skipMergeNROIThresh=10;
    settings.autoThresh.doBinaryExpansion=false;
    settings.autoThresh.minThreshold=2;
    settings.autoThresh.maxThreshold=15;
    settings.autoThresh.decreaseThresholdBy=0.85;