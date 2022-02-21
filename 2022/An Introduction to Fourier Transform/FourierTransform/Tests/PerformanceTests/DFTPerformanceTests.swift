import XCTest
import Numerics
import FourierDrawing

final class DFTPerformanceTests: XCTestCase {
    static let realSamples: [Double] = {
        let n = 1024
        let samples = (0..<n).map({ (i: Int) -> Double in
            let t = Double(i)/(Double(n)/(.pi * 2.0))
            return (sin(t) + abs(sin(2 * t)) + sin(5 * t) + cos(6 * t) + sin(12 * t)) * 64
        })
        return samples
    }()
    
    static let complexSamples: [ComplexNumber] = {
        return realSamples.map({ ComplexNumber($0) })
    }()
    
    func testStraightDFTForward() throws {
        measure {
            let _ = DFT.forward(Self.complexSamples)
        }
    }
    
    func testFFTForward() throws {
        measure {
            let _ = FFT.forward(Self.complexSamples)
        }
    }
    
    func testFFTvDSPForward() throws {
        measure {
            let _ = FFT_vDSP.forward(Self.realSamples)
        }
    }
}
