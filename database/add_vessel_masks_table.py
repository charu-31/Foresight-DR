import sqlite3

connection = sqlite3.connect("dr_project.db")
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON;")

# New table: vessel_masks
# Each row = one vessel segmentation mask, linked to one fundus image.
# Not every image will have a mask (DRIVE's test set has none by design),
# so we simply won't insert a row for those images -- no need for a
# placeholder/NULL mask.
create_vessel_masks_table = """
CREATE TABLE IF NOT EXISTS vessel_masks (
    mask_id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id INTEGER NOT NULL,
    mask_path TEXT NOT NULL,
    FOREIGN KEY (image_id) REFERENCES fundus_images (image_id)
);
"""
cursor.execute(create_vessel_masks_table)
connection.commit()

print("Done! 'vessel_masks' table added to dr_project.db")

connection.close()
