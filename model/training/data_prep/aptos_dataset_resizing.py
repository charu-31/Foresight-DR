Resize the data for CNN:
import cv2
import os

image_folder = '/content/aptos_data/all_images'
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
