//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/20.
//

import Foundation
import SwiftUI
import FourierDrawing
import CoreText

class Fourier2DDrawingController: ObservableObject {
    
    @Published private(set) var image: CGImage?
    
    @Published var frequencyLimit: Float {
        didSet {
            self.drawer.reset()
        }
    }
    
    @Published private(set) var drawing: FourierDrawing
    
    private var timer: Timer?
    private var drawer: FourierDrawer
    
    struct Shape: CaseIterable, Hashable, Identifiable {
        var name: String
        var path: CGPath
        
        var id: String { name }
        
        static let allCases: [Shape] = {
            if let font =  NSFont(name: "SF Pro", size: 16) {
                return [.swift, .sketch, .airplane, .heart, .person, .github]
            } else {
                return [.github]
            }
        }()
        
        static let github = Shape(name: "Github", path: .github)
        static let sketch = Shape(name: "Sketch", path: .makePathForSymbol("􀤑"))
        static let person = Shape(name: "Person", path: .makePathForSymbol("􀉪"))
        static let swift = Shape(name: "Swift", path: .makePathForSymbol("􀫊"))
        static let airplane = Shape(name: "Airplane", path: .makePathForSymbol("􀑓"))
        static let heart = Shape(name: "Heart", path: .makePathForSymbol("􀊵"))
    }
    
    @Published var shape: Shape {
        didSet {
            self.rebuildDrawing()
        }
    }
    
    init() {
        let shape = Shape.allCases.first!
        let path: CGPath = shape.path
        self.shape = shape
        let drawing = Fourier2DDrawing(path: path, maximumFrequency: 50)
        frequencyLimit = Float(drawing.maximumFrequency)
        drawer = try! FourierDrawer(drawing: drawing, options: FourierDrawer.Options(penOrigin: .zero, rollsPaper: false, drawsSamples: true))
        self.drawing = drawing
        
        var time: Double = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { [unowned self] timer in
            time += 0.001
            self.image = self.drawer.draw(at: time, frequencyLimit: Int(self.frequencyLimit))
        })
    }
    
    private func rebuildDrawing() {
        drawing = Fourier2DDrawing(path: shape.path, maximumFrequency: 50)
        drawer = try! FourierDrawer(drawing: drawing, options: FourierDrawer.Options(penOrigin: .zero, rollsPaper: false, drawsSamples: true))
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct Fourier2DDrawingView: View {
    @StateObject var controller: Fourier2DDrawingController = Fourier2DDrawingController()
    
    var body: some View {
        Group {
            if let image = controller.image {
                VStack {
                    Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    HStack {
                        Picker("", selection: $controller.shape, content: {
                            ForEach(Fourier2DDrawingController.Shape.allCases, content: { shape in
                                Text(shape.name).tag(shape)
                            })
                        }).controlSize(.large)
                            .scaledToFit()
                            .fixedSize()
                        Spacer(minLength: 16)
                        Text("Frequency Limit: \(Int(controller.frequencyLimit), specifier: "%02d")")
                            .font(Font.body.monospacedDigit())
                        Slider(value: $controller.frequencyLimit, in: 1...Float(controller.drawing.maximumFrequency), step: 1)
                            .controlSize(.large)
                            .frame(minWidth: 240)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color( NSColor.controlBackgroundColor)))
                }.padding()
            } else {
                Text("Loading...")
                    .frame(width: 512, height: 256)
            }
        }
        .toolbar(content: { Spacer() })
        .navigationTitle("2D Drawing")
    }
}

