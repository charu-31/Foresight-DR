import sqlite3
import pandas as pd

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

train_df = pd.read_csv("val_split.csv")

for _, row in train_df.iterrows():

    id_code = row["id_code"]
    diagnosis = int(row["diagnosis"])

    cursor.execute("""
        INSERT INTO patients (name, age, gender, diabetes_duration_years, location)
        VALUES (?, NULL, NULL, NULL, NULL);
    """, (f"APTOS_{id_code}",))

    new_patient_id = cursor.lastrowid

    image_path = f"aptos_all_images/{id_code}.png"

    cursor.execute("""
        INSERT INTO fundus_images (patient_id, image_path, eye, date_captured, source_dataset)
        VALUES (?, ?, NULL, NULL, ?);
    """, (new_patient_id, image_path, "APTOS"))

    new_image_id = cursor.lastrowid

    cursor.execute("""
        INSERT INTO dr_results (image_id, severity_grade, confidence_score, is_ground_truth)
        VALUES (?, ?, NULL, 1);
    """, (new_image_id, diagnosis))

connection.commit()

print(f"Done! Loaded {len(train_df)} images from val_split.csv into dr_project.db")

connection.close()
