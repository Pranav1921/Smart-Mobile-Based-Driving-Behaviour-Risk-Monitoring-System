import cv2
import numpy as np
from PIL import Image

def process_image(img_path, out_path, rect_margin=(20, 20, 20, 20), remove_red_pin=False):
    # Load image
    img = cv2.imread(img_path)
    h, w = img.shape[:2]

    # Create mask for GrabCut
    mask = np.zeros((h, w), np.uint8)
    bgdModel = np.zeros((1, 65), np.float64)
    fgdModel = np.zeros((1, 65), np.float64)

    # Define rectangle containing the vehicle
    top, bottom, left, right = rect_margin
    rect = (left, top, w - left - right, h - top - bottom)

    cv2.grabCut(img, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)

    # In GrabCut: 0 and 2 are background, 1 and 3 are foreground
    fg_mask = np.where((mask == 1) | (mask == 3), 255, 0).astype('uint8')

    if remove_red_pin:
        # For bike, remove the red pin if it got included
        # Red in HSV: H in [0, 10] or [170, 180], S > 100, V > 100
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        lower_red1 = np.array([0, 120, 100])
        upper_red1 = np.array([10, 255, 255])
        lower_red2 = np.array([170, 120, 100])
        upper_red2 = np.array([180, 255, 255])
        red_mask = cv2.inRange(hsv, lower_red1, upper_red1) | cv2.inRange(hsv, lower_red2, upper_red2)
        # Only in the lower right quadrant where the pin is located
        red_mask[:int(h*0.5), :] = 0
        red_mask[:, :int(w*0.5)] = 0
        # Dilate slightly and remove from fg_mask
        red_dilated = cv2.dilate(red_mask, np.ones((7, 7), np.uint8))
        fg_mask[red_dilated > 0] = 0

    # Smooth the mask edges
    fg_mask = cv2.GaussianBlur(fg_mask, (3, 3), 0)

    # Convert BGR to BGRA
    b, g, r = cv2.split(img)
    rgba = cv2.merge([b, g, r, fg_mask])

    # Crop to bounding box with small padding
    contours, _ = cv2.findContours((fg_mask > 50).astype('uint8'), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        # Find largest contour (the vehicle)
        c = max(contours, key=cv2.contourArea)
        x, y, bw, bh = cv2.boundingRect(c)
        pad = 12
        x1 = max(0, x - pad)
        y1 = max(0, y - pad)
        x2 = min(w, x + bw + pad)
        y2 = min(h, y + bh + pad)
        cropped = rgba[y1:y2, x1:x2]
    else:
        cropped = rgba

    cv2.imwrite(out_path, cropped)
    print(f"Saved: {out_path} ({cropped.shape[1]}x{cropped.shape[0]})")

bike_src = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\top_view_bike_1791451429685.jpg'
car_src = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\top_view_car_1791451451702.jpg'
truck_src = r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\top_view_truck_1791451471624.jpg'

process_image(bike_src, r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\clean_bike.png', (15, 15, 40, 40), remove_red_pin=True)
process_image(car_src, r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\clean_car.png', (30, 30, 80, 80))
process_image(truck_src, r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\clean_truck.png', (30, 30, 80, 80))
