#!/usr/bin/env python3
"""
Create a Nexus icon for the desktop launcher.
Generates a PNG icon with the Nexus logo.
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_nexus_icon(size=512):
    """Create a Nexus icon."""

    # Create image with dark background
    img = Image.new('RGB', (size, size), color='#0a0e27')
    draw = ImageDraw.Draw(img)

    # Draw outer glow circle
    for i in range(20):
        alpha = int(255 * (1 - i/20))
        offset = i * 3
        draw.ellipse(
            [offset, offset, size-offset, size-offset],
            fill=f'#{hex(alpha)[2:].zfill(2)}4477ff'
        )

    # Draw main circle (neural network node)
    margin = size // 4
    draw.ellipse(
        [margin, margin, size-margin, size-margin],
        fill='#1a1f3a',
        outline='#4477ff',
        width=8
    )

    # Draw inner circle
    inner_margin = margin + size // 12
    draw.ellipse(
        [inner_margin, inner_margin, size-inner_margin, size-inner_margin],
        fill='#0a0e27',
        outline='#6699ff',
        width=4
    )

    # Draw connecting nodes (representing the 5 cores)
    core_positions = [
        (size//2, margin),  # Top (Central Nexus)
        (margin + 30, size//2),  # Left
        (size - margin - 30, size//2),  # Right
        (size//2 - 60, size - margin - 20),  # Bottom left
        (size//2 + 60, size - margin - 20),  # Bottom right
    ]

    center = (size//2, size//2)

    # Draw connections from center to cores
    for pos in core_positions:
        draw.line([center, pos], fill='#4477ff', width=3)

    # Draw core nodes
    for pos in core_positions:
        node_size = 20
        draw.ellipse(
            [pos[0]-node_size, pos[1]-node_size, pos[0]+node_size, pos[1]+node_size],
            fill='#6699ff',
            outline='#88bbff',
            width=2
        )

    # Draw center node (larger)
    center_size = 30
    draw.ellipse(
        [center[0]-center_size, center[1]-center_size,
         center[0]+center_size, center[1]+center_size],
        fill='#4477ff',
        outline='#88bbff',
        width=3
    )

    # Try to add text
    try:
        # Try to load a font
        font_size = size // 8
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
        except:
            font = ImageFont.load_default()

        # Draw 'N' in the center
        text = "N"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_position = ((size - text_width) // 2, (size - text_height) // 2 - font_size // 4)

        draw.text(text_position, text, fill='#ffffff', font=font)
    except Exception as e:
        print(f"Warning: Could not add text to icon: {e}")

    return img


def main():
    """Generate icons in multiple sizes."""
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Create icons directory
    icons_dir = os.path.join(script_dir, 'icons')
    os.makedirs(icons_dir, exist_ok=True)

    # Generate icons in standard sizes
    sizes = [512, 256, 128, 64, 48, 32, 16]

    print("🎨 Creating Nexus icons...")

    for size in sizes:
        icon = create_nexus_icon(size)
        icon_path = os.path.join(icons_dir, f'nexus_{size}.png')
        icon.save(icon_path)
        print(f"  ✓ Created {size}x{size} icon")

    # Save main icon
    main_icon = create_nexus_icon(512)
    main_icon_path = os.path.join(script_dir, 'nexus_icon.png')
    main_icon.save(main_icon_path)

    print(f"\n✅ Icon created successfully!")
    print(f"   Main icon: {main_icon_path}")
    print(f"   All sizes: {icons_dir}/")


if __name__ == "__main__":
    # Check if PIL is available
    try:
        import PIL
        main()
    except ImportError:
        print("⚠️  Pillow not installed. Installing...")
        import subprocess
        subprocess.run(["pip", "install", "pillow"])
        print("✓ Pillow installed. Running icon creation...")
        main()
