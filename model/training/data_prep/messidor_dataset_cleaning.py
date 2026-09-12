from PIL import Image
import os

def is_corrupted(filepath):
    try:
        img = Image.open(filepath)
        img.verify()
        return False
    except Exception:
        return True

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

hashes = {}
duplicates = []

for filename in os.listdir(image_folder):
    filepath = os.path.join(image_folder, filename)
    img = Image.open(filepath)
    img_hash = imagehash.phash(img, hash_size=16)

    if img_hash in hashes:
        duplicates.append((filename, hashes[img_hash]))
    else:
        hashes[img_hash] = filename

print(f"Total images checked: {len(os.listdir(image_folder))}")
print(f"Duplicate pairs found: {len(duplicates)}")
print(duplicates)

import matplotlib.pyplot as plt

for file1, file2 in duplicates:
    img1 = Image.open(os.path.join(image_folder, file1))
    img2 = Image.open(os.path.join(image_folder, file2))

    fig, axes = plt.subplots(1, 2, figsize=(8,4))
    axes[0].imshow(img1)
    axes[0].set_title(file1)
    axes[0].axis('off')

    axes[1].imshow(img2)
    axes[1].set_title(file2)
    axes[1].axis('off')

    plt.show()

files_to_remove = set()

for file1, file2 in duplicates:
    files_to_remove.add(file1)

print(f"Files to remove: {len(files_to_remove)}")
print(files_to_remove)

removed_count = 0
for filename in files_to_remove:
    filepath = os.path.join(image_folder, filename)
    if os.path.exists(filepath):
        os.remove(filepath)
        removed_count += 1

print(f"Removed {removed_count} image files")
print(f"Remaining images: {len(os.listdir(image_folder))}")

print(f"Rows before removing: {df_messidor.shape}")

df_messidor_clean = df_messidor[~df_messidor['id_code'].isin(files_to_remove)]

print(f"Rows after removing: {df_messidor_clean.shape}")
