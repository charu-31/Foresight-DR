import cv2

target_size = (224, 224)

def resize_pair(image_folder, image_file, mask_folder, mask_file, manual_folder=None, manual_file=None):
    img = cv2.imread(os.path.join(image_folder, image_file))
    img_resized = cv2.resize(img, target_size, interpolation=cv2.INTER_LINEAR)
    cv2.imwrite(os.path.join(image_folder, image_file), img_resized)
    
    mask = cv2.imread(os.path.join(mask_folder, mask_file), cv2.IMREAD_GRAYSCALE)
    mask_resized = cv2.resize(mask, target_size, interpolation=cv2.INTER_NEAREST)
    cv2.imwrite(os.path.join(mask_folder, mask_file.replace('.gif', '.png')), mask_resized)
    
    if manual_folder and manual_file:
        manual = cv2.imread(os.path.join(manual_folder, manual_file), cv2.IMREAD_GRAYSCALE)
        manual_resized = cv2.resize(manual, target_size, interpolation=cv2.INTER_NEAREST)
        cv2.imwrite(os.path.join(manual_folder, manual_file.replace('.gif', '.png')), manual_resized)

image_folder = '/content/drive_data/DRIVE/training/images'
mask_folder = '/content/drive_data/DRIVE/training/mask'
manual_folder = '/content/drive_data/DRIVE/training/1st_manual'

for _, row in df_drive_train.iterrows():
    resize_pair(
        image_folder, row['image'],
        mask_folder, row['mask'],
        manual_folder, row['manual1']
    )

print("Training set resized!")

test_image_folder = '/content/drive_data/DRIVE/test/images'
test_mask_folder = '/content/drive_data/DRIVE/test/mask'

for _, row in df_drive_test.iterrows():
    resize_pair(
        test_image_folder, row['image'],
        test_mask_folder, row['mask']
    )

print("Test set resized!")

import shutil

# Save the pairing tables as CSVs
df_drive_train.to_csv('/content/drive_data/drive_train_pairs.csv', index=False)
df_drive_test.to_csv('/content/drive_data/drive_test_pairs.csv', index=False)

shutil.copy('/content/drive_data/drive_train_pairs.csv', '/content/drive/MyDrive/drive_train_pairs.csv')
shutil.copy('/content/drive_data/drive_test_pairs.csv', '/content/drive/MyDrive/drive_test_pairs.csv')

# Back up the entire resized DRIVE folder (images + masks + manual1)
shutil.make_archive('/content/drive/MyDrive/DRIVE_resized_backup', 'zip', '/content/drive_data/DRIVE')

print("DRIVE pairing tables and resized images backed up to Drive!")

