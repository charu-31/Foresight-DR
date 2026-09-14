import sqlite3
import pandas as pd

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

test_df = pd.read_csv("drive_test_pairs.csv")

for _, row in test_df.iterrows():

    drive_id = row["id"]
    image_filename = row["image"]

    # --- Insert a placeholder patient ---
    cursor.execute("""
        INSERT INTO patients (name, age, gender, diabetes_duration_years, location)
        VALUES (?, NULL, NULL, NULL, NULL);
    """, (f"DRIVE_test_{drive_id}",))

    new_patient_id = cursor.lastrowid

    # --- Insert the fundus image ---
    # NOTE: no vessel_masks row and no dr_results row here --
    # DRIVE's test set has no ground-truth vessel mask by design.
    image_path = f"drive_all_images/{image_filename}"

    cursor.execute("""
        INSERT INTO fundus_images (patient_id, image_path, eye, date_captured, source_dataset)
        VALUES (?, ?, NULL, NULL, ?);
    """, (new_patient_id, image_path, "DRIVE"))

connection.commit()

print(f"Done! Loaded {len(test_df)} DRIVE test images (no ground-truth masks).")

connection.close()
