function result = ForeSightDR_Backend(imagePath, opticDiscCSV, foveaCSV)
% ForeSightDR_Backend
% Complete backend for ForeSight DR
%
% Input:
%   imagePath     - path to fundus image
%   opticDiscCSV  - IDRiD optic disc CSV
%   foveaCSV      - IDRiD fovea CSV
%
% Output:
%   result        - structure containing DR grading, Grad-CAM,
%                   localization and lesion segmentation

clc;

%% ============================================================
% 1. SELECT IMAGE IF NO VALID IMAGE PATH IS PROVIDED
% =============================================================

if nargin < 1 || isempty(imagePath) || ~isfile(imagePath)

    [imageFile, imageFolder] = uigetfile( ...
        {'*.jpg;*.jpeg;*.png;*.JPG;*.JPEG;*.PNG', ...
        'Fundus Images'}, ...
        'Select Fundus Image');

    if isequal(imageFile, 0)
        error('No fundus image was selected.');
    end

    imagePath = fullfile(imageFolder, imageFile);
end

% Final safety check
if ~ischar(imagePath) && ~isstring(imagePath)
    error('Invalid image path.');
end

imagePath = char(imagePath);

if ~isfile(imagePath)
    error('Image file does not exist: %s', imagePath);
end

fprintf('\n========================================\n');
fprintf('       FORE SIGHT DR BACKEND\n');
fprintf('========================================\n');
fprintf('Image: %s\n\n', imagePath);


%% ============================================================
% 2. READ ORIGINAL IMAGE
% =============================================================

originalImage = imread(imagePath);

if size(originalImage,3) == 1
    originalImage = repmat(originalImage,[1 1 3]);
end

fprintf('Image loaded successfully.\n');


%% ============================================================
% 3. LOAD DR GRADING MODEL
% =============================================================

gradingModelFile = 'ForeSight_IDRiD_ResNet18.mat';

if ~isfile(gradingModelFile)
    error(['Cannot find %s. Make sure the trained DR grading ', ...
        'model is in the current MATLAB folder.'], gradingModelFile);
end

gradingData = load(gradingModelFile);

if ~isfield(gradingData,'net')
    error('The grading MAT file does not contain a variable named "net".');
end

classificationNet = gradingData.net;

fprintf('DR grading model loaded.\n');


%% ============================================================
% 4. PREPARE IMAGE FOR RESNET-18
% =============================================================

classificationImage = imresize(originalImage,[224 224]);

% Convert to single
classificationImage = im2single(classificationImage);


%% ============================================================
% 5. DR DISEASE GRADING
% =============================================================

fprintf('\nRunning DR grading...\n');

% Get prediction scores
scores = predict(classificationNet, classificationImage);

% Convert scores to a normal numeric array
scores = extractdata(scores);

scores = double(scores);

% Find highest probability
[confidence, classIndex] = max(scores(:));

% IDRiD DR grades are 0,1,2,3,4
drGrade = classIndex - 1;

% Keep grade within valid range
drGrade = max(0,min(4,drGrade));

fprintf('Predicted DR Grade: %d\n',drGrade);
fprintf('Confidence: %.2f%%\n',confidence*100);

%% ============================================================
% 6. DR CLASS NAME
% =============================================================

switch drGrade

    case 0
        drClass = 'No DR';

    case 1
        drClass = 'Mild DR';

    case 2
        drClass = 'Moderate DR';

    case 3
        drClass = 'Severe DR';

    case 4
        drClass = 'Proliferative DR';

    otherwise
        drClass = 'Unknown';

end

fprintf('DR Classification: %s\n',drClass);


%% ============================================================
% 7. GRAD-CAM
% =============================================================

fprintf('\nGenerating Grad-CAM explanation...\n');

gradCAMImage = '';

