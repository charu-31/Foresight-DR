from google.colab import drive
drive.mount('/content/drive', force_remount=True, timeout_ms=120000)
import os
print(os.listdir('/content/drive/MyDrive'))
import zipfile

with zipfile.ZipFile('/content/drive/MyDrive/archive.zip', 'r') as zip_ref:
    zip_ref.extractall('/content/aptos_data')
import pandas as pd

df = pd.read_csv('/content/aptos_data/train_1.csv')
print(df.head())
print(df.shape)

df_valid = pd.read_csv('/content/aptos_data/valid.csv')
print(df_valid.head())
print(df_valid.shape)

df_test = pd.read_csv('/content/aptos_data/test.csv')
print(df_test.head())
print(df_test.shape)
import shutil
import os

os.makedirs('/content/aptos_data/all_images', exist_ok=True)

for folder in ['train_images', 'val_images', 'test_images']:
    folder_path = f'/content/aptos_data/{folder}/{folder}'
    for filename in os.listdir(folder_path):
        src = os.path.join(folder_path, filename)
        dst = os.path.join('/content/aptos_data/all_images', filename)
        shutil.copy(src, dst)

print(len(os.listdir('/content/aptos_data/all_images')))

from sklearn.model_selection import train_test_split

train_df, temp_df = train_test_split(
    df_combined,
    test_size=0.30,
    stratify=df_combined['diagnosis'],
    random_state=42
)

val_df, test_df = train_test_split(
    temp_df,
    test_size=0.50,
    stratify=temp_df['diagnosis'],
    random_state=42
)

print("Train:", train_df.shape)
print("Val:", val_df.shape)
print("Test:", test_df.shape)

print("Train class distribution:")
print(train_df['diagnosis'].value_counts(normalize=True).sort_index())

print("\nVal class distribution:")
print(val_df['diagnosis'].value_counts(normalize=True).sort_index())

print("\nTest class distribution:")
print(test_df['diagnosis'].value_counts(normalize=True).sort_index())

train_df.to_csv('/content/aptos_data/train_split.csv', index=False)
val_df.to_csv('/content/aptos_data/val_split.csv', index=False)
test_df.to_csv('/content/aptos_data/test_split.csv', index=False)

import shutil

shutil.copy('/content/aptos_data/train_split.csv', '/content/drive/MyDrive/train_split.csv')
shutil.copy('/content/aptos_data/val_split.csv', '/content/drive/MyDrive/val_split.csv')
shutil.copy('/content/aptos_data/test_split.csv', '/content/drive/MyDrive/test_split.csv')
