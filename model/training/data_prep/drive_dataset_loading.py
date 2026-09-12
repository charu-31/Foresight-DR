from google.colab import drive
drive.mount('/content/drive')

import zipfile

with zipfile.ZipFile('/content/drive/MyDrive/DRIVEdataset.zip', 'r') as zip_ref:
    zip_ref.extractall('/content/drive_data')

import os
print(os.listdir('/content/drive_data'))

contents = os.listdir('/content/drive_data/DRIVE')
print(contents)

print("Training folder:")
print(os.listdir('/content/drive_data/DRIVE/training'))

print("\nTest folder:")
print(os.listdir('/content/drive_data/DRIVE/test'))

import pandas as pd

training_ids = sorted([get_id_number(f) for f in training_images])

training_pairs = []
for id_num in training_ids:
    training_pairs.append({
        'id': id_num,
        'image': f'{id_num}_training.tif',
        'mask': f'{id_num}_training_mask.gif',
        'manual1': f'{id_num}_manual1.gif'
    })

df_drive_train = pd.DataFrame(training_pairs)
print(df_drive_train.shape)
print(df_drive_train.head())

mage_folder = '/content/drive_data/DRIVE/training/images'
mask_folder = '/content/drive_data/DRIVE/training/mask'
manual_folder = '/content/drive_data/DRIVE/training/1st_manual'

df_drive_train['image_exists'] = df_drive_train['image'].apply(lambda x: os.path.exists(os.path.join(image_folder, x)))
df_drive_train['mask_exists'] = df_drive_train['mask'].apply(lambda x: os.path.exists(os.path.join(mask_folder, x)))
df_drive_train['manual1_exists'] = df_drive_train['manual1'].apply(lambda x: os.path.exists(os.path.join(manual_folder, x)))

print(df_drive_train[['image_exists', 'mask_exists', 'manual1_exists']].sum())

test_images = os.listdir('/content/drive_data/DRIVE/test/images')
test_ids = sorted([get_id_number(f) for f in test_images])

test_pairs = []
for id_num in test_ids:
    test_pairs.append({
        'id': id_num,
        'image': f'{id_num}_test.tif',
        'mask': f'{id_num}_test_mask.gif'
    })

df_drive_test = pd.DataFrame(test_pairs)

test_image_folder = '/content/drive_data/DRIVE/test/images'
test_mask_folder = '/content/drive_data/DRIVE/test/mask'

df_drive_test['image_exists'] = df_drive_test['image'].apply(lambda x: os.path.exists(os.path.join(test_image_folder, x)))
df_drive_test['mask_exists'] = df_drive_test['mask'].apply(lambda x: os.path.exists(os.path.join(test_mask_folder, x)))

print(df_drive_test.shape)
print(df_drive_test[['image_exists', 'mask_exists']].sum())