try

    % Use predicted class index
    classIndex = double(predictedClass);

    if isempty(classIndex) || classIndex < 1
        classIndex = drGrade + 1;
    end

    cam = gradCAM( ...
        classificationNet, ...
        classificationImage, ...
        classIndex);

    % Normalize CAM
    cam = mat2gray(cam);

    % Resize CAM to original image size
    cam = imresize(cam,[size(originalImage,1) size(originalImage,2)]);

    % Create figure
    fig = figure('Visible','off');

    imshow(originalImage);
    hold on;

    imagesc(cam);
    colormap jet;
    colorbar;

    alphaData = cam * 0.5;
    set(findobj(gca,'Type','Image'),'AlphaData',alphaData);

    title('ForeSight DR - Grad-CAM Explanation');

    hold off;

    gradCAMImage = fullfile( ...
        tempdir, ...
        'ForeSight_GradCAM_Result.png');

    exportgraphics(fig,gradCAMImage);

    close(fig);

    fprintf('Grad-CAM generated.\n');

catch ME

    warning('Grad-CAM could not be generated: %s',ME.message);

end


%% ============================================================
% 8. LOCALIZATION
% =============================================================

localizationImage = '';

opticDisc = [];
fovea = [];

fprintf('\nRunning optic disc / fovea localization...\n');

% If CSV files were not provided, ask the user
if nargin < 2 || isempty(opticDiscCSV) || ~isfile(opticDiscCSV)

    [file,path] = uigetfile('*.csv', ...
        'Select Optic Disc CSV');

    if ~isequal(file,0)
        opticDiscCSV = fullfile(path,file);
    end

end

if nargin < 3 || isempty(foveaCSV) || ~isfile(foveaCSV)

    [file,path] = uigetfile('*.csv', ...
        'Select Fovea CSV');

    if ~isequal(file,0)
        foveaCSV = fullfile(path,file);
    end

end


%% Find image ID

[~,imageName,~] = fileparts(imagePath);

% Remove common suffixes if present
imageID = imageName;

fprintf('Searching localization data for: %s\n',imageID);


%% Read optic disc CSV

if ~isempty(opticDiscCSV) && isfile(opticDiscCSV)

    try

        OD = readtable(opticDiscCSV);

        % Search rows for image ID
        row = find( ...
            contains(string(OD{:,1}),imageID, ...
            'IgnoreCase',true),1);

        if ~isempty(row)

            opticDisc = [ ...
                double(OD{row,2}), ...
                double(OD{row,3})];

            fprintf('Optic disc found: X=%g Y=%g\n', ...
                opticDisc(1),opticDisc(2));

        else

            warning('Image ID not found in optic disc CSV.');

        end

    catch ME

        warning('Could not read optic disc CSV: %s',ME.message);

    end

end


%% Read fovea CSV

if ~isempty(foveaCSV) && isfile(foveaCSV)

    try

        FOV = readtable(foveaCSV);

        row = find( ...
            contains(string(FOV{:,1}),imageID, ...
            'IgnoreCase',true),1);

        if ~isempty(row)

            fovea = [ ...
                double(FOV{row,2}), ...
                double(FOV{row,3})];

            fprintf('Fovea found: X=%g Y=%g\n', ...
                fovea(1),fovea(2));

        else

            warning('Image ID not found in fovea CSV.');

        end

    catch ME

        warning('Could not read fovea CSV: %s',ME.message);

    end

end


%% Create localization image

if ~isempty(opticDisc) || ~isempty(fovea)

    fig = figure('Visible','off');

    imshow(originalImage);
    hold on;

    % Scale coordinates from original IDRiD image
    % to current image size if necessary

    originalHeight = size(originalImage,1);
    originalWidth  = size(originalImage,2);

    if ~isempty(opticDisc)

        plot( ...
            opticDisc(1), ...
            opticDisc(2), ...
            'ro', ...
            'MarkerSize',12, ...
            'LineWidth',2);

        text( ...
            opticDisc(1)+10, ...
            opticDisc(2), ...
            'Optic Disc', ...
            'Color','red', ...
            'FontSize',12, ...
            'FontWeight','bold');

    end


    if ~isempty(fovea)

        plot( ...
            fovea(1), ...
            fovea(2), ...
            'go', ...
            'MarkerSize',12, ...
            'LineWidth',2);

        text( ...
            fovea(1)+10, ...
            fovea(2), ...
            'Fovea', ...
            'Color','green', ...
            'FontSize',12, ...
            'FontWeight','bold');

    end

    title('ForeSight DR - Optic Disc & Fovea Localization');

    hold off;

    localizationImage = fullfile( ...
        tempdir, ...
        'ForeSight_Localization_Result.png');

    exportgraphics(fig,localizationImage);

    close(fig);

    fprintf('Localization image generated.\n');

