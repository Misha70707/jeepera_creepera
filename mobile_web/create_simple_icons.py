from PIL import Image, ImageDraw, ImageFont

# Create 192x192 icon
img192 = Image.new('RGB', (192, 192), color='#4477ff')
draw = ImageDraw.Draw(img192)
draw.ellipse([20, 20, 172, 172], fill='#6699ff')
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 80)
except:
    font = ImageFont.load_default()
draw.text((60, 50), "N", fill='white', font=font)
img192.save('static/icon-192.png')

# Create 512x512 icon
img512 = Image.new('RGB', (512, 512), color='#4477ff')
draw = ImageDraw.Draw(img512)
draw.ellipse([50, 50, 462, 462], fill='#6699ff')
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 220)
except:
    font = ImageFont.load_default()
draw.text((160, 130), "N", fill='white', font=font)
img512.save('static/icon-512.png')

print("✓ Icons created!")
