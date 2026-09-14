import sqlite3

# STEP A: Connect to the database file.
# If "dr_project.db" doesn't exist yet, SQLite will CREATE it right here.
# If it already exists, this just opens it (won't erase existing data).
connection = sqlite3.connect("dr_project.db")

# STEP B: Create a "cursor" -- this is the object we actually use
# to run commands against the database.
cursor = connection.cursor()

# STEP C: Write the SQL command that creates our "patients" table.
# Notice: this is a Python multi-line string containing SQL code,
# not Python code itself.
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

# STEP D: Run that SQL command using the cursor.
cursor.execute(create_patients_table)

# STEP D2: Turn on foreign key enforcement.
# SQLite has this OFF by default (unlike most databases), so without
# this line, SQLite would silently allow an image to be linked to a
# patient_id that doesn't actually exist -- bad data with no warning.
cursor.execute("PRAGMA foreign_keys = ON;")

# STEP D3: Create the fundus_images table.
# Each row = one eye photo, linked back to exactly one patient.
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

# STEP D4: Create the dr_results table.
# Each row = one severity result for one image.
# Links back to fundus_images the same way fundus_images links to patients.
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

# STEP E: Save (commit) the changes to the actual .db file.
# Without this line, the table creation would NOT be saved permanently.
connection.commit()

# STEP F: Close the connection -- good practice once you're done.
connection.close()

print("Done! 'patients' table created inside dr_project.db")
