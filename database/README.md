dr_project.db is a SQLite database that stores patient records, fundus images, DR severity results, and vessel segmentation masks, combined from three public datasets: APTOS, Messidor, and DRIVE.

Since APTOS/Messidor/DRIVE are anonymized public datasets with no real patient info, each image is linked to a placeholder "patient" (e.g. APTOS_041f09eec1e8). When real clinic patients are added later (via Member 5's app), they'll use the same patients table with real name/age/etc. — no schema changes needed.

Schema:

patients — one row per patient (real or placeholder)

patient_id (PK), name, age, gender, diabetes_duration_years, location

fundus_images — one row per eye photo, linked to a patient

image_id (PK), patient_id (FK), image_path, eye, date_captured, source_dataset

dr_results — one row per severity grading, linked to an image

result_id (PK), image_id (FK), severity_grade (0–4), confidence_score, is_ground_truth
Only APTOS and Messidor have rows here (DRIVE has no severity grade)

vessel_masks — one row per vessel segmentation mask, linked to an image

mask_id (PK), image_id (FK), mask_path
Only DRIVE train images have rows here (DRIVE test has no ground-truth mask)
Current contents has totally 5,951 images

Severity distribution: Grade 0: 2,815 · Grade 1: 770 · Grade 2: 1,279 · Grade 3: 530 · Grade 4: 517
