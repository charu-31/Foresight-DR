import sqlite3

connection = sqlite3.connect("dr_project.db")

cursor = connection.cursor()

create_patients_table = """
CREATE TABLE IF NOT EXISTS patients (
    patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    age INTEGER,
    gender TEXT,
    diabetes_duration_years INTEGER,
    location TEXT
);
"""

cursor.execute(create_patients_table)

cursor.execute("PRAGMA foreign_keys = ON;")

create_images_table = """
CREATE TABLE IF NOT EXISTS fundus_images (
    image_id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    image_path TEXT NOT NULL,
    eye TEXT,
    date_captured TEXT,
    source_dataset TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
);
"""
cursor.execute(create_images_table)

create_results_table = """
CREATE TABLE IF NOT EXISTS dr_results (
    result_id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id INTEGER NOT NULL,
    severity_grade INTEGER,
    confidence_score REAL,
    is_ground_truth INTEGER NOT NULL,
    FOREIGN KEY (image_id) REFERENCES fundus_images (image_id)
);
"""
cursor.execute(create_results_table)

connection.commit()

# STEP F: Close the connection -- good practice once you're done.
connection.close()

print("Done! 'patients' table created inside dr_project.db")
