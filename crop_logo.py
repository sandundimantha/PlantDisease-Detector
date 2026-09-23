import sys
from PIL import Image

def crop_center_square(img_path, out_path):
    try:
        img = Image.open(img_path)
        width, height = img.size
        
        # The image has blurred borders on left/right. We need to extract the center square.
        # It looks like the main logo is a square in the center. Let's make it square based on height.
        # But wait, looking at the image, it's a 16:9 or similar with the square in the center.
        # The actual square might be slightly smaller than the height, let's just take a center square of size min(width, height)
        size = min(width, height)
        
        left = (width - size) / 2
        top = (height - size) / 2
        right = (width + size) / 2
        bottom = (height + size) / 2
        
        img_cropped = img.crop((left, top, right, bottom))
        img_cropped.save(out_path)
        print(f"Successfully cropped image from {width}x{height} to {size}x{size} and saved to {out_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    crop_center_square("assets/images/logo.png", "assets/images/logo_cropped.png")
