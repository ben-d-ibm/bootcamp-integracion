#!/usr/bin/env bash

# Script to crop the top warning banner ("Updating assets can impact...")
# Applies to images from image_bootcamp_07.png to image_bootcamp_47.png (except image_bootcamp_44.png)

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

echo "Running warning banner crop script..."

swift - << 'EOF'
import Foundation
import CoreGraphics
import ImageIO

let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath

// Target: 07 to 47 inclusive, skipping 44
var targets = Set<String>()
for i in 7...47 {
    if i == 44 { continue }
    targets.insert(String(format: "image_bootcamp_%02d.png", i))
}

var croppedCount = 0

for file in targets.sorted() {
    let url = URL(fileURLWithPath: file)
    guard fileManager.fileExists(atPath: file),
          let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("⚠️ Could not open: \(file)")
        continue
    }

    let w = cgImage.width
    let h = cgImage.height

    let cropTopPixels = 50
    guard h > cropTopPixels else {
        print("⚠️ Image too small to crop: \(file)")
        continue
    }

    let cropRect = CGRect(x: 0, y: cropTopPixels, width: w, height: h - cropTopPixels)
    guard let cropped = cgImage.cropping(to: cropRect) else {
        print("❌ Failed to crop: \(file)")
        continue
    }

    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        print("❌ Failed to create destination for: \(file)")
        continue
    }

    CGImageDestinationAddImage(dest, cropped, nil)
    if CGImageDestinationFinalize(dest) {
        print("✂️  Cropped banner from \(file): \(w)x\(h) -> \(cropped.width)x\(cropped.height)")
        croppedCount += 1
    } else {
        print("❌ Failed to save: \(file)")
    }
}

print("\nFinished. Total images cropped: \(croppedCount)")
EOF
