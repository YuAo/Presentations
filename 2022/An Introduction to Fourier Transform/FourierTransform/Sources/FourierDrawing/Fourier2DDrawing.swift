import CoreGraphics
import Numerics
import PathUtilities

public struct Fourier2DDrawing: FourierDrawing {
    public let bounds: CGRect
    
    // -n ... -1, 0, 1, 2 ... n
    public let frequencyComponents: [ComplexNumber]
    
    public let maximumFrequency: Int
    
    public let samples: [ComplexNumber]
    
    public init(path: CGPath, maximumFrequency: Int) {
        self.maximumFrequency = maximumFrequency
        let componentCount = maximumFrequency * 2 + 1
        
        let pathElements = path.elements
        var samples: [ComplexNumber] = []
        for i in 0..<Int(pathElements.pathLength) {
            if let p = pathElements.point(atPathLength: CGFloat(i)) {
                samples.append(Complex(p.x, p.y))
            }
        }
        self.samples = samples
        
        // fourier transform
        var components = [ComplexNumber](repeating: .zero, count: componentCount)
        var index = 0
        for frequency in -maximumFrequency...maximumFrequency {
            var sum: ComplexNumber = .zero
            for (index, sample) in samples.enumerated() {
                let t = Double(index) / Double(samples.count)
                // e^(-f * 2 * pi * t * i)
                let applier = ComplexNumber.exp(
                    ComplexNumber(-Double(frequency) * 2 * .pi * Double(t))
                    *
                    ComplexNumber.i
                )
                // sum += f(t) * e^(-f * 2 * pi * t * i)
                sum += applier * sample
            }
            sum /= ComplexNumber(samples.count)
            components[index] = sum
            index += 1
        }
        
        self.bounds = path.boundingBox.insetBy(dx: -path.boundingBox.width/2, dy: -path.boundingBox.height/2)
        self.frequencyComponents = components
    }
    
    public func enumerateVectorsForDrawing(at time: Double, invoking body: (FrequencyComponent) throws -> Void) rethrows {
        
        func componentForFrequency(_ f: Int, at time: Double) -> FrequencyComponent {
            let index = maximumFrequency + f
            let component = frequencyComponents[index]
            let value = component * ComplexNumber.exp(
                ComplexNumber(Double(f) * 2 * .pi * time) * ComplexNumber.i
            )
            return FrequencyComponent(frequency: f, value: value)
        }
        
        try body(componentForFrequency(0, at: time))
        for i in 1...maximumFrequency {
            try body(componentForFrequency(i, at: time))
            try body(componentForFrequency(-i, at: time))
        }
    }
}
