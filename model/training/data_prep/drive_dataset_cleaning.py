from PIL import Image

def is_corrupted(filepath):
    try:
        img = Image.open(filepath)
        img.verify()
        return False
    except Exception:
        return True

def check_folder(folder_path, label):
    files = os.listdir(folder_path)
    corrupted = [f for f in files if is_corrupted(os.path.join(folder_path, f))]
    print(f"{label}: {len(files)} checked, {len(corrupted)} corrupted")
    if corrupted:
        print(f"  Corrupted files: {corrupted}")

check_folder('/content/drive_data/DRIVE/training/images', 'Training images')
check_folder('/content/drive_data/DRIVE/training/mask', 'Training masks')
check_folder('/content/drive_data/DRIVE/training/1st_manual', 'Training manual1')
check_folder('/content/drive_data/DRIVE/test/images', 'Test images')
check_folder('/content/drive_data/DRIVE/test/mask', 'Test masks')

import imagehash

def check_duplicates(folder_path, label):
    files = os.listdir(folder_path)
    hashes = {}
    dupes = []

    for filename in files:
        img = Image.open(os.path.join(folder_path, filename))
        img_hash = imagehash.phash(img, hash_size=16)
        if img_hash in hashes:
            dupes.append((filename, hashes[img_hash]))
        else:
            hashes[img_hash] = filename

    print(f"{label}: {len(files)} checked, {len(dupes)} duplicate pairs found")
    if dupes:
        print(f"  {dupes}")

check_duplicates('/content/drive_data/DRIVE/training/images', 'Training images')
check_duplicates('/content/drive_data/DRIVE/test/images', 'Test images')

