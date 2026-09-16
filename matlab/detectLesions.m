function results = detectLesions(models, retinalImage)
% detectLesions
% Runs the four trained lesion-segmentation models.
%
% Input:
%   models       - structure containing the four trained dlnetworks
%   retinalImage - RGB fundus image
%
% Output:
%   results      - structure containing lesion masks and pixel counts

% Prepare image for the trained networks
img = imresize(retinalImage,[384 384]);
img = single(img);
dlImg = dlarray(img,'SSC');

% Lesion model names
lesions = {'Microaneurysm','Haemorrhage','HardExudate','SoftExudate'};

for i = 1:numel(lesions)

    lesionName = lesions{i};

    % Select trained model
    net = models.(lesionName);

    % Run prediction
    output = predict(net,dlImg);

    % Convert prediction to numeric array
    scores = extractdata(output);

    % Select highest-scoring class for each pixel
    [~,mask] = max(scores,[],3);

    % Store results
    results.(lesionName).Mask = (mask == 2);
    results.(lesionName).DetectedPixels = nnz(mask == 2);

end

end