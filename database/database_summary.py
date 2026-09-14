import sqlite3

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()

print("=" * 50)
print("DR_PROJECT.DB SUMMARY REPORT")
print("=" * 50)

cursor.execute("SELECT COUNT(*) FROM patients;")
print(f"\nTotal patients: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM fundus_images;")
print(f"Total images: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM dr_results;")
print(f"Total DR results (severity labels): {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM vessel_masks;")
print(f"Total vessel masks: {cursor.fetchone()[0]}")

print("\n--- Images per dataset ---")
cursor.execute("""
    SELECT source_dataset, COUNT(*)
    FROM fundus_images
    GROUP BY source_dataset;
""")
for dataset, count in cursor.fetchall():
    print(f"  {dataset}: {count}")

print("\n--- Severity grade distribution ---")
cursor.execute("""
    SELECT dr_results.severity_grade, COUNT(*)
    FROM dr_results
    GROUP BY dr_results.severity_grade
    ORDER BY dr_results.severity_grade;
""")
for grade, count in cursor.fetchall():
    print(f"  Grade {grade}: {count}")

cursor.execute("""
    SELECT COUNT(*) FROM fundus_images
    WHERE patient_id NOT IN (SELECT patient_id FROM patients);
""")
print(f"\nImages with a missing/broken patient link: {cursor.fetchone()[0]} (should be 0)")

cursor.execute("""
    SELECT COUNT(*) FROM dr_results
    WHERE image_id NOT IN (SELECT image_id FROM fundus_images);
""")
print(f"Results with a missing/broken image link: {cursor.fetchone()[0]} (should be 0)")

print("\n" + "=" * 50)

connection.close()
