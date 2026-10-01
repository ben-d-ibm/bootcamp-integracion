#!/usr/bin/env bash

# Script to crop the browser top bar/tabs (242px) from images.
# Default target: image_bootcamp_07.png to image_bootcamp_71.png (and any 3456x2234 image)

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

echo "Running image crop script..."

swift - << 'EOF'
import Foundation
import CoreGraphics
import ImageIO

let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath

let files = (try? fileManager.contentsOfDirectory(atPath: currentDir)) ?? []
let pngFiles = files.filter { $0.hasPrefix("image_bootcamp_") && $0.hasSuffix(".png") }.sorted()

var croppedCount = 0

for file in pngFiles {
    let url = URL(fileURLWithPath: file)
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        continue
    }

    let w = cgImage.width
    let h = cgImage.height

    // Only crop full screenshots containing the top browser bar (3456x2234)
    if w == 3456 && h == 2234 {
        let cropTopPixels = 242
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
            print("✂️  Cropped \(file): \(w)x\(h) -> \(cropped.width)x\(cropped.height)")
            croppedCount += 1
        } else {
            print("❌ Failed to save: \(file)")
        }
    }
}

print("\nFinished. Total images cropped: \(croppedCount)")
EOF
