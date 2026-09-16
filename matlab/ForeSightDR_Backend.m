function result = ForeSightDR_Backend(imagePath)
% ============================================================
%              FORESIGHT DR - MASTER BACKEND
% ============================================================
%
% Modules:
%   1. Diabetic Retinopathy Grading
%   2. Grad-CAM Explainability
%   3. Optic Disc + Fovea Localization
%   4. Retinal Lesion Segmentation
%
% Required files in the SAME folder:
%
%   ForeSightDR_Backend.m
%   ForeSight_IDRiD_ResNet18.mat
%   ForeSight_IDRiD_Localization.mat
%   ForeSight_IDRiD_LesionSegmentation_Accurate.mat
%
% Localization is ML-based.
% CSV files are NOT required.
% ============================================================

clc;

%% ============================================================
% 0. FIND BACKEND FOLDER
% =============================================================

backendFolder = fileparts(mfilename('fullpath'));

if isempty(backendFolder)
    backendFolder = pwd;
end

fprintf('\n============================================\n');
fprintf('        ForeSight DR Backend\n');
fprintf('============================================\n');


%% ============================================================
% 1. SELECT FUNDUS IMAGE
% =============================================================

if nargin < 1 || isempty(imagePath) || ~isfile(imagePath)

    [fileName,filePath] = uigetfile( ...
        {'*.jpg;*.jpeg;*.png;*.tif;*.tiff', ...
        'Fundus Images (*.jpg, *.jpeg, *.png, *.tif, *.tiff)'}, ...
        'Select Fundus Image');

    if isequal(fileName,0)
        error('No fundus image was selected.');
    end

    imagePath = fullfile(filePath,fileName);
end

fprintf('\nInput image:\n%s\n',imagePath);


%% ============================================================
% 2. READ INPUT IMAGE
% =============================================================

originalImage = imread(imagePath);

% Convert grayscale image to RGB
if size(originalImage,3) == 1

    originalImage = cat(3, ...
        originalImage, ...
        originalImage, ...
        originalImage);

end

% Remove alpha channel if present
if size(originalImage,3) > 3

    originalImage = originalImage(:,:,1:3);

end

% Keep an 8-bit version for visualization
originalImage = im2uint8(originalImage);

originalHeight = size(originalImage,1);
originalWidth  = size(originalImage,2);
========================================================
Quality assessment
========================================================
quality = assessQuality(originalImage);

if quality.Status ~= "ACCEPT"
    result.Status = "RECAPTURE";
    result.Message = quality.Message;
    result.Quality = quality;
    return;
end


%% ============================================================
% 3. LOAD DR GRADING MODEL
% =============================================================

fprintf('\n[1/4] Loading DR grading model...\n');

classificationFile = fullfile( ...
    backendFolder, ...
    'ForeSight_IDRiD_ResNet18.mat');

if ~isfile(classificationFile)

    error(['Could not find ', ...
        'ForeSight_IDRiD_ResNet18.mat in the backend folder.']);

end

classificationData = load(classificationFile);

if ~isfield(classificationData,'net')

    error(['ForeSight_IDRiD_ResNet18.mat does not ', ...
        'contain a variable named "net".']);

end

classificationNet = classificationData.net;


%% ============================================================
% 4. DR DISEASE GRADING
% =============================================================

fprintf('[1/4] Predicting diabetic retinopathy grade...\n');

% Resize to the size used during training
classificationImage = ...
    imresize(originalImage,[224 224]);

% IMPORTANT:
% dlnetwork/predict requires numeric floating-point
% input rather than uint8.
classificationImage = ...
    im2single(classificationImage);

% Predict
scores = predict( ...
    classificationNet, ...
    classificationImage);

% Convert dlarray output if necessary
if isa(scores,'dlarray')

    scores = extractdata(scores);

end

scores = double(scores);
scores = scores(:);

% Find highest probability
[confidence,classIndex] = max(scores);

% IDRiD DR classes
%
% 0 = No DR
% 1 = Mild DR
% 2 = Moderate DR
% 3 = Severe DR
% 4 = Proliferative DR

drGrade = classIndex - 1;

% Safety clamp
drGrade = max(0,min(4,drGrade));

