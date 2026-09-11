# MATLAB — Fundus Image Processing

This folder contains the MATLAB implementation for retinal fundus image quality assessment and preprocessing in the **Foresight DR** project.

The MATLAB pipeline prepares retinal fundus images for the downstream AI-based diabetic retinopathy screening system.

## Pipeline


RGB Fundus Image
       ↓
Image Quality Assessment
       ↓
   ┌───────────────┐
   │               │
 REJECT          ACCEPT
   │               │
Recapture          ↓
             Image Preprocessing
                   ↓
             AI Screening Model


## Folder Structure


matlab/
├── preprocessing/
│   ├── fundus_basics.m
│   ├── preprocessFundus.m
│   └── testPreprocessing.m
│
├── quality_assessment/
│   ├── assessQuality.m
│   └── testQualityAssessment.m
│
└── README.md


## 1. Quality Assessment

### `assessQuality.m`

This function evaluates the basic quality of a retinal fundus image using:

* Brightness
* Contrast
* Sharpness
* Field of View (FOV)

It returns:

* Quality measurements
* `ACCEPT` or `REJECT` status
* A user-friendly message explaining the result

Example:

matlab
testImage = imread("../test_images/retinal(1).jpg");
result = assessQuality(testImage);
disp(result);


Example output:


Brightness: 56.1380
Contrast: 35.0548
Sharpness: 426.7079
FOV: 78.9481
Status: "ACCEPT"
Message: "Image quality is good. Proceed with screening."


### Quality Decision

Images that fail the preliminary quality checks are rejected and the user is prompted to recapture the image.

Possible quality issues include:

* Image too dark
* Image too bright
* Low contrast
* Image blur
* Insufficient retinal field of view

> **Note:** The current thresholds are preliminary prototype thresholds intended for development and internal hackathon testing. They are not clinically validated thresholds.

---

## 2. Image Preprocessing

### `preprocessFundus.m`

This function prepares an accepted fundus image for downstream AI processing.

The current preprocessing pipeline is:


RGB Image
    ↓
Grayscale Conversion
    ↓
CLAHE Contrast Enhancement
    ↓
Intensity Normalization
    ↓
3 × 3 Median Filtering
    ↓
Preprocessed Image


The preprocessing steps are designed to improve the visibility and consistency of retinal structures before AI analysis.

Example:

matlab
testImage = imread("../test_images/retinal(1).jpg");
processedImage = preprocessFundus(testImage);

figure;
imshow(processedImage);
title('Preprocessed Fundus Image');




## 3. Test Scripts

### `testQualityAssessment.m`

Tests the `assessQuality()` function on multiple retinal fundus images and displays the quality measurements and decisions.

### `testPreprocessing.m`

Tests the preprocessing pipeline on multiple fundus images and displays the original and processed images.

### `fundus_basics.m`

Contains the initial image analysis and experimentation used during development, including:

* Image loading
* RGB channel analysis
* Grayscale conversion
* Brightness measurement
* Contrast measurement
* Sharpness measurement
* Field-of-view estimation

These experiments helped establish the current quality-assessment and preprocessing pipeline.

---

## Requirements

The MATLAB implementation uses functions from the **Image Processing Toolbox**.

Required functionality includes:

* `rgb2gray`
* `adapthisteq`
* `mat2gray`
* `medfilt2`
* `fspecial`
* `imfilter`

## Current Scope

The MATLAB module is responsible for:

1. Checking whether the input fundus image has acceptable basic quality.
2. Rejecting poor-quality images and providing recapture guidance.
3. Preprocessing accepted images.
4. Passing the processed image to the downstream AI screening stage.

The MATLAB module **does not perform the final diabetic retinopathy diagnosis by itself**.

## Future Integration

The processed image will be passed to the AI model for diabetic retinopathy screening.

Planned pipeline:


Fundus Image
     ↓
MATLAB Quality Assessment
     ↓
MATLAB Preprocessing
     ↓
AI Model
     ↓
DR Severity Classification
     ↓
Explainability / Grad-CAM
     ↓
Backend / Frontend


The MATLAB functions will later be integrated with the Python-based application.

## Development Note

The current implementation is a prototype developed for the internal hackathon. Image-quality thresholds and preprocessing choices require further evaluation and validation using a larger clinically labelled dataset before any clinical deployment.
