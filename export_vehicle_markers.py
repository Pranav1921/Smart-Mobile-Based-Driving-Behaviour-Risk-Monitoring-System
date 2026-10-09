import cv2
import numpy as np
import os
import shutil

# Paths
bike_jpg = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\top_view_bike_chroma_1791451700589.jpg'
truck_jpg = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\top_view_truck_chroma_1791451674023.jpg'
clean_car_png = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\clean_car.png'

dest_dashboard = r'c:\projects\Major_project\dashboard\public\markers'
dest_mobile = r'c:\projects\Major_project\MobileApp\assets\images'

os.makedirs(dest_dashboard, exist_ok=True)
os.makedirs(dest_mobile, exist_ok=True)

def cutout_black_bg(img_path, rotate_180=False, threshold=12):
    img = cv2.imread(img_path)
    if rotate_180:
        img = cv2.rotate(img, cv2.ROTATE_180)
    
    # Compute max intensity across channels
    max_c = np.max(img, axis=2)
    
    # Create binary mask where pixels are above threshold
    # To avoid cutting dark parts inside vehicle, we flood fill from the 4 corners of the image
    h, w = img.shape[:2]
    # Background seed points: borders
    bg_mask = np.zeros((h+2, w+2), np.uint8)
    
    # We flood fill dark areas connected to image edges
    # Create edge-connected background mask
    dark = (max_c <= threshold).astype(np.uint8)
    # FloodFill from (0,0)
    cv2.floodFill(dark, None, (0, 0), 2, loDiff=0, upDiff=0)
    cv2.floodFill(dark, None, (w-1, 0), 2, loDiff=0, upDiff=0)
    cv2.floodFill(dark, None, (0, h-1), 2, loDiff=0, upDiff=0)
    cv2.floodFill(dark, None, (w-1, h-1), 2, loDiff=0, upDiff=0)
    
    # Also floodfill outer frame points
    for step in range(0, w, 50):
        if max_c[0, step] <= threshold and dark[0, step] != 2:
            cv2.floodFill(dark, None, (step, 0), 2)
        if max_c[h-1, step] <= threshold and dark[h-1, step] != 2:
            cv2.floodFill(dark, None, (step, h-1), 2)
    for step in range(0, h, 50):
        if max_c[step, 0] <= threshold and dark[step, 0] != 2:
            cv2.floodFill(dark, None, (0, step), 2)
        if max_c[step, w-1] <= threshold and dark[step, w-1] != 2:
            cv2.floodFill(dark, None, (w-1, step), 2)

    # Foreground is everything not floodfilled as 2
    fg = (dark != 2).astype(np.uint8) * 255
    
    # Smooth mask
    fg = cv2.GaussianBlur(fg, (3, 3), 0)
    
    b, g, r = cv2.split(img)
    rgba = cv2.merge([b, g, r, fg])
    
    # Crop to non-zero alpha bounding box
    coords = np.argwhere(fg > 20)
    y0, x0 = coords.min(axis=0)
    y1, x1 = coords.max(axis=0) + 1
    
    pad = 8
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(w, x1 + pad)
    y1 = min(h, y1 + pad)
    
    return rgba[y0:y1, x0:x1]

# Process bike
bike_rgba = cutout_black_bg(bike_jpg, rotate_180=False, threshold=15)
cv2.imwrite(os.path.join(dest_dashboard, 'vehicle_bike.png'), bike_rgba)
cv2.imwrite(os.path.join(dest_mobile, 'vehicle_bike.png'), bike_rgba)
print("Bike saved:", bike_rgba.shape)

# Process truck
truck_rgba = cutout_black_bg(truck_jpg, rotate_180=True, threshold=15)
cv2.imwrite(os.path.join(dest_dashboard, 'vehicle_truck.png'), truck_rgba)
cv2.imwrite(os.path.join(dest_mobile, 'vehicle_truck.png'), truck_rgba)
print("Truck saved:", truck_rgba.shape)

# Process car
car_img = cv2.imread(clean_car_png, cv2.IMREAD_UNCHANGED)
cv2.imwrite(os.path.join(dest_dashboard, 'vehicle_car.png'), car_img)
cv2.imwrite(os.path.join(dest_mobile, 'vehicle_car.png'), car_img)
print("Car saved:", car_img.shape)