drClasses = { ...
    'No DR'
    'Mild DR'
    'Moderate DR'
    'Severe DR'
    'Proliferative DR'
    };

drClass = drClasses{drGrade + 1};

fprintf('\n');
fprintf('   DR Grade    : %d\n',drGrade);
fprintf('   DR Class    : %s\n',drClass);
fprintf('   Confidence  : %.2f%%\n',confidence*100);


%% ============================================================
% 5. GENERATE GRAD-CAM
% =============================================================

fprintf('\n[2/4] Generating Grad-CAM explanation...\n');

try

    % Generate Grad-CAM
    cam = gradCAM( ...
        classificationNet, ...
        classificationImage, ...
        classIndex);

    % Convert dlarray if necessary
    if isa(cam,'dlarray')

        cam = extractdata(cam);

    end

    cam = squeeze(cam);
    cam = double(cam);

    % Normalize CAM
    camMin = min(cam(:));
    camMax = max(cam(:));

    if camMax > camMin

        cam = ...
            (cam - camMin) / (camMax - camMin);

    else

        cam = zeros(size(cam));

    end

    % Resize CAM to original image size
    cam = imresize( ...
        cam, ...
        [originalHeight originalWidth]);

    % Convert CAM into RGB heatmap
    heatmapImage = ind2rgb( ...
        uint8(cam * 255), ...
        jet(256));

    % Convert original image to double
    baseImage = im2double(originalImage);

    % Blend
    alpha = 0.45;

    gradCAMOverlay = ...
        (1-alpha) * baseImage + ...
        alpha * heatmapImage;

    gradCAMOverlay = ...
        im2uint8(gradCAMOverlay);

    % Save image
    gradCAMImagePath = fullfile( ...
        tempdir, ...
        'ForeSight_GradCAM_Result.png');

    imwrite( ...
        gradCAMOverlay, ...
        gradCAMImagePath);

    fprintf('   Grad-CAM generated successfully.\n');

catch ME

    warning( ...
        'Grad-CAM generation failed: %s', ...
        ME.message);

    gradCAMImagePath = '';

end


%% ============================================================
% 6. LOAD ML LOCALIZATION MODEL
% =============================================================

fprintf('\n[3/4] Loading localization model...\n');

localizationFile = fullfile( ...
    backendFolder, ...
    'ForeSight_IDRiD_Localization.mat');

if ~isfile(localizationFile)

    error(['Could not find ', ...
        'ForeSight_IDRiD_Localization.mat in the backend folder.']);

end

localizationData = ...
    load(localizationFile);

if ~isfield(localizationData,'net')

    error(['ForeSight_IDRiD_Localization.mat does not ', ...
        'contain a variable named "net".']);

end

localizationNet = localizationData.net;


%% ============================================================
% 7. OPTIC DISC + FOVEA LOCALIZATION
% =============================================================

fprintf('[3/4] Predicting optic disc and fovea...\n');

% Resize to localization model input size
localizationInput = ...
    imresize(originalImage,[224 224]);

% IMPORTANT:
% Convert uint8 to single for dlnetwork
localizationInput = ...
    im2single(localizationInput);

% Predict
localizationPrediction = ...
    predict( ...
        localizationNet, ...
        localizationInput);

% Convert dlarray if necessary
if isa(localizationPrediction,'dlarray')

    localizationPrediction = ...
        extractdata(localizationPrediction);

end

localizationPrediction = ...
    double(localizationPrediction(:));

% The model should return:
%
% [opticDiscX opticDiscY foveaX foveaY]
%
% Coordinates are normalized from 0 to 1.

if numel(localizationPrediction) < 4

    error(['Localization model returned fewer than ', ...
        '4 coordinate values.']);

end

opticDiscX_norm = ...
    localizationPrediction(1);

opticDiscY_norm = ...
    localizationPrediction(2);

foveaX_norm = ...
    localizationPrediction(3);

foveaY_norm = ...
    localizationPrediction(4);


%% ============================================================
% 8. KEEP COORDINATES INSIDE IMAGE
% =============================================================

opticDiscX_norm = ...
    max(0,min(1,opticDiscX_norm));

opticDiscY_norm = ...
    max(0,min(1,opticDiscY_norm));

foveaX_norm = ...
    max(0,min(1,foveaX_norm));

foveaY_norm = ...
    max(0,min(1,foveaY_norm));


%% ============================================================
% 9. CONVERT NORMALIZED COORDINATES
%    TO ORIGINAL IMAGE COORDINATES
% =============================================================

opticDiscX = ...
    opticDiscX_norm * originalWidth;

opticDiscY = ...
    opticDiscY_norm * originalHeight;

foveaX = ...
    foveaX_norm * originalWidth;

foveaY = ...
    foveaY_norm * originalHeight;

opticDisc = ...
    [opticDiscX opticDiscY];

fovea = ...
    [foveaX foveaY];

fprintf('\n');
fprintf('   Optic Disc : (%.1f, %.1f)\n', ...
    opticDiscX,opticDiscY);

fprintf('   Fovea      : (%.1f, %.1f)\n', ...
    foveaX,foveaY);


%% ============================================================
% 10. CREATE LOCALIZATION IMAGE
% =============================================================

localizationFigure = figure( ...
    'Visible','off', ...
    'Color','white');

imshow(originalImage);

hold on;

% Optic disc = RED
plot( ...
    opticDiscX, ...
    opticDiscY, ...
    'ro', ...
    'MarkerSize',14, ...
    'LineWidth',3);

% Fovea = GREEN
plot( ...
    foveaX, ...
    foveaY, ...
    'go', ...
    'MarkerSize',14, ...
    'LineWidth',3);

% Optic disc label
text( ...
    opticDiscX + 10, ...
    opticDiscY, ...
    'Optic Disc', ...
    'Color','red', ...
    'FontSize',12, ...
    'FontWeight','bold');

% Fovea label
text( ...
    foveaX + 10, ...
    foveaY, ...
    'Fovea', ...
    'Color','green', ...
    'FontSize',12, ...
    'FontWeight','bold');

title( ...
    'ForeSight DR - Optic Disc and Fovea Localization');

hold off;

localizationImagePath = fullfile( ...
    tempdir, ...
    'ForeSight_Localization_Result.png');

exportgraphics( ...
    localizationFigure, ...
    localizationImagePath);

close(localizationFigure);

fprintf('   Localization image generated successfully.\n');


%% ============================================================
% 11. LOAD LESION SEGMENTATION MODEL
% =============================================================

fprintf('\n[4/4] Loading lesion segmentation models...\n');

segmentationFile = fullfile( ...
    backendFolder, ...
    'ForeSight_IDRiD_LesionSegmentation.mat');

if ~isfile(segmentationFile)
    segmentationFile = fullfile( ...
        backendFolder, ...
        'ForeSight_IDRiD_LesionSegmentation_Accurate.mat');
end

if ~isfile(segmentationFile)
    error('Could not find lesion segmentation MAT file in backend folder.');
end

segmentationData = load(segmentationFile);


%% ============================================================
% 12. PREPARE IMAGE FOR LESION SEGMENTATION
% =============================================================

segmentationImage = imresize(originalImage,[384 384]);

% Mild enhancement using green channel
greenChannel = segmentationImage(:,:,2);

try
    greenChannel = adapthisteq( ...
        greenChannel, ...
        'ClipLimit',0.01);
catch
    % If adapthisteq is unavailable, continue without enhancement.
end

segmentationImage(:,:,2) = greenChannel;


%% ============================================================
% 13. LESION SEGMENTATION
% =============================================================

fprintf('[4/4] Detecting retinal lesions...\n');

lesionNames = { ...
    'Microaneurysm'
    'Haemorrhage'
    'Hard Exudate'
    'Soft Exudate'
    };

lesionMasks = cell(4,1);
lesionCounts = zeros(4,1);

if isfield(segmentationData, 'net')
    try
        classes = ["background", "Microaneurysm", "Haemorrhage", "HardExudate", "SoftExudate"];
        predMask = semanticseg(segmentationImage, segmentationData.net, 'Classes', classes);
        
        targetClasses = ["Microaneurysm", "Haemorrhage", "HardExudate", "SoftExudate"];
        for k = 1:4
            maskK = (predMask == targetClasses(k));
            maskK = imresize(maskK, [originalHeight originalWidth], 'nearest');
            lesionMasks{k} = maskK;
            lesionCounts(k) = nnz(maskK);
        end
    catch ME
        warning('Multi-class segmentation failed: %s', ME.message);
        for k = 1:4
            lesionMasks{k} = false(originalHeight, originalWidth);
            lesionCounts(k) = 0;
        end
    end
elseif isfield(segmentationData, 'models')
    models = segmentationData.models;
    for k = 1:4
        fprintf('   Detecting %s...\n', lesionNames{k});
        try
            currentMask = semanticseg(segmentationImage, models{k});
            currentMask = currentMask ~= categorical("background");
            currentMask = logical(currentMask);
            currentMask = imresize(currentMask, [originalHeight originalWidth], 'nearest');
            lesionMasks{k} = currentMask;
            lesionCounts(k) = nnz(currentMask);
        catch ME
            warning('Segmentation failed for %s: %s', lesionNames{k}, ME.message);
            lesionMasks{k} = false(originalHeight, originalWidth);
            lesionCounts(k) = 0;
        end
    end
else
    error('Segmentation MAT file does not contain "net" or "models".');
end


%% ============================================================
% 14. CREATE LESION OVERLAY
% =============================================================

fprintf('   Creating lesion overlay...\n');

baseImage = ...
    im2double(originalImage);

overlayImage = baseImage;

% Colors:
%
% Microaneurysm = RED
% Haemorrhage   = BLUE
% Hard Exudate  = YELLOW
% Soft Exudate  = MAGENTA

lesionColors = { ...
    [1 0 0]
    [0 0 1]
    [1 1 0]
    [1 0 1]
    };

alpha = 0.45;


for k = 1:4

    mask = lesionMasks{k};

    if any(mask(:))

        currentColor = ...
            lesionColors{k};

        for c = 1:3

            channel = ...
                overlayImage(:,:,c);

            channel(mask) = ...
                (1-alpha) * channel(mask) + ...
                alpha * currentColor(c);

            overlayImage(:,:,c) = ...
                channel;

        end

    end

end


%% ============================================================
% 15. SAVE LESION OVERLAY
% =============================================================

overlayImage = ...
    im2uint8(overlayImage);

lesionOverlayPath = fullfile( ...
    tempdir, ...
    'ForeSight_Lesion_Overlay.png');

imwrite( ...
    overlayImage, ...
    lesionOverlayPath);

fprintf('   Lesion overlay generated successfully.\n');




%% ============================================================
% 16. CREATE FINAL RESULT STRUCTURE
% =============================================================

result = struct();


% ---- DR grading ----
result.drGrade = ...
    drGrade;

result.drClass = ...
    drClass;

result.confidence = ...
    confidence;


% ---- Grad-CAM ----
result.gradCAMImage = ...
    gradCAMImagePath;


% ---- Localization ----
result.localizationImage = ...
    localizationImagePath;

result.opticDisc = ...
    opticDisc;

result.fovea = ...
    fovea;


% ---- Lesion segmentation ----
result.lesionOverlay = ...
    lesionOverlayPath;

result.lesionCounts = ...
    lesionCounts;

result.lesionNames = ...
    lesionNames;


% ---- Input ----
result.imagePath = ...
    imagePath;

result.Status = "SCREENED";
result.Message = "Image successfully screened.";
result.Quality = quality;


%% ============================================================
% 17. FINAL SUMMARY
% =============================================================

fprintf('\n============================================\n');
fprintf('       FORESIGHT DR ANALYSIS COMPLETE\n');
fprintf('============================================\n');

fprintf('\nDISEASE GRADING\n');

fprintf('Grade      : %d\n',drGrade);

fprintf('Class      : %s\n',drClass);

fprintf('Confidence : %.2f%%\n', ...
    confidence*100);


fprintf('\nLOCALIZATION\n');

fprintf('Optic Disc : (%.1f, %.1f)\n', ...
    opticDiscX,opticDiscY);

fprintf('Fovea      : (%.1f, %.1f)\n', ...
    foveaX,foveaY);


fprintf('\nLESION PIXEL COUNTS\n');

for k = 1:4

    fprintf( ...
        '%-20s : %d\n', ...
        lesionNames{k}, ...
        lesionCounts(k));

end


fprintf('\n============================================\n');
fprintf('Backend completed successfully.\n');
fprintf('============================================\n');

end