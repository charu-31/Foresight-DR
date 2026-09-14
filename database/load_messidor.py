import sqlite3
import pandas as pd

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

messidor_df = pd.read_csv("messidor2_clean_split.csv")

skipped_count = 0
loaded_count = 0

for _, row in messidor_df.iterrows():

    if int(row["adjudicated_gradable"]) == 0:
        skipped_count += 1
        continue

    id_code = row["id_code"]
    diagnosis = int(row["diagnosis"])

    cursor.execute("""
        INSERT INTO patients (name, age, gender, diabetes_duration_years, location)
        VALUES (?, NULL, NULL, NULL, NULL);
    """, (f"MESSIDOR_{id_code}",))

    new_patient_id = cursor.lastrowid

    image_path = f"messidor_all_images/{id_code}"

    cursor.execute("""
        INSERT INTO fundus_images (patient_id, image_path, eye, date_captured, source_dataset)
        VALUES (?, ?, NULL, NULL, ?);
    """, (new_patient_id, image_path, "MESSIDOR"))

    new_image_id = cursor.lastrowid

    cursor.execute("""
        INSERT INTO dr_results (image_id, severity_grade, confidence_score, is_ground_truth)
        VALUES (?, ?, NULL, 1);
    """, (new_image_id, diagnosis))

    loaded_count += 1

connection.commit()

print(f"Done! Loaded {loaded_count} images, skipped {skipped_count} ungradable images.")

connection.close()
