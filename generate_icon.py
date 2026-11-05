import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFilter

def create_app_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background macOS Squircle with rounded corners
    margin = 80
    corner_radius = 210
    
    # Outer ambient glow behind icon
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.rounded_rectangle(
        [margin - 10, margin - 10, size - margin + 10, size - margin + 10],
        radius=corner_radius + 10,
        fill=(255, 42, 133, 90)
    )
    glow = glow.filter(ImageFilter.GaussianBlur(35))
    img.paste(glow, (0, 0), glow)

    # Base squircle surface
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base_draw = ImageDraw.Draw(base)
    base_draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=(15, 14, 25, 255)
    )

    # Liquid gradient overlay inside squircle
    grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(grad)
    for y in range(margin, size - margin):
        factor = (y - margin) / float(size - 2 * margin)
        # Deep violet to magenta to cyan
        r = int(35 + (235 - 35) * math.sin(factor * math.pi * 0.8))
        g = int(20 + (50 - 20) * factor + 180 * math.sin(factor * math.pi * 0.5) * (1 - factor))
        b = int(60 + (220 - 60) * factor)
        grad_draw.line([(margin, y), (size - margin, y)], fill=(r, g, b, 230))
    
    # Mask gradient to rounded rect
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=255
    )
    base.paste(grad, (0, 0), mask)

    # Inner glass sheen (top-left specular highlight)
    sheen = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sheen_draw = ImageDraw.Draw(sheen)
    sheen_draw.ellipse(
        [margin + 40, margin + 20, size - margin - 40, margin + 440],
        fill=(255, 255, 255, 50)
    )
    sheen = sheen.filter(ImageFilter.GaussianBlur(50))
    base.paste(sheen, (0, 0), mask)

    # Central Liquid Drop and Sparkles Emblem
    emblem = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    emblem_draw = ImageDraw.Draw(emblem)
    cx, cy = size // 2, size // 2 + 20

    # Draw central glowing liquid teardrop
    # Top point (cx, cy - 180), bottom round (cx, cy + 120, r=140)
    drop_points = []
    # top vertex
    drop_points.append((cx, cy - 170))
    # bezier-approximated sides into bottom semicircle
    for angle in range(0, 181):
        rad = math.radians(angle)
        px = cx + 140 * math.cos(rad)
        py = cy + 40 + 130 * math.sin(rad)
        drop_points.append((px, py))
    emblem_draw.polygon(drop_points, fill=(255, 255, 255, 240))
    
    # Inner drop gradient highlight
    inner_drop = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(inner_drop).ellipse(
        [cx - 85, cy - 30, cx + 85, cy + 140],
        fill=(0, 240, 255, 180)
    )
    inner_drop = inner_drop.filter(ImageFilter.GaussianBlur(25))
    emblem.paste(inner_drop, (0, 0), inner_drop)

    # Sparkle star
    star_x, star_y = cx + 150, cy - 130
    for w, h in [(60, 10), (10, 60)]:
        emblem_draw.ellipse([star_x - w, star_y - h, star_x + w, star_y + h], fill=(255, 255, 255, 230))

    base.paste(emblem, (0, 0), emblem)

    # Liquid glass rim stroke
    rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    rim_draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        outline=(255, 255, 255, 110),
        width=3
    )
    base.paste(rim, (0, 0), rim)

    img.paste(base, (0, 0), base)

    # Generate iconset
    iconset_dir = "AppIcon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    os.makedirs("Resources", exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png")
    ]

    for s, name in sizes:
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, name))

    # Convert to .icns
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", "Resources/AppIcon.icns"], check=True)
    print("Successfully generated Resources/AppIcon.icns")

if __name__ == "__main__":
    create_app_icon()
