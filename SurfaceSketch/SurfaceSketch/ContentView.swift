//
//  ContentView.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/20/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var showPhotoPicker = false
    @State private var showIntro = true
    @State private var sketchItem: PhotosPickerItem?
    @State private var sketchImage: Image?

    var body: some View {
        VStack {
            if showIntro {
                intro
            } else {
                arInstructions
            }
        }
        .padding(16)
        .sheet(isPresented: $showPhotoPicker) {
            photoPicker
        }
    }

    private var intro: some View {
        VStack(spacing: 40) {
            introInstructions
            asset
            nextButton
        }
    }

    private var arInstructions: some View {
        VStack {
            Spacer()
            HStack(spacing: 30) {
                sketchImage?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                Text("Choose a surface to sketch your image")
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
            .frame(width: 300)
    }

    private var introInstructions: some View {
        Group {
            if sketchImage == nil {
                Text("Tap the camera below to select an image")
            } else {
                Text("Tap the image below to select a new image")
            }
        }
        .font(.largeTitle)
        .multilineTextAlignment(.center)
    }

    private var nextButton: some View {
        Button("Next") {
            showIntro = false
        }
        .disabled(sketchImage == nil)
    }

    private var photoPicker: some View {
        PhotosPicker("Select an image", selection: $sketchItem, matching: .images)
        .onChange(of: sketchItem) {
            Task {
                defer {
                    showPhotoPicker = false
                }

                if let loaded = try? await sketchItem?.loadTransferable(type: Data.self) {
                    sketchImage = Image(data: loaded)
                } else {
                    print("Failed")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension Image {
    init?(data: Data) {
    #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
    #endif
    }
}
