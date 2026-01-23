#!/usr/bin/env python3
"""
Simple script to create a launcher icon for Agrilink app
Creates a 1024x1024 tractor icon using Python PIL
"""

from PIL import Image, ImageDraw
import os

def create_tractor_icon():
    # Create 1024x1024 image
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - Agricultural green theme (matching splash screen)
    green_bg = (46, 125, 50)   # Dark green background (matching splash)
    green_tractor = (76, 175, 80)  # Light green tractor color
    dark_green = (56, 142, 60)  # Medium green for cab/details
    white = (255, 255, 255)
    black = (50, 50, 50)
    gray = (150, 150, 150)
    yellow = (255, 235, 59)
    leaf_green = (139, 195, 74)  # For agricultural accent
    
    # Draw background circle
    margin = 20
    draw.ellipse([margin, margin, size-margin, size-margin], fill=green_bg)
    
    # Draw white border
    border_width = 8
    draw.ellipse([margin, margin, size-margin, size-margin], outline=white, width=border_width)
    
    # Calculate tractor position and size
    tractor_width = size * 0.5
    tractor_height = size * 0.3
    tractor_x = (size - tractor_width) // 2
    tractor_y = (size - tractor_height) // 2
    
    # Draw main tractor body (green agricultural theme)
    body_rect = [tractor_x, tractor_y + tractor_height*0.3, 
                 tractor_x + tractor_width*0.7, tractor_y + tractor_height*0.8]
    draw.rounded_rectangle(body_rect, radius=20, fill=green_tractor)
    
    # Draw cab (at back) - darker green
    cab_rect = [tractor_x + tractor_width*0.05, tractor_y + tractor_height*0.1,
                tractor_x + tractor_width*0.35, tractor_y + tractor_height*0.6]
    draw.rounded_rectangle(cab_rect, radius=15, fill=dark_green)
    
    # Draw window
    window_rect = [tractor_x + tractor_width*0.1, tractor_y + tractor_height*0.2,
                   tractor_x + tractor_width*0.28, tractor_y + tractor_height*0.45]
    draw.rounded_rectangle(window_rect, radius=8, fill=(173, 216, 230))
    
    # Draw engine grille
    grille_rect = [tractor_x + tractor_width*0.6, tractor_y + tractor_height*0.4,
                   tractor_x + tractor_width*0.68, tractor_y + tractor_height*0.65]
    draw.rectangle(grille_rect, fill=black)
    
    # Draw wheels
    # Rear wheel (larger)
    rear_wheel_center = (tractor_x + tractor_width*0.2, tractor_y + tractor_height*0.9)
    rear_wheel_radius = tractor_width * 0.08
    draw.ellipse([rear_wheel_center[0] - rear_wheel_radius, rear_wheel_center[1] - rear_wheel_radius,
                  rear_wheel_center[0] + rear_wheel_radius, rear_wheel_center[1] + rear_wheel_radius],
                 fill=black)
    draw.ellipse([rear_wheel_center[0] - rear_wheel_radius*0.7, rear_wheel_center[1] - rear_wheel_radius*0.7,
                  rear_wheel_center[0] + rear_wheel_radius*0.7, rear_wheel_center[1] + rear_wheel_radius*0.7],
                 fill=gray)
    
    # Front wheel (smaller)
    front_wheel_center = (tractor_x + tractor_width*0.65, tractor_y + tractor_height*0.85)
    front_wheel_radius = tractor_width * 0.06
    draw.ellipse([front_wheel_center[0] - front_wheel_radius, front_wheel_center[1] - front_wheel_radius,
                  front_wheel_center[0] + front_wheel_radius, front_wheel_center[1] + front_wheel_radius],
                 fill=black)
    draw.ellipse([front_wheel_center[0] - front_wheel_radius*0.7, front_wheel_center[1] - front_wheel_radius*0.7,
                  front_wheel_center[0] + front_wheel_radius*0.7, front_wheel_center[1] + front_wheel_radius*0.7],
                 fill=gray)
    
    # Draw headlight
    headlight_center = (tractor_x + tractor_width*0.67, tractor_y + tractor_height*0.45)
    headlight_radius = tractor_width * 0.02
    draw.ellipse([headlight_center[0] - headlight_radius, headlight_center[1] - headlight_radius,
                  headlight_center[0] + headlight_radius, headlight_center[1] + headlight_radius],
                 fill=yellow)
    
    return img

def main():
    print("🚜 Creating Agrilink Tractor Launcher Icon...")
    
    # Create the icon
    icon = create_tractor_icon()
    
    # Save as PNG
    os.makedirs('assets/icons', exist_ok=True)
    icon.save('assets/icons/app_icon.png', 'PNG')
    
    print("✅ Icon created successfully!")
    print("📁 Saved to: assets/icons/app_icon.png")
    print("🔧 Next steps:")
    print("   1. Run: flutter pub get")
    print("   2. Run: flutter pub run flutter_launcher_icons")
    print("   3. Build your app with the new icon!")

if __name__ == "__main__":
    main()