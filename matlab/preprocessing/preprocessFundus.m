function preprocessedImage = preprocessFundus(retinalImage)
% preprocessFundus
% Preprocesses a retinal fundus image for downstream AI screening.
%
% Input:
%   retinalImage - RGB fundus image
%
% Output:
%   preprocessedImage - processed grayscale fundus image

%% Convert RGB image to grayscale

grayImage = rgb2gray(retinalImage);

%% Enhance local contrast using CLAHE

claheImage = adapthisteq(grayImage);

%% Normalize intensity values

claheDouble = im2double(claheImage);

normalizedImage = mat2gray(claheDouble);

%% Reduce small noise

preprocessedImage = medfilt2(normalizedImage, [3 3]);

end
