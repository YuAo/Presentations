//
//  File.swift
//  
//
//  Created by YuAo on 2022/2/14.
//

import Foundation
import SwiftUI
import ImageDCT

extension GrayscaleImage {
    var aspectRatio: CGFloat { CGFloat(width) / CGFloat(height) }
    var cgImage: CGImage! {
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: CGDataProvider(data: Data(self.bitmap) as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}

struct GrayscaleImageView: View {
    let image: GrayscaleImage
    let pixelSpacing: CGFloat = 0
    var body: some View {
        Image(nsImage: NSImage(cgImage: image.cgImage, size: CGSize(width: image.width, height: image.height)))
            .interpolation(.none)
            .resizable()
            .aspectRatio(image.aspectRatio, contentMode: .fit)
    }
}

class ImageDCTExperimentController: ObservableObject {
    let originalImage: GrayscaleImage = {
        let image = NSImage(contentsOf: Bundle.module.url(forResource: "flower", withExtension: "png")!)!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        return GrayscaleImage(cgImage: image, size: 64)
    }()
    
    @Published private(set) var restoredImage: GrayscaleImage
    
    @Published var compression: Float {
        didSet {
            self.updateImage()
        }
    }
    
    init() {
        self.compression = 0
        self.restoredImage = self.originalImage
    }
    
    private func updateImage() {
        let frequencyData = ImageDCT.forward(self.originalImage)
        let compressed = frequencyData.dropLast(Int(Float(frequencyData.data.count) * self.compression))
        self.restoredImage = ImageDCT.inverse(compressed)
    }
}

struct ImageDCTExperimentView: View {
    @StateObject private var controller = ImageDCTExperimentController()
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                VStack {
                    GrayscaleImageView(image: controller.originalImage)
                    Text("Original")
                }
                VStack {
                    GrayscaleImageView(image: controller.restoredImage)
                    Text("Restored")
                }
            }
            Spacer()
            HStack {
                Text("Compression")
                Slider(value: $controller.compression, in: 0...1)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color( NSColor.controlBackgroundColor)))
        }
        .padding()
        .toolbar(content: { Spacer() })
        .navigationTitle("Image DCT")
    }
}
