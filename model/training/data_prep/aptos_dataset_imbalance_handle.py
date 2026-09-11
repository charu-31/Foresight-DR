print(train_df['diagnosis'].value_counts().sort_index())
create func that creates duplicated with changes:
import albumentations as A
import numpy as np

transform = A.Compose([
    A.Rotate(limit=25, p=0.7),
    A.HorizontalFlip(p=0.5),
    A.VerticalFlip(p=0.3),
    A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.5),
])
import cv2
import os

target_count = 400
classes_to_augment = [1, 3, 4]

augmented_rows = []

for class_id in classes_to_augment:
    class_df = train_df[train_df['diagnosis'] == class_id]
    current_count = len(class_df)
    needed = target_count - current_count
    
    print(f"Class {class_id}: have {current_count}, need {needed} more")
    
    for i in range(needed):
        row = class_df.sample(1).iloc[0]
        original_id = row['id_code']
        
        img_path = os.path.join(image_folder, original_id + '.png')
        img = cv2.imread(img_path)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        augmented = transform(image=img)['image']
        
        new_id = f"{original_id}_aug{i}"
        new_filename = new_id + '.png'
        
        augmented_bgr = cv2.cvtColor(augmented, cv2.COLOR_RGB2BGR)
        cv2.imwrite(os.path.join(image_folder, new_filename), augmented_bgr)
        
        augmented_rows.append({'id_code': new_id, 'diagnosis': class_id})

print(f"\nTotal augmented images created: {len(augmented_rows)}")
import pandas as pd

augmented_df = pd.DataFrame(augmented_rows)
print(augmented_df.shape)
print(augmented_df.head())

train_df = pd.concat([train_df, augmented_df], ignore_index=True)
print("\nNew train_df shape:", train_df.shape)
train_df.to_csv('/content/aptos_data/train_split.csv', index=False)

import shutil
shutil.copy('/content/aptos_data/train_split.csv', '/content/drive/MyDrive/train_split.csv')
