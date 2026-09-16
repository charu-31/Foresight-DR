clc;
clear;
close all;

%% ============================================
%       FORESIGHT DR - EXPLAINABLE AI
%              GRAD-CAM
% =============================================

%% 1. LOAD TRAINED MODEL

load('ForeSight_IDRiD_ResNet18.mat','net');

fprintf('Model loaded successfully!\n');


%% 2. CLASS NAMES

classNames = { ...
    'No DR', ...
    'Mild DR', ...
    'Moderate DR', ...
    'Severe DR', ...
    'Proliferative DR'};


%% 3. SELECT RETINAL IMAGE

[file,path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png','Retinal Images'}, ...
    'Select a Fundus Image');

if isequal(file,0)
    error('No image selected.');
end

imagePath = fullfile(path,file);


%% 4. READ IMAGE

img = imread(imagePath);


%% 5. CONVERT GRAYSCALE TO RGB IF NEEDED

if size(img,3) == 1
    img = cat(3,img,img,img);
end


%% 6. RESIZE FOR RESNET-18

imgInput = imresize(img,[224 224]);


%% 7. PREDICT DR

scores = predict(net,single(imgInput));


%% 8. FIND PREDICTED CLASS

[confidence,classIndex] = max(scores);


predictedClass = classNames{classIndex};


%% 9. DISPLAY PREDICTION

fprintf('\n====================================\n');
fprintf('        FORESIGHT DR RESULT\n');
fprintf('====================================\n');

fprintf('Prediction  : %s\n',predictedClass);

fprintf('Confidence  : %.2f%%\n', ...
    confidence*100);


%% 10. GENERATE GRAD-CAM

fprintf('\nGenerating Grad-CAM explanation...\n');

scoreMap = gradCAM( ...
    net, ...
    imgInput, ...
    classIndex);


%% 11. DISPLAY ORIGINAL IMAGE

figure;

imshow(imgInput);

title(sprintf( ...
    'Fundus Image - Predicted: %s', ...
    predictedClass), ...
    'FontSize',14);


%% 12. DISPLAY HEATMAP

figure;

imshow(imgInput);

hold on;

imagesc(scoreMap);

colormap jet;

colorbar;

alpha(0.45);

title(sprintf( ...
    'Grad-CAM Explanation - %s', ...
    predictedClass), ...
    'FontSize',14);

hold off;


%% 13. SAVE EXPLANATION

outputName = ...
    'ForeSight_GradCAM_Result.png';

saveas(gcf,outputName);

fprintf('\nGrad-CAM result saved as:\n');
fprintf('%s\n',outputName);


fprintf('\n====================================\n');
fprintf('       EXPLANATION COMPLETE\n');
fprintf('====================================\n');