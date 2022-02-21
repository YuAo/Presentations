//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/24.
//

import Foundation
import Numerics
import Accelerate

public enum DFT {
    public static func forward(_ samples: [ComplexNumber]) -> [ComplexNumber] {
        var components = [ComplexNumber](repeating: .zero, count: samples.count)
        var index = 0
        for frequency in 0..<samples.count {
            var sum: ComplexNumber = .zero
            for (index, sample) in samples.enumerated() {
                let t = Double(index) / Double(samples.count)
                let applier = ComplexNumber.exp(
                    ComplexNumber(-Double(frequency) * 2 * .pi * Double(t)) * ComplexNumber.i
                )
                sum += applier * sample
            }
            components[index] = sum
            index += 1
        }
        return components
    }
}

public struct Fourier1DDrawing: FourierDrawing {
    public let bounds: CGRect
    
    // 0, 1, 2 ...
    public let frequencyComponents: [ComplexNumber]
    
    public let maximumFrequency: Int
    
    public let samples: [ComplexNumber]
    
    public init(samples realSamples: [Double]) {
        precondition(realSamples.count > 0)
        
        self.maximumFrequency = realSamples.count
        let samples = realSamples.map({ ComplexNumber($0) })
        self.samples = samples
        
        do {
            let straightStart = CFAbsoluteTimeGetCurrent()
            let dftResult = DFT.forward(samples).map({
                $0 / ComplexNumber(Double(samples.count))
            })
            print("Straight DFT", CFAbsoluteTimeGetCurrent() - straightStart)
            self.frequencyComponents = dftResult
        }
        
        /*
        do {
            let fastStart = CFAbsoluteTimeGetCurrent()
            let fftResult = FFT.forward(samples).map({
                $0 / ComplexNumber(Double(samples.count))
            })
            print("Fast", CFAbsoluteTimeGetCurrent() - fastStart)
            self.frequencyComponents = fftResult
        }
        */
        
        /*
        do {
            let fftResult = FFT_vDSP.forward(realSamples).map({
                $0 / ComplexNumber(Double(samples.count))
            })
            self.frequencyComponents = fftResult
        }
        */
        
        let extent = max(abs(realSamples.max()!), abs(realSamples.min()!)) * 1.2
        self.bounds = CGRect(x: -extent, y: 0, width: extent * 2, height: 512)
    }
    
    public func enumerateVectorsForDrawing(at time: Double, invoking body: (FrequencyComponent) throws -> Void) rethrows {
        for i in 0..<maximumFrequency {
            // the actual frequency `f`
            let f = i > maximumFrequency / 2 ?  -(maximumFrequency - i) : i
            
            let component = frequencyComponents[i]
            let value = component * ComplexNumber.exp(
                ComplexNumber(
                    Double(i /* if we use `f` here, we are not limited to the 1/n time step in the `Fourier1DDrawingView` */ )
                    * 2 * .pi * time)
                * ComplexNumber.i
            )
            
            if i > maximumFrequency / 2 {
                try body(FrequencyComponent(frequency: f, value: value))
            } else {
                try body(FrequencyComponent(frequency: i, value: value))
            }
        }
    }
}
