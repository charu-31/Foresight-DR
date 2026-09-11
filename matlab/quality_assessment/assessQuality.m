function qualityResult = assessQuality(retinalImage)
% assessQuality
% Evaluates the quality of a retinal fundus image.
%
% Input:
%   retinalImage - RGB fundus image
%
% Output:
%   qualityResult - structure containing quality measurements,
%                   status, and user-friendly message.

%% Convert image to grayscale

grayImage = rgb2gray(retinalImage);

%% Brightness

brightness = mean(grayImage(:));

%% Contrast

grayDouble = double(grayImage);
contrast = std(grayDouble(:));

%% Sharpness

laplacianFilter = fspecial('laplacian', 0);
laplacianResponse = imfilter(grayDouble, laplacianFilter);

sharpness = var(laplacianResponse(:));

%% Field of View

fovMask = grayImage > 10;

visiblePixels = sum(fovMask(:));
totalPixels = numel(grayImage);

fov = (visiblePixels / totalPixels) * 100;

%% Quality thresholds

brightnessLower = 40;
brightnessUpper = 120;

contrastLower = 20;

sharpnessLower = 50;

fovLower = 70;

%% Check quality conditions

brightnessOK = brightness >= brightnessLower && ...
               brightness <= brightnessUpper;

contrastOK = contrast >= contrastLower;

sharpnessOK = sharpness >= sharpnessLower;

fovOK = fov >= fovLower;

%% Generate user-friendly message

problems = strings(0);

if ~brightnessOK

    if brightness < brightnessLower
        problems(end+1) = ...
            "Image is too dark. Improve the lighting and recapture.";
    else
        problems(end+1) = ...
            "Image is too bright. Adjust the lighting and recapture.";
    end

end

if ~contrastOK
    problems(end+1) = ...
        "Retinal details are not clear. Please recapture the image.";
end

if ~sharpnessOK
    problems(end+1) = ...
        "Image appears blurry. Hold the camera steady and recapture.";
end

if ~fovOK
    problems(end+1) = ...
        "Retinal area is not fully visible. Reposition the camera and recapture.";
end

%% Final decision

if isempty(problems)

    status = "ACCEPT";
    message = "Image quality is good. Proceed with screening.";

else

    status = "REJECT";
    message = strjoin(problems, " ");

end

%% Store results

qualityResult.Brightness = brightness;
qualityResult.Contrast = contrast;
qualityResult.Sharpness = sharpness;
qualityResult.FOV = fov;

qualityResult.Status = status;
qualityResult.Message = message;

end
