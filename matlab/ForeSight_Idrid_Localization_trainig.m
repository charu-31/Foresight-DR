%% ============================================================
% FORESIGHT DR
% IDRiD ML OPTIC DISC + FOVEA LOCALIZATION
% MATLAB R2026a
%
% INPUT:
%   IDRiD original images
%   Optic Disc coordinate CSV
%   Fovea coordinate CSV
%
% OUTPUT:
%   ForeSight_IDRiD_Localization.mat
%
% MODEL OUTPUT:
%   [OpticDisc_X OpticDisc_Y Fovea_X Fovea_Y]
%
% Coordinates are learned as normalized 0-1 values.
%% ============================================================

clear;
clc;
close all;

fprintf('\n');
fprintf('====================================================\n');
fprintf('      FORESIGHT DR - ML LOCALIZATION\n');
fprintf('      OPTIC DISC + FOVEA\n');
fprintf('====================================================\n\n');


%% ============================================================
% STEP 1 - SELECT IDRiD ORIGINAL IMAGES
%% ============================================================

fprintf('STEP 1: Select IDRiD ORIGINAL IMAGES folder\n');

imageFolder = uigetdir(pwd,'Select IDRiD Original Images folder');

if isequal(imageFolder,0)
    error('No image folder selected.');
end

fprintf('Selected image folder:\n%s\n\n',imageFolder);


%% ============================================================
% STEP 2 - SELECT OPTIC DISC CSV
%% ============================================================

fprintf('STEP 2: Select OPTIC DISC coordinate CSV\n');

[odFile,odPath] = uigetfile({'*.csv','CSV Files'}, ...
    'Select IDRiD Optic Disc Center CSV');

if isequal(odFile,0)
    error('Optic Disc CSV not selected.');
end

odCSV = fullfile(odPath,odFile);

OD = readtable(odCSV,'VariableNamingRule','preserve');

fprintf('Optic Disc CSV:\n%s\n\n',odCSV);


%% ============================================================
% STEP 3 - SELECT FOVEA CSV
%% ============================================================

fprintf('STEP 3: Select FOVEA coordinate CSV\n');

[fovFile,fovPath] = uigetfile({'*.csv','CSV Files'}, ...
    'Select IDRiD Fovea Center CSV');

if isequal(fovFile,0)
    error('Fovea CSV not selected.');
end

fovCSV = fullfile(fovPath,fovFile);

FOV = readtable(fovCSV,'VariableNamingRule','preserve');

fprintf('Fovea CSV:\n%s\n\n',fovCSV);


%% ============================================================
% SHOW CSV INFORMATION
%% ============================================================

fprintf('Optic Disc CSV columns:\n');
disp(OD.Properties.VariableNames);

fprintf('Fovea CSV columns:\n');
disp(FOV.Properties.VariableNames);


%% ============================================================
% STEP 4 - FIND IMAGE FILES
%% ============================================================

fprintf('\nSearching for IDRiD images...\n');

imageFiles = dir(fullfile(imageFolder,'*.jpg'));

if isempty(imageFiles)
    imageFiles = dir(fullfile(imageFolder,'*.jpeg'));
end

if isempty(imageFiles)
    imageFiles = dir(fullfile(imageFolder,'*.png'));
end

if isempty(imageFiles)
    error('No images found in the selected folder.');
end

fprintf('Images found: %d\n\n',length(imageFiles));


%% ============================================================
% STEP 5 - READ IMAGE NAMES FROM CSV
%% ============================================================

odNames = string(OD{:,1});
fovNames = string(FOV{:,1});


%% ============================================================
% STEP 6 - PREPARE DATA
%% ============================================================

inputSize = [224 224 3];

maxImages = length(imageFiles);

X = zeros(224,224,3,maxImages,'single');

Y = zeros(maxImages,4,'single');

validCount = 0;


fprintf('====================================================\n');
fprintf('PREPARING LOCALIZATION DATASET\n');
fprintf('====================================================\n\n');


