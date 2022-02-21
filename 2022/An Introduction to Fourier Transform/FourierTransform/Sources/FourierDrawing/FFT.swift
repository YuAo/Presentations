//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/24.
//

import Foundation
import Numerics
import Accelerate

public enum FFT {
    public static func forward(_ values: [ComplexNumber]) -> [ComplexNumber] {
        precondition(Int(pow(2, round(log2(Double(values.count))))) == values.count)
        
        let n = values.count
        if n == 1 {
            return values
        }
        var p1: [ComplexNumber] = [ComplexNumber](repeating: .zero, count: n/2)
        var p2: [ComplexNumber] = [ComplexNumber](repeating: .zero, count: n/2)
        for i in 0..<n {
            if i % 2 == 0 {
                p1[i/2] = values[i]
            } else {
                p2[i/2] = values[i]
            }
        }
        let (y1, y2) = (forward(p1), forward(p2))
        var result: [ComplexNumber] = [ComplexNumber](repeating: .zero, count: n)
        for i in 0..<n/2 {
            let w = ComplexNumber.exp(
                ComplexNumber(2 * .pi / Double(n) * Double(i)) * .i
            )
            result[i] = y1[i] + w * y2[i]
            result[i + n/2] = y1[i] - w * y2[i]
        }
        return result
    }
}

public enum FFT_vDSP {
    public static func forward(_ values: [Double], radix: vDSP.Radix = .radix2) -> [ComplexNumber] {
        precondition(Int(pow(2, round(log2(Double(values.count))))) == values.count)
        
        let log2n = Int(round(log2(Double(values.count))))
        
        let fft = vDSP.FFT(log2n: vDSP_Length(log2n), radix: radix, ofType: DSPDoubleSplitComplex.self)!
        
        var realPart = [Double](repeating: .zero, count: values.count/2)
        var imaginaryPart = [Double](repeating: .zero, count: values.count/2)
        
        values.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            realPart.withUnsafeMutableBufferPointer({ realPtr in
                imaginaryPart.withUnsafeMutableBufferPointer { imaginaryPtr in
                    var splitComplex = DSPDoubleSplitComplex(realp: realPtr.baseAddress!, imagp: imaginaryPtr.baseAddress!)
                    vDSP_ctozD(ptr.bindMemory(to: DSPDoubleComplex.self).baseAddress!,
                               2,
                               &splitComplex,
                               1,
                               vDSP_Length(values.count/2))
                    // WARNING: In-place call.
                    fft.transform(input: splitComplex, output: &splitComplex, direction: .forward)
                }
            })
        }
        
        /*
         If Direction is +1, a real-to-complex transform is performed, taking
         input from a real vector that has been coerced into the complex
         structure:
         
         scale = 2;
         
         // Define a real vector, h:
         for (j = 0; j < N/2; ++j)
         {
            h[2*j + 0] = C->realp[j*IC];
            h[2*j + 1] = C->imagp[j*IC];
         }
         
         // Perform Discrete Fourier Transform.
         for (k = 0; k < N; ++k)
            H[k] = scale *
                    sum(h[j] * e**(-Direction*2*pi*i*j*k/N), 0 <= j < N);
         
         // Pack DC and Nyquist components into C->realp[0] and C->imagp[0].
         C->realp[0*IC] = Re(H[ 0 ]).
         C->imagp[0*IC] = Re(H[N/2]).
         
         // Store regular components:
         for (k = 1; k < N/2; ++k)
         {
             C->realp[k*IC] = Re(H[k]);
             C->imagp[k*IC] = Im(H[k]);
         }
         
         Note that, for N/2 < k < N, H[k] is not stored.  However, since
         the input is a real vector, the output has symmetry that allows the
         unstored elements to be derived from the stored elements:  H[k] =
         conj(H(N-k)).  This symmetry also implies the DC and Nyquist
         components are real, so their imaginary parts are zero.
         */
        
        var fftResult = [ComplexNumber](repeating: .zero, count: values.count)
        fftResult[0] = ComplexNumber(realPart[0])
        fftResult[values.count/2] = ComplexNumber(imaginaryPart[0])
        for i in 1..<values.count/2 {
            fftResult[i] = ComplexNumber(realPart[i], imaginaryPart[i])
        }
        for i in (values.count/2 + 1)..<values.count {
            fftResult[i] = fftResult[values.count - i].conjugate
        }
        fftResult = fftResult.map({ $0 / ComplexNumber(2.0) })
        return fftResult
    }
}
