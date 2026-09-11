from google.colab import drive
drive.mount('/content/drive')
import os
print(os.listdir('/content/drive/MyDrive'))
import zipfile

with zipfile.ZipFile('/content/drive/MyDrive/messidor-2.zip', 'r') as zip_ref:
    zip_ref.extractall('/content/messidor2_data')

import os
print(os.listdir('/content/messidor2_data'))
import pandas as pd

df_messidor = pd.read_csv('/content/messidor2_data/messidor_data.csv')
print(df_messidor.shape)
print(df_messidor.head())
print(df_messidor['adjudicated_gradable'].value_counts())
print(df_messidor['diagnosis'].value_counts().sort_index())
print("\nAs percentages:")
print(df_messidor['diagnosis'].value_counts(normalize=True).sort_index())

import os

image_folder = '/content/messidor2_data/messidor-2/messidor-2/preprocess'
actual_files = set(os.listdir(image_folder))

df_messidor['file_exists'] = df_messidor['id_code'].apply(lambda x: x in actual_files)

print(f"Total rows: {len(df_messidor)}")
print(f"Matching files found: {df_messidor['file_exists'].sum()}")
print(f"Missing: {(~df_messidor['file_exists']).sum()}")