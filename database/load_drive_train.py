import sqlite3
import pandas as pd

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

train_df = pd.read_csv("drive_train_pairs.csv")

for _, row in train_df.iterrows():

    drive_id = row["id"]
    image_filename = row["image"]
    manual1_filename = row["manual1"]

    cursor.execute("""
        INSERT INTO patients (name, age, gender, diabetes_duration_years, location)
        VALUES (?, NULL, NULL, NULL, NULL);
    """, (f"DRIVE_train_{drive_id}",))

    new_patient_id = cursor.lastrowid

    image_path = f"drive_all_images/{image_filename}"

    cursor.execute("""
        INSERT INTO fundus_images (patient_id, image_path, eye, date_captured, source_dataset)
        VALUES (?, ?, NULL, NULL, ?);
    """, (new_patient_id, image_path, "DRIVE"))

    new_image_id = cursor.lastrowid

    mask_path = f"drive_manual1_masks/{manual1_filename}"

    cursor.execute("""
        INSERT INTO vessel_masks (image_id, mask_path)
        VALUES (?, ?);
    """, (new_image_id, mask_path))

connection.commit()

print(f"Done! Loaded {len(train_df)} DRIVE train images with vessel masks.")

connection.close()
