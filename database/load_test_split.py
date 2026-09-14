import sqlite3
import pandas as pd

# STEP 1: Connect to your REAL database (not the test one).
# This assumes dr_project.db already exists (built by create_database.py).
connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

# STEP 2: Load the CSV into a pandas DataFrame.
# A DataFrame is just pandas' version of a table -- rows and columns in memory.
train_df = pd.read_csv("test_split.csv")

# STEP 3: Loop through every row of the CSV, one image at a time.
# iterrows() gives us (row_number, row_data) for each row -- we only need row_data here.
for _, row in train_df.iterrows():

    id_code = row["id_code"]
    diagnosis = int(row["diagnosis"])

    # --- Insert a placeholder patient for this image ---
    # We don't have real patient info, so we fill in what we DO know
    # (a traceable name) and leave the rest as NULL (unknown).
    cursor.execute("""
        INSERT INTO patients (name, age, gender, diabetes_duration_years, location)
        VALUES (?, NULL, NULL, NULL, NULL);
    """, (f"APTOS_{id_code}",))

    new_patient_id = cursor.lastrowid

    # --- Insert the fundus image, linked to that patient ---
    # Note: we build the image path ourselves using the folder name you chose.
    image_path = f"aptos_all_images/{id_code}.png"

    cursor.execute("""
        INSERT INTO fundus_images (patient_id, image_path, eye, date_captured, source_dataset)
        VALUES (?, ?, NULL, NULL, ?);
    """, (new_patient_id, image_path, "APTOS"))

    new_image_id = cursor.lastrowid

    # --- Insert the DR result, linked to that image ---
    # is_ground_truth = 1 because this diagnosis came from the real dataset label,
    # not from an AI prediction.
    cursor.execute("""
        INSERT INTO dr_results (image_id, severity_grade, confidence_score, is_ground_truth)
        VALUES (?, ?, NULL, 1);
    """, (new_image_id, diagnosis))

# STEP 4: Save everything at once, after the whole loop finishes.
# (More efficient than committing after every single row.)
connection.commit()

print(f"Done! Loaded {len(train_df)} images from test_split.csv into dr_project.db")

connection.close()
