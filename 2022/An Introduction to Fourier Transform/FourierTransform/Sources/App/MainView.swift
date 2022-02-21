//
//  File.swift
//  
//
//  Created by YuAo on 2022/1/20.
//

import Foundation
import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Euler's Identity", destination: EulersIdentityView())
                NavigationLink("2D Drawing", destination: Fourier2DDrawingView())
                NavigationLink("1D Drawing", destination: Fourier1DDrawingView())
                NavigationLink("Image DCT", destination: ImageDCTExperimentView())
            }
            .listStyle(SidebarListStyle())
            Text("Pick a topic on the left to start.")
                .toolbar(content: { Spacer() })
                .navigationTitle("Fourier Transform")
        }
    }
}
