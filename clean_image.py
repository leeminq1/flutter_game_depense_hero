import sys
import os
from PIL import Image

def process_citadel(src_path, dest_path):
    print(f"Processing image: {src_path}")
    img = Image.open(src_path).convert("RGBA")
    width, height = img.size
    data = img.load()
    
    # 1. Background removal using flood-fill from edges
    # We sample the 4 corners. For AI images, usually the background is flat but sometimes noisy.
    
    # We'll use a tolerance-based flood fill mask
    visited = set()
    queue = []
    
    # Identify background color from top-left
    bg_color = data[0, 0]
    
    def color_distance(c1, c2):
        return sum(abs(a - b) for a, b in zip(c1[:3], c2[:3]))
    
    # Initial queue with edges
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
        
    for (x, y) in queue:
        visited.add((x, y))
        
    tolerance = 45 # A bit forgiving for compression artifacts

    while queue:
        x, y = queue.pop(0)
        curr_color = data[x, y]
        
        # If it's close to bg
        if color_distance(curr_color, bg_color) < tolerance:
            data[x, y] = (curr_color[0], curr_color[1], curr_color[2], 0) # Transparent
            
            # Add neighbors
            for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        queue.append((nx, ny))

    # Clean up fringing: any non-transparent pixel very close to bg color becomes transparent
    for x in range(width):
        for y in range(height):
            if data[x, y][3] != 0:
                if color_distance(data[x, y], bg_color) < tolerance * 0.8:
                    data[x, y] = (data[x, y][0], data[x, y][1], data[x, y][2], 0)

    # 2. Crop to bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"Cropped to original bounds: {bbox}")
    else:
        print("Warning: Image is completely empty after background removal.")
        
    # Scale it to a nice size if it's too large, say max 256x256 (it's a 1x1 or 2x2 sprite)
    new_w, new_h = img.size
    max_dim = 256
    if new_w > max_dim or new_h > max_dim:
        scale = max_dim / max(new_w, new_h)
        img = img.resize((int(new_w * scale), int(new_h * scale)), Image.Resampling.LANCZOS)
    
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    img.save(dest_path, "PNG")
    print(f"Saved cleanly to: {dest_path}")

if __name__ == "__main__":
    src = r"C:\Users\min21\.gemini\antigravity\brain\4acfc780-a0ad-4d76-86d4-d1cb59e3db2d\raw_citadel_1776472791403.png"
    dest = r"c:\Users\min21\Desktop\flutter_grame\depense_game\assets\sprites\environment\landmarks\central_citadel.png"
    
    if os.path.exists(src):
        process_citadel(src, dest)
    else:
        print(f"File not found: {src}")