else

    fprintf('Localization coordinates unavailable.\n');

end


%% ============================================================
% 9. LOAD LESION SEGMENTATION MODELS
% =============================================================

fprintf('\nLoading lesion segmentation models...\n');

segmentationModelFile = ...
    'ForeSight_IDRiD_LesionSegmentation_Accurate.mat';

if ~isfile(segmentationModelFile)

    error(['Cannot find %s. Make sure the trained ', ...
        'lesion segmentation model is in the MATLAB folder.'], ...
        segmentationModelFile);

end

segData = load(segmentationModelFile);

if ~isfield(segData,'models')

    error(['The lesion segmentation MAT file does not ', ...
        'contain the variable "models".']);

end

models = segData.models;

fprintf('Lesion segmentation models loaded.\n');


%% ============================================================
% 10. PREPROCESS IMAGE FOR SEGMENTATION
% =============================================================

fprintf('\nPreparing image for lesion segmentation...\n');

segImage = preprocessForSegmentation(originalImage);

fprintf('Segmentation image prepared: %dx%d\n', ...
    size(segImage,1),size(segImage,2));


%% ============================================================
% 11. LESION SEGMENTATION
% =============================================================

lesionNames = { ...
    'Microaneurysm', ...
    'Haemorrhage', ...
    'Hard Exudate', ...
    'Soft Exudate'};

modelFields = { ...
    'Microaneurysm', ...
    'Haemorrhage', ...
    'HardExudate', ...
    'SoftExudate'};

lesionMasks = cell(4,1);
lesionCounts = zeros(4,1);


for k = 1:4

    fprintf('Segmenting %s...\n',lesionNames{k});

    try

        currentModel = models.(modelFields{k});

        predictedMask = semanticseg( ...
            segImage, ...
            currentModel);

        % Convert categorical result into logical mask
        predictedMask = string(predictedMask);

        lesionMasks{k} = ...
            predictedMask == "lesion";

        lesionCounts(k) = ...
            nnz(lesionMasks{k});

    catch ME

        warning( ...
            'Could not segment %s: %s', ...
            lesionNames{k},ME.message);

        lesionMasks{k} = ...
            false(size(segImage,1),size(segImage,2));

        lesionCounts(k) = 0;

    end

end


%% ============================================================
% 12. CREATE CLEAN LESION OVERLAY
% =============================================================

fprintf('\nCreating lesion overlay...\n');

overlay = segImage;

% Convert to RGB if necessary
if size(overlay,3) == 1
    overlay = repmat(overlay,[1 1 3]);
end

overlay = im2double(overlay);

% Make overlay slightly darker
overlay = overlay * 0.65;


% Microaneurysm - Red
mask = lesionMasks{1};

for c = 1:3
    channel = overlay(:,:,c);

    if c == 1
        channel(mask) = 1;
    else
        channel(mask) = 0;
    end

    overlay(:,:,c) = channel;
end


% Haemorrhage - Blue
mask = lesionMasks{2};

for c = 1:3
    channel = overlay(:,:,c);

    if c == 3
        channel(mask) = 1;
    else
        channel(mask) = 0;
    end

    overlay(:,:,c) = channel;
end


% Hard Exudate - Yellow
mask = lesionMasks{3};

overlay(:,:,1) = ...
    max(overlay(:,:,1),double(mask));

overlay(:,:,2) = ...
    max(overlay(:,:,2),double(mask));


