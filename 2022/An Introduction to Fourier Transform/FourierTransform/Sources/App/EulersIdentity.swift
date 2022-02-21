//
//  File.swift
//  
//
//  Created by YuAo on 2022/2/16.
//

import Foundation
import SwiftUI
import Numerics

class EulersIdentityExperimentController: ObservableObject {
    let timeRange = ClosedRange<TimeInterval>(uncheckedBounds: (lower: 0, upper: 4 * .pi))
    
    private static func position(at time: TimeInterval) -> CGPoint {
        let position = Complex<Double>.exp(.i * Complex<Double>(time))
        return CGPoint(x: position.real, y: position.imaginary)
    }
    
    @Published var time: TimeInterval = 0 {
        didSet {
            self.position = EulersIdentityExperimentController.position(at: time)
        }
    }
    
    @Published var position: CGPoint = EulersIdentityExperimentController.position(at: 0)
    
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                if self.timer == nil {
                    if self.time >= self.timeRange.upperBound {
                        self.time = 0
                    }
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true, block: { [unowned self] timer in
                        self.time += timer.timeInterval
                        if self.time >= self.timeRange.upperBound {
                            self.time = self.timeRange.upperBound
                            self.isPlaying = false
                        }
                    })
                }
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    private var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
}

struct EulersIdentityView: View {
    @StateObject private var controller = EulersIdentityExperimentController()
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            GeometryReader { proxy in
                let width = proxy.size.width
                let unit = width / 3
                let origin = CGPoint(x: proxy.size.width/2, y: proxy.size.height/2)
                let circlePosition = CGPoint(x: controller.position.x * unit + origin.x,
                                             y: -controller.position.y * unit + origin.y)
                let labelPosition = CGPoint(x: circlePosition.x, y: circlePosition.y - width/20)
                ZStack {
                    HStack {
                        Divider().position(origin)
                    }
                    VStack {
                        Divider().position(origin)
                    }
                    Circle()
                        .frame(width: width/40, height: width/40)
                        .foregroundColor(.green)
                        .position(circlePosition)
                    Text("(\(controller.position.x, specifier: "%.2f"), \(controller.position.y, specifier: "%.2f"))")
                        .font(.system(.body, design: .serif).italic())
                        .position(labelPosition)
                }
            }.aspectRatio(1, contentMode: .fit)
            
            Spacer()
            
            HStack {
                HStack {
                    Text("position")
                    Text(" = ")
                    Text("e")
                    Text("i · time").baselineOffset(10).font(.system(size: 14, weight: .medium, design: .serif).italic())
                }
            }.font(.system(size: 24, weight: .medium, design: .serif).italic())
            
            HStack {
                Button(action: {
                    controller.isPlaying.toggle()
                }, label: {
                    Image(systemName: controller.isPlaying ? "pause" : "play.fill")
                }).frame(width: 44)
                Text("Time: \(controller.time, specifier: "%.2f")").font(.body.monospacedDigit())
                Slider(value: $controller.time, in: controller.timeRange)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(NSColor.controlBackgroundColor)))
        }
        .padding()
        .toolbar(content: { Spacer() })
        .navigationTitle("Euler's Identity")
    }
}