extension CGPath {
    static let github = CGPath.makePath(svgPath: "M 0 131.335938 C 0 159.722656 7.957031 185.246094 23.875 207.902344 C 39.792969 230.5625 60.417969 246.421875 85.75 255.488281 C 86.75 255.65625 87.582031 255.742188 88.25 255.742188 C 88.917969 255.742188 89.457031 255.613281 89.875 255.359375 C 90.292969 255.101562 90.625 254.84375 90.875 254.589844 C 91.125 254.332031 91.292969 253.90625 91.375 253.304688 C 91.457031 252.707031 91.5 252.324219 91.5 252.152344 L 91.5 226.246094 C 85.332031 226.929688 79.832031 226.886719 75 226.117188 C 70.167969 225.347656 66.375 224.148438 63.625 222.523438 C 60.875 220.902344 58.457031 218.890625 56.375 216.496094 C 54.292969 214.101562 52.875 211.921875 52.125 209.957031 C 51.375 207.988281 50.625 205.9375 49.875 203.800781 C 49.125 201.660156 48.667969 200.421875 48.5 200.082031 C 47 197.515625 44.75 195.164062 41.75 193.027344 C 38.75 190.886719 36.5 189.179688 35 187.894531 C 33.5 186.613281 33.332031 185.375 34.5 184.175781 C 42.832031 179.730469 52.25 185.375 62.75 201.105469 C 68.417969 209.828125 78.332031 212.394531 92.5 208.800781 C 94.167969 201.789062 97.5 195.804688 102.5 190.84375 C 83.167969 187.253906 68.832031 179.902344 59.5 168.785156 C 50.167969 157.671875 45.5 144.160156 45.5 128.257812 C 45.5 113.378906 50.082031 100.46875 59.25 89.523438 C 55.582031 78.40625 56.082031 66.695312 60.75 54.378906 C 65.582031 54.039062 71 55.023438 77 57.332031 C 83 59.640625 87.207031 61.605469 89.625 63.230469 C 92.042969 64.855469 94.167969 66.351562 96 67.71875 C 105.5 64.984375 116.207031 63.613281 128.125 63.613281 C 140.042969 63.613281 150.832031 64.984375 160.5 67.71875 C 162.667969 66.179688 165.082031 64.554688 167.75 62.84375 C 170.417969 61.136719 174.5 59.296875 180 57.332031 C 185.5 55.363281 190.582031 54.550781 195.25 54.894531 C 199.75 67.035156 200.25 78.578125 196.75 89.523438 C 206.082031 100.46875 210.75 113.464844 210.75 128.511719 C 210.75 144.246094 206.042969 157.710938 196.625 168.914062 C 187.207031 180.113281 172.917969 187.425781 153.75 190.84375 C 160.917969 198.199219 164.5 207.089844 164.5 217.523438 L 164.5 250.613281 C 164.5 250.785156 164.582031 251.039062 164.75 251.382812 C 164.75 252.410156 164.792969 253.179688 164.875 253.691406 C 164.957031 254.203125 165.332031 254.71875 166 255.230469 C 166.667969 255.742188 167.582031 256 168.75 256 C 194.417969 247.109375 215.375 231.246094 231.625 208.417969 C 247.875 185.585938 256 159.894531 256 131.335938 C 256 113.550781 252.625 96.535156 245.875 80.289062 C 239.125 64.042969 230.042969 50.0625 218.625 38.347656 C 207.207031 26.632812 193.582031 17.316406 177.75 10.390625 C 161.917969 3.464844 145.332031 0 128 0 C 110.667969 0 94.082031 3.464844 78.25 10.390625 C 62.417969 17.316406 48.792969 26.632812 37.375 38.347656 C 25.957031 50.0625 16.875 64.042969 10.125 80.289062 C 3.375 96.535156 0 113.550781 0 131.335938 Z M 0 131.335938", offset: 0)
    
    static func makePathForSymbol(_ symbol: String, size: CGFloat = 256) -> CGPath {
        guard let font = NSFont(name: "SF Pro", size: size) else {
            fatalError("No \"SF Pro\" font found.")
        }
        var chars = symbol.utf16.map({ UniChar($0) })
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        let gotGlyphs = CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count)
        if gotGlyphs {
            let path = CTFontCreatePathForGlyph(font, glyphs[0], nil)
            return path!
        } else {
            fatalError()
        }
    }
    
}