% Soft Exudate - Magenta
mask = lesionMasks{4};

overlay(:,:,1) = ...
    max(overlay(:,:,1),double(mask));

overlay(:,:,3) = ...
    max(overlay(:,:,3),double(mask));


%% Save overlay

fig = figure('Visible','off');

imshow(overlay);

title('ForeSight DR - Lesion Segmentation');

legendText = { ...
    'Red = Microaneurysm', ...
    'Blue = Haemorrhage', ...
    'Yellow = Hard Exudate', ...
    'Magenta = Soft Exudate'};

annotation( ...
    'textbox', ...
    [0.02 0.02 0.4 0.12], ...
    'String',legendText, ...
    'FitBoxToText','on');

lesionOverlay = fullfile( ...
    tempdir, ...
    'ForeSight_Lesion_Overlay.png');

exportgraphics(fig,lesionOverlay);

close(fig);

fprintf('Lesion overlay generated.\n');


%% ============================================================
% 13. CREATE RESULT STRUCTURE
% =============================================================

result = struct();

result.drGrade = drGrade;

result.drClass = drClass;

result.confidence = confidence;

result.gradCAMImage = gradCAMImage;

result.localizationImage = localizationImage;

result.opticDisc = opticDisc;

result.fovea = fovea;

result.lesionOverlay = lesionOverlay;

result.lesionCounts = lesionCounts;

result.lesionNames = lesionNames;

result.imagePath = imagePath;


%% ============================================================
% 14. DISPLAY FINAL RESULTS
% =============================================================

fprintf('\n========================================\n');
fprintf('          FORESIGHT DR RESULT\n');
fprintf('========================================\n');

fprintf('DR Grade       : %d\n',drGrade);
fprintf('Classification : %s\n',drClass);
fprintf('Confidence     : %.2f%%\n',confidence*100);

fprintf('\nLesion Pixels:\n');

for k = 1:4

    fprintf('  %-20s : %d\n', ...
        lesionNames{k}, ...
        lesionCounts(k));

end

fprintf('\n========================================\n');
fprintf('Backend processing complete!\n');
fprintf('========================================\n');


end


%% ============================================================
% LOCAL FUNCTION
% IMAGE PREPROCESSING FOR SEGMENTATION
% =============================================================

function outputImage = preprocessForSegmentation(inputImage)

    % Convert to RGB
    if size(inputImage,3) == 1
        inputImage = repmat(inputImage,[1 1 3]);
    end

    inputImage = im2uint8(inputImage);


    % ---------------------------------------------------------
    % Detect retinal field
    % ---------------------------------------------------------

    grayImage = rgb2gray(inputImage);

    mask = grayImage > 10;

    % Remove tiny regions
    mask = bwareaopen(mask,500);


    % ---------------------------------------------------------
    % Find bounding box
    % ---------------------------------------------------------

    props = regionprops(mask,'BoundingBox','Area');

    if isempty(props)

        cropped = inputImage;

    else

        [~,idx] = max([props.Area]);

        bbox = props(idx).BoundingBox;

        cropped = imcrop(inputImage,bbox);

    end


    % ---------------------------------------------------------
    % Make square
    % ---------------------------------------------------------

    [h,w,~] = size(cropped);

    side = max(h,w);

    squareImage = zeros( ...
        side,side,3,'uint8');

    yStart = floor((side-h)/2)+1;

    xStart = floor((side-w)/2)+1;

    squareImage( ...
        yStart:yStart+h-1, ...
        xStart:xStart+w-1,:) = cropped;


    % ---------------------------------------------------------
    % Resize to segmentation input
    % ---------------------------------------------------------

    outputImage = imresize( ...
        squareImage,[384 384]);


    % ---------------------------------------------------------
    % Mild CLAHE enhancement on green channel
    % ---------------------------------------------------------

    greenChannel = outputImage(:,:,2);

    greenChannel = adapthisteq( ...
        greenChannel, ...
        'ClipLimit',0.01);

    outputImage(:,:,2) = greenChannel;

end