from PIL import Image
import os

def is_corrupted(filepath):
    try:
        img = Image.open(filepath)
        img.verify()
        return False
    except Exception:
        return True

image_folder = '/content/aptos_data/all_images'
corrupted_files = []

for filename in os.listdir(image_folder):
    filepath = os.path.join(image_folder, filename)
    if is_corrupted(filepath):
        corrupted_files.append(filename)

print(f"Total images checked: {len(os.listdir(image_folder))}")
print(f"Corrupted images found: {len(corrupted_files)}")
print(corrupted_files)
import imagehash
from PIL import Image
import os

image_folder = '/content/aptos_data/all_images'
hashes = {}
duplicates = []

for filename in os.listdir(image_folder):
    filepath = os.path.join(image_folder, filename)
    img = Image.open(filepath)
    img_hash = imagehash.average_hash(img)
    
    if img_hash in hashes:
        duplicates.append((filename, hashes[img_hash]))
    else:
        hashes[img_hash] = filename

print(f"Total images checked: {len(os.listdir(image_folder))}")
print(f"Duplicate pairs found: {len(duplicates)}")
print(duplicates)
import os

removed_count = 0
for filename in files_to_remove:
    filepath = os.path.join(image_folder, filename)
    if os.path.exists(filepath):
        os.remove(filepath)
        removed_count += 1

print(f"Removed {removed_count} image files")
print(f"Remaining images: {len(os.listdir(image_folder))}")
files_to_remove_ids = [f.replace('.png', '') for f in files_to_remove]

print(f"Rows before removing: {df_combined.shape}")

df_combined_clean = df_combined[~df_combined['id_code'].isin(files_to_remove_ids)]

print(f"Rows after removing: {df_combined_clean.shape}")

