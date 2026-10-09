import os
import zipfile
from PIL import Image, ImageDraw, ImageFont

fig_dir = r'report\figures'
figs = [
    ('Figure 1: Four-Tier System Architecture', os.path.join(fig_dir, 'system_architecture.png')),
    ('Figure 2: Data Processing Pipeline Flowchart', os.path.join(fig_dir, 'fig_flowchart.png')),
    ('Figure 3: In-Cabin Physical Hardware Prototype', os.path.join(fig_dir, 'hardware_prototype.png')),
    ('Figure 4: Flutter Mobile App Interface (HUD, Dead Zone, Geofence)', os.path.join(fig_dir, 'fig_mobile_hud.png')),
    ('Figure 5: React Fleet Operations Command Dashboard', os.path.join(fig_dir, 'fig_fleet_dashboard.png'))
]

# 1. Zip all figures together
zip_path = 'all_paper_figures.zip'
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for label, path in figs:
        if os.path.exists(path):
            filename = os.path.basename(path)
            zf.write(path, arcname=filename)
print(f"Created zip archive: {zip_path}")

# 2. Build a high-res combined master sheet
target_w = 1200
target_h = 675

collage_w = 2500
collage_h = 3 * (target_h + 80) + 120

collage = Image.new('RGB', (collage_w, collage_h), color=(15, 23, 42))
draw = ImageDraw.Draw(collage)

positions = [
    (50, 100),                  # Fig 1 (Top Left)
    (1250, 100),                # Fig 2 (Top Right)
    (50, 100 + target_h + 80),  # Fig 3 (Mid Left)
    (1250, 100 + target_h + 80),# Fig 4 (Mid Right)
    (650, 100 + (target_h + 80)*2) # Fig 5 (Bottom Center)
]

for (label, path), (x, y) in zip(figs, positions):
    if os.path.exists(path):
        img = Image.open(path).convert('RGB')
        img_resized = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
        collage.paste(img_resized, (x, y))
        draw.text((x + 10, y - 30), label, fill=(56, 189, 248))
        draw.rectangle([x - 2, y - 2, x + target_w + 2, y + target_h + 2], outline=(51, 65, 85), width=3)

collage.save('all_project_figures_combined.png', 'PNG', quality=95)
collage.save(r'report\figures\all_project_figures_combined.png', 'PNG', quality=95)
collage.save(r'C:\Users\prana\.gemini\antigravity-ide\brain\c973ae0b-3996-4347-ad65-a29f5dd77614\all_project_figures_combined.png', 'PNG', quality=95)
print("Successfully generated all_project_figures_combined.png!")
