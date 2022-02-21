//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/24.
//

import Foundation
import Numerics

public typealias ComplexNumber = Complex<Double>

public struct FrequencyComponent {
    public var frequency: Int
    public var value: ComplexNumber
}

public protocol FourierDrawing {
    var samples: [ComplexNumber] { get }
    var bounds: CGRect { get }
    var frequencyComponents: [ComplexNumber] { get }
    var maximumFrequency: Int { get }
    
    func enumerateVectorsForDrawing(at time: Double, invoking body: (FrequencyComponent) throws -> Void) rethrows
}
