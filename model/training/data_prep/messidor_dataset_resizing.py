import cv2
import os

target_size = (224, 224)
filenames = os.listdir(image_folder)
resized_count = 0

for filename in filenames:
    filepath = os.path.join(image_folder, filename)
    img = cv2.imread(filepath)
    img_resized = cv2.resize(img, target_size)
    cv2.imwrite(filepath, img_resized)
    resized_count += 1

print(f"Resized {resized_count} images to {target_size}")

df_messidor_clean = df_messidor_clean.drop(columns=['file_exists'])
df_messidor_clean.to_csv('/content/messidor2_data/messidor2_clean_split.csv', index=False)

import shutil
shutil.copy('/content/messidor2_data/messidor2_clean_split.csv', '/content/drive/MyDrive/messidor2_clean_split.csv')

print("Messidor-2 labels saved and backed up!")

shutil.make_archive('/content/drive/MyDrive/messidor2_images_resized_backup', 'zip', image_folder)

print("Messidor-2 image folder backed up to Drive!")