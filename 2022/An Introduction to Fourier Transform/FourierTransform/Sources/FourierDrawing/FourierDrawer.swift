//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/24.
//

import Foundation
import Numerics
import CoreGraphics

public class FourierDrawer {
    
    public enum Error: Swift.Error {
        case cannotCreateContext
        case cannotCreateImage
    }
    
    public struct Options {
        public init(
            penOrigin: CGPoint,
            rollsPaper: Bool,
            drawsSamples: Bool,
            penColor: CGColor = CGColor(srgbRed: 0, green: 192/255.0, blue: 128/255.0, alpha: 1.0),
            vectorColor: CGColor = CGColor(srgbRed: 0, green: 0.5, blue: 1.0, alpha: 0.7),
            circleColor: CGColor = CGColor(srgbRed: 0, green: 0.5, blue: 1.0, alpha: 0.2),
            sampleColor: CGColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.1)
        )
        {
            self.penOrigin = penOrigin
            self.penColor = penColor
            self.vectorColor = vectorColor
            self.circleColor = circleColor
            self.sampleColor = sampleColor
            self.rollsPaper = rollsPaper
            self.drawsSamples = drawsSamples
        }
        
        public var penOrigin: CGPoint
        public var penColor: CGColor
        public var vectorColor: CGColor
        public var circleColor: CGColor
        public var sampleColor: CGColor
        
        public var rollsPaper: Bool
        public var drawsSamples: Bool
    }
    
    private var trace: CGImage?
    private var lastPoint: CGPoint?
    
    private let drawing: FourierDrawing
    private let context: CGContext
    
    public let options: Options
    
    public init(drawing: FourierDrawing, options: Options) throws {
        self.drawing = drawing
        self.options = options
        guard let context = CGContext(data: nil,
                                      width: Int(drawing.bounds.width),
                                      height: Int(drawing.bounds.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            throw Error.cannotCreateContext
        }
        self.context = context
    }
    
    public func draw(at time: Double, frequencyLimit: Int) -> CGImage? {
        context.setLineJoin(.round)
        context.setLineCap(.round)
        
        let radiusPath = CGMutablePath()
        let vectorPath = CGMutablePath()
        var keyPoint: ComplexNumber = ComplexNumber(options.penOrigin.x - drawing.bounds.origin.x, options.penOrigin.y - drawing.bounds.origin.y)
        vectorPath.move(to: CGPoint(x: keyPoint.real, y: keyPoint.imaginary))
        
        drawing.enumerateVectorsForDrawing(at: time, invoking: { component in
            guard abs(component.frequency) <= frequencyLimit else { return }
            
            let v = component.value
            radiusPath.addEllipse(in: CGRect(x: keyPoint.real - v.length, y: keyPoint.imaginary - v.length, width: v.length * 2, height: v.length * 2))
            keyPoint = keyPoint + v
            vectorPath.addLine(to: CGPoint(x: keyPoint.real, y: keyPoint.imaginary))
        })
        
        context.setFillColor(.white)
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
        if let trace = trace {
            context.draw(trace, in: CGRect(x: 0, y: options.rollsPaper ? 1 : 0, width: context.width, height: context.height))
        }
        if let lastPoint = lastPoint {
            context.setStrokeColor(options.penColor)
            context.setLineWidth(2)
            context.strokeLineSegments(between: [lastPoint, CGPoint(x: keyPoint.real, y: keyPoint.imaginary)])
        } else {
            context.setFillColor(options.penColor)
            context.fillEllipse(in: CGRect(x: keyPoint.real - 1, y: keyPoint.imaginary - 1, width: 2, height: 2))
        }
        self.trace = context.makeImage()
        
        if options.rollsPaper {
            lastPoint = CGPoint(x: keyPoint.real, y: keyPoint.imaginary + 1)
        } else {
            lastPoint = CGPoint(x: keyPoint.real, y: keyPoint.imaginary)
        }
        
        context.setLineWidth(1.0)
        context.setStrokeColor(options.circleColor)
        context.addPath(radiusPath)
        context.strokePath()
        
        context.setLineWidth(2.0)
        context.setStrokeColor(options.vectorColor)
        context.addPath(vectorPath)
        context.strokePath()
        
        if options.drawsSamples {
            for sample in drawing.samples {
                context.setFillColor(options.sampleColor)
                context.fillEllipse(in: CGRect(x: sample.real - 1 - drawing.bounds.origin.x, y: sample.imaginary - 1 - drawing.bounds.origin.y, width: 2, height: 2))
            }
        }
        
        context.setLineWidth(1.0)
        context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.1))
        context.strokeLineSegments(between: [
            CGPoint(x: 0, y: options.penOrigin.y - drawing.bounds.origin.y),
            CGPoint(x: CGFloat(context.width), y: options.penOrigin.y - drawing.bounds.origin.y)
        ])
        context.strokeLineSegments(between: [
            CGPoint(x: options.penOrigin.x - drawing.bounds.origin.x, y: 0),
            CGPoint(x: options.penOrigin.x - drawing.bounds.origin.x, y: CGFloat(context.height))
        ])
        
        return context.makeImage()
    }
    
    public func reset() {
        self.trace = nil
        self.lastPoint = nil
    }
}
    
