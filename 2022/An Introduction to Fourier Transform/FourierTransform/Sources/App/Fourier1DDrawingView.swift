//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/24.
//

import Foundation
import SwiftUI
import FourierDrawing

class Fourier1DDrawingController: ObservableObject {
    
    @Published private(set) var image: CGImage?
    
    private var timer: Timer?
    private let drawer: FourierDrawer
    
    init() {
        let n = 512
        let samples = (0..<n).map({ (i: Int) -> Double in
            let t = Double(i)/(Double(n)/(.pi * 2.0))
            
            // https://www.desmos.com/calculator/ixjp350txq
            return (
                sin(t) + abs(sin(2 * t)) + sin(5 * t) + cos(6 * t) + sin(12 * t)
            ) * 60
        })
        let drawing = Fourier1DDrawing(samples: samples)
        drawer = try! FourierDrawer(drawing: drawing, options: FourierDrawer.Options(penOrigin: CGPoint(x: 0, y: 128), rollsPaper: true, drawsSamples: false))
        var time: Double = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { [unowned self] timer in
            time += (1.0/Double(n))
            self.image = self.drawer.draw(at: time, frequencyLimit: n)
        })
    }
    
    deinit {
        timer?.invalidate()
    }
}

class Fourier1DDrawingOrientationController: ObservableObject {
    enum Orientation {
        case normal
        case horizontal
        
        mutating func toggle() {
            switch self {
            case .normal:
                self = .horizontal
            case .horizontal:
                self = .normal
            }
        }
    }
    
    // This has to be in the controller object to work around SwiftUI's toolbar retain cycle bug.
    @Published var preferredDisplayOrientation: Orientation = .normal
}


extension View {
    func apply(_ orientation: Fourier1DDrawingOrientationController.Orientation) -> some View {
        Group {
            switch orientation {
            case .normal:
                self
            case .horizontal:
                self.rotationEffect(.radians(-.pi/2))
            }
        }
    }
}

struct Fourier1DDrawingView: View {
    @StateObject var controller: Fourier1DDrawingController = Fourier1DDrawingController()
    @StateObject var orientationController: Fourier1DDrawingOrientationController = Fourier1DDrawingOrientationController()
    
    var body: some View {
        Group {
            if let image = controller.image {
                Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .apply(orientationController.preferredDisplayOrientation)
            } else {
                Text("Loading...").frame(width: 512, height: 256)
            }
        }
        .toolbar(content: {
            Button("Rotate", action: { [orientationController] in
                orientationController.preferredDisplayOrientation.toggle()
            })
        })
        .navigationTitle("1D Drawing")
    }
}