for i = 1:maxImages

    filename = imageFiles(i).name;

    [~,imageID,~] = fileparts(filename);

    fprintf('Processing %d / %d : %s\n', ...
        i,maxImages,filename);


    %% Find matching optic disc row

    odRow = find(contains(odNames,imageID),1);

    %% Find matching fovea row

    fovRow = find(contains(fovNames,imageID),1);


    if isempty(odRow) || isempty(fovRow)

        fprintf('  Skipped - coordinates not found.\n');
        continue;

    end


    %% Read image

    img = imread(fullfile( ...
        imageFiles(i).folder, ...
        filename));


    %% Convert grayscale to RGB

    if ndims(img) == 2

        img = cat(3,img,img,img);

    end


    %% Original dimensions

    imageHeight = size(img,1);
    imageWidth = size(img,2);


    %% Read optic disc coordinates

    odX = double(OD{odRow,2});
    odY = double(OD{odRow,3});


    %% Read fovea coordinates

    fovX = double(FOV{fovRow,2});
    fovY = double(FOV{fovRow,3});


    %% Check coordinates

    if any(isnan([odX odY fovX fovY]))

        fprintf('  Skipped - invalid coordinates.\n');
        continue;

    end


    %% Normalize coordinates

    odX = odX / imageWidth;
    odY = odY / imageHeight;

    fovX = fovX / imageWidth;
    fovY = fovY / imageHeight;


    %% Resize image

    img = imresize(img,[224 224]);

    img = im2single(img);


    %% Store image

    validCount = validCount + 1;

    X(:,:,:,validCount) = img;


    %% Store targets

    Y(validCount,:) = single([ ...
        odX odY fovX fovY]);


end


%% ============================================================
% STEP 7 - REMOVE UNUSED DATA
%% ============================================================

X = X(:,:,:,1:validCount);

Y = Y(1:validCount,:);


fprintf('\n');
fprintf('====================================================\n');
fprintf('DATASET PREPARATION COMPLETE\n');
fprintf('Valid images: %d\n',validCount);
fprintf('====================================================\n');


if validCount < 10

    error(['Too few valid images were found. ' ...
        'Check the selected IDRiD folders and CSV files.']);

end


%% ============================================================
% STEP 8 - TRAIN / VALIDATION SPLIT
%% ============================================================

rng(42);

randomIndices = randperm(validCount);

numTrain = floor(0.80 * validCount);

trainIndices = randomIndices(1:numTrain);

validationIndices = randomIndices(numTrain+1:end);


XTrain = X(:,:,:,trainIndices);

YTrain = Y(trainIndices,:);


XValidation = X(:,:,:,validationIndices);

YValidation = Y(validationIndices,:);


fprintf('\n');
fprintf('Training images   : %d\n',size(XTrain,4));
fprintf('Validation images : %d\n',size(XValidation,4));


%% ============================================================
% STEP 9 - CREATE NETWORK
%% ============================================================

fprintf('\nCreating localization neural network...\n');


layers = [

    imageInputLayer([224 224 3], ...
        'Normalization','zerocenter', ...
        'Name','input')

    convolution2dLayer(7,32, ...
        'Stride',2, ...
        'Padding','same', ...
        'Name','conv1')

    batchNormalizationLayer('Name','bn1')

    reluLayer('Name','relu1')

    maxPooling2dLayer(3, ...
        'Stride',2, ...
        'Padding','same', ...
        'Name','pool1')

    convolution2dLayer(3,64, ...
        'Padding','same', ...
        'Name','conv2')

    batchNormalizationLayer('Name','bn2')

    reluLayer('Name','relu2')

    maxPooling2dLayer(2, ...
        'Stride',2, ...
        'Name','pool2')

    convolution2dLayer(3,128, ...
        'Padding','same', ...
        'Name','conv3')

    batchNormalizationLayer('Name','bn3')

    reluLayer('Name','relu3')

    maxPooling2dLayer(2, ...
        'Stride',2, ...
        'Name','pool3')

    convolution2dLayer(3,256, ...
        'Padding','same', ...
        'Name','conv4')

    batchNormalizationLayer('Name','bn4')

    reluLayer('Name','relu4')

    globalAveragePooling2dLayer('Name','gap')

    fullyConnectedLayer(128,'Name','fc1')

    reluLayer('Name','fc_relu')

    dropoutLayer(0.2,'Name','dropout')

    fullyConnectedLayer(4,'Name','coordinates')

];


net = dlnetwork(layers);


%% ============================================================
% STEP 10 - CREATE TRAINING DATASTORE
%% ============================================================

XTrainDS = arrayDatastore( ...
    XTrain, ...
    'IterationDimension',4);

YTrainDS = arrayDatastore(YTrain);

trainDS = combine(XTrainDS,YTrainDS);


%% ============================================================
% STEP 11 - CREATE VALIDATION DATASTORE
%% ============================================================

XValidationDS = arrayDatastore( ...
    XValidation, ...
    'IterationDimension',4);

YValidationDS = arrayDatastore(YValidation);

validationDS = combine( ...
    XValidationDS, ...
    YValidationDS);


%% ============================================================
% STEP 12 - TRAINING OPTIONS
%% ============================================================

