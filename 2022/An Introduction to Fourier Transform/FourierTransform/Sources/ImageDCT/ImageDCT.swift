//
//  File.swift
//  
//
//  Created by YuAo on 2022/2/14.
//

import Foundation
import Accelerate

public enum ImageDCT {
    public struct FrequencyData {
        public let data: [Float]
        public let width: Int
        public let height: Int
        
        // https://en.wikipedia.org/wiki/JPEG
        private func zigzag(count: Int, _ action: (_ row: Int, _ col: Int) -> Void) {
            precondition(width == height)
            let n = width
            var counter = 0
            for diag in 0..<(2 * n - 1) {
                let minIndex = max(0, diag - n + 1)
                let maxIndex = minIndex + min(diag, 2 * (n - 1) - diag)
                for i in minIndex...maxIndex {
                    if counter >= count {
                        break
                    }
                    let row = diag % 2 != 0 ? i : (diag - i)
                    let col = diag % 2 != 0 ? (diag - i) : i
                    action(row, col)
                    counter += 1
                }
            }
        }
        
        public func dropLast(_ nElement: Int) -> FrequencyData {
            precondition(width == height)
            precondition(nElement <= width * height)
            var data = self.data
            zigzag(count: nElement, { row, col in
                data[(height - row - 1) * width + (width - col - 1)] = 0
            })
            return FrequencyData(data: data, width: width, height: height)
        }
        
        public func dropFirst(_ nElement: Int) -> FrequencyData {
            precondition(width == height)
            precondition(nElement <= width * height)
            var data = self.data
            zigzag(count: nElement, { row, col in
                data[row * width + col] = 0
            })
            return FrequencyData(data: data, width: width, height: height)
        }
    }
    
    public static func forward(_ image: GrayscaleImage) -> FrequencyData {
        var data: [Float] = image.bitmap.map({ Float($0) - 128 })
        let rowDCT = vDSP.DCT(count: image.width, transformType: .II)!
        for y in 0..<image.height {
            let row = data[y * image.width..<(y+1) * image.width]
            data[y * image.width..<(y+1) * image.width] = ArraySlice(rowDCT.transform(row))
        }
        let columnDCT = vDSP.DCT(count: image.height, transformType: .II)!
        for x in 0..<image.width {
            let input = (0..<image.height).map({
                data[$0 * image.width + x]
            })
            let output = columnDCT.transform(input)
            for y in 0..<image.height {
                data[y * image.width + x] = output[y]
            }
        }
        return FrequencyData(data: data, width: image.width, height: image.height)
    }
    
    public static func inverse(_ frequencyData: FrequencyData) -> GrayscaleImage {
        // https://developer.apple.com/documentation/accelerate/signal_extraction_from_noise
        // The scaling factor for the forward transform is 2, and the scaling factor for the inverse transform is the number of samples. Divide the inverse DCT result by `count / 2` to return a signal with the correct amplitude.
        
        var data = frequencyData.data
        let columnInverseDCT = vDSP.DCT(count: frequencyData.height, transformType: .III)!
        let columnScale = 1.0 / (Float(frequencyData.height) / 2)
        for x in 0..<frequencyData.width {
            let input = (0..<frequencyData.height).map({
                data[$0 * frequencyData.width + x]
            })
            let output = columnInverseDCT.transform(input)
            for y in 0..<frequencyData.height {
                data[y * frequencyData.width + x] = output[y] * columnScale
            }
        }
        let rowInverseDCT = vDSP.DCT(count: frequencyData.width, transformType: .III)!
        let rowScale = 1.0 / (Float(frequencyData.width) / 2)
        for y in 0..<frequencyData.height {
            let row = data[y * frequencyData.width..<(y+1) * frequencyData.width]
            data[y * frequencyData.width..<(y+1) * frequencyData.width] = ArraySlice(rowInverseDCT.transform(row).map({ $0 * rowScale }))
        }
        let bitmapData = data.map({ UInt8(clamping: Int(round($0)) + 128) })
        return GrayscaleImage(width: frequencyData.width, height: frequencyData.height, bitmap: bitmapData)
    }
}
