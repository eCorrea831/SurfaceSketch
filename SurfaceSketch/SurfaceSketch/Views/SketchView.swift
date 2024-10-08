//
//  ContentView.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/20/24.
//

import SwiftUI
import PhotosUI
import UIKit

struct SketchView: View {
    @State private var showPhotoPicker = false
    @State private var showIntro = true
    @State private var sketchItem: PhotosPickerItem?
    @State private var sketchImage: Image?
    @State private var sketchUIImage: UIImage?
    @State private var showOpacitySlider = false
    @State private var opacity: Double = 1.0

    let navIndicator = ARNavigationIndicator()

    var body: some View {
        ZStack {
            navIndicator
            foreground
            .sheet(isPresented: $showPhotoPicker) {
                photoPicker
            }
        }
        .onAppear {
            navIndicator.setSelectionClosure {
                showOpacitySlider = true
            }
        }
    }

    private var foreground: some View {        
        VStack {
            if showIntro {
                intro
            } else {
                arInstructions
            }
        }
        .padding(16)
    }

    private var intro: some View {
        VStack(spacing: 40) {
            introInstructions
            asset
            nextButton
        }
        .frame(height: 400)
    }

    private var arInstructions: some View {
        VStack {
            HStack {
                slider
                restartButton
            }
            Spacer()
            HStack(spacing: 30) {
                sketchImage?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                StrokeText(text: showOpacitySlider ? "Tap the surface to rotate the image or adjust opacity to start tracing!" : "Tap to select a surface", width: 0.2, color: .white)
            }
        }
    }

    @ViewBuilder
    private var slider: some View {
        if showOpacitySlider {
            VStack {
                Slider(
                    value: $opacity,
                    in: 0...1,
                    onEditingChanged: { _ in
                        navIndicator.adjustNodeOpacity(opacity: opacity)
                    })
                StrokeText(text: "Opacity: \(String(format: "%.2f", opacity * 100))%", width: 0.5, color: .white)
            }
        }
    }

    private var asset: some View {
        Group {
            if sketchImage != nil {
                formattedSketchImage
            } else {
                cameraImage
            }
        }
        .onTapGesture {
            showPhotoPicker = true
        }
    }

    private var formattedSketchImage: some View {
        sketchImage?
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 300)
    }

    private var cameraImage: some View {
        Image(systemName: "camera")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200)
    }

    private var introInstructions: some View {
        Group {
            if sketchImage == nil {
                StrokeText(text: "Tap the camera below to select an image", width: 0.5, color: .white)
            } else {
                StrokeText(text: "Tap the image below to select a new image or tap 'Next' to proceed", width: 0.5, color: .white)
            }
        }
        .font(.largeTitle)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var nextButton: some View {
        if sketchImage != nil {
            Button(action: dismissIntro) {
                StrokeText(text: "Next", width: 0.5, color: .black)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker("Select an image", selection: $sketchItem, matching: .images)
            .onChange(of: sketchItem) {
                Task {
                    defer {
                        showPhotoPicker = false
                    }

                    if let loaded = try? await sketchItem?.loadTransferable(type: TransferableImage.self) {
                        sketchImage = loaded.image
                        sketchUIImage = loaded.uiImage
                        navIndicator.setArViewSelectedImage(sketchUIImage)
                    } else {
                        print("Failed")
                    }
                }
            }
    }

    @ViewBuilder
    private var restartButton: some View {
        if showOpacitySlider {
            Button(action: restartExperience) {
                Image(systemName: "arrow.counterclockwise")
                    .fontWeight(.heavy)
                    .frame(width: 100, height: 100)
            }
        }
    }

    private func dismissIntro() {
        showIntro = false
        navIndicator.startPlaneDetection()
    }

    private func restartExperience() {
        showIntro = true
        sketchItem = nil
        sketchImage = nil
        sketchUIImage = nil
        showOpacitySlider = false
        opacity = 1.0
        navIndicator.clearSurfaces()
    }
}

#Preview {
    SketchView()
}