fprintf('\nPreparing training options...\n');


options = trainingOptions('adam', ...
    'InitialLearnRate',1e-4, ...
    'MaxEpochs',25, ...
    'MiniBatchSize',8, ...
    'Shuffle','every-epoch', ...
    'ValidationData',validationDS, ...
    'ValidationFrequency',20, ...
    'Plots','training-progress', ...
    'Verbose',true);


%% ============================================================
% STEP 13 - TRAIN MODEL
%% ============================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('       STARTING ML LOCALIZATION TRAINING\n');
fprintf('====================================================\n\n');

fprintf('The network is learning:\n');
fprintf('1. Optic Disc X\n');
fprintf('2. Optic Disc Y\n');
fprintf('3. Fovea X\n');
fprintf('4. Fovea Y\n\n');


net = trainnet( ...
    trainDS, ...
    net, ...
    'mse', ...
    options);


%% ============================================================
% STEP 14 - SAVE MODEL
%% ============================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('          SAVING LOCALIZATION MODEL\n');
fprintf('====================================================\n');


save( ...
    'ForeSight_IDRiD_Localization.mat', ...
    'net', ...
    'inputSize');


fprintf('\n');
fprintf('MODEL SAVED SUCCESSFULLY!\n');
fprintf('\n');
fprintf('File:\n');
fprintf('ForeSight_IDRiD_Localization.mat\n');


%% ============================================================
% STEP 15 - SELECT TEST IMAGE
%% ============================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('          SELECT TEST FUNDUS IMAGE\n');
fprintf('====================================================\n');


[testFile,testPath] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png','Fundus Images'}, ...
    'Select a test fundus image');


if isequal(testFile,0)

    fprintf('\nNo test image selected.\n');
    return;

end


testImage = imread( ...
    fullfile(testPath,testFile));


%% ============================================================
% STEP 16 - PREPARE TEST IMAGE
%% ============================================================

if ndims(testImage) == 2

    testImage = cat(3, ...
        testImage, ...
        testImage, ...
        testImage);

end


originalHeight = size(testImage,1);

originalWidth = size(testImage,2);


testInput = imresize( ...
    testImage, ...
    [224 224]);


testInput = im2single(testInput);


%% ============================================================
% STEP 17 - PREDICT
%% ============================================================

fprintf('\nRunning ML localization...\n');


prediction = predict( ...
    net, ...
    testInput);


prediction = extractdata(prediction);

prediction = double(prediction);

prediction = prediction(:);


%% Keep coordinates between 0 and 1

prediction = max(0,min(1,prediction));


%% ============================================================
% STEP 18 - CONVERT TO ORIGINAL IMAGE COORDINATES
%% ============================================================

odX = prediction(1) * originalWidth;

odY = prediction(2) * originalHeight;

fovX = prediction(3) * originalWidth;

fovY = prediction(4) * originalHeight;


%% ============================================================
% STEP 19 - DISPLAY RESULT
%% ============================================================

figure('Name','ForeSight DR - ML Localization');


imshow(testImage);

hold on;


%% Optic Disc

plot( ...
    odX, ...
    odY, ...
    'ro', ...
    'MarkerSize',14, ...
    'LineWidth',3);


%% Fovea

plot( ...
    fovX, ...
    fovY, ...
    'go', ...
    'MarkerSize',14, ...
    'LineWidth',3);


%% Labels

text( ...
    odX + 20, ...
    odY, ...
    'OPTIC DISC', ...
    'Color','red', ...
    'FontSize',12, ...
    'FontWeight','bold');


text( ...
    fovX + 20, ...
    fovY, ...
    'FOVEA', ...
    'Color','green', ...
    'FontSize',12, ...
    'FontWeight','bold');


title( ...
    'ForeSight DR - ML Optic Disc + Fovea Localization');


legend( ...
    'Optic Disc', ...
    'Fovea');


hold off;


%% ============================================================
% STEP 20 - DISPLAY NUMERICAL RESULT
%% ============================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('       ML LOCALIZATION COMPLETE\n');
fprintf('====================================================\n');

fprintf('\nTest image: %s\n',testFile);

fprintf('\nPredicted Optic Disc:\n');
fprintf('X = %.1f pixels\n',odX);
fprintf('Y = %.1f pixels\n',odY);

fprintf('\nPredicted Fovea:\n');
fprintf('X = %.1f pixels\n',fovX);
fprintf('Y = %.1f pixels\n',fovY);

fprintf('\n====================================================\n');
fprintf('CSV FILES ARE NO LONGER NEEDED FOR PREDICTION.\n');
fprintf('====================================================\n');