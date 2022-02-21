//
//  File.swift
//  
//
//  Created by YuAo on 2022/2/14.
//

import Foundation
import CoreGraphics

public struct GrayscaleImage {
    public init(width: Int, height: Int, bitmap: [UInt8]) {
        self.width = width
        self.height = height
        self.bitmap = bitmap
    }
    
    public let width: Int
    public let height: Int
    public let bitmap: [UInt8]
    
    public init(cgImage: CGImage, size: Int = 32) {
        let width = size
        let height = size
        var data = [UInt8](repeating: 0, count: width * height)
        data.withUnsafeMutableBytes({ ptr in
            let context = CGContext(data: ptr.baseAddress!,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: width,
                                    space: CGColorSpaceCreateDeviceGray(),
                                    bitmapInfo: CGImageAlphaInfo.none.rawValue)
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        })
        self.width = width
        self.height = height
        self.bitmap = data
    }
}
