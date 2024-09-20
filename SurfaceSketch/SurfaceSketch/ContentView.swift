//
//  ContentView.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/20/24.
//

import SwiftUI
import PhotosUI
import SceneKit
import ARKit

class ARView: UIViewController, ARSCNViewDelegate {
    var arView: ARSCNView {
        self.view as! ARSCNView
    }

    override func loadView() {
      self.view = ARSCNView(frame: .zero)
    }

    override func viewDidLoad() {
       super.viewDidLoad()
       arView.delegate = self
       arView.scene = SCNScene()
    }

    // MARK: - Functions for standard AR view handling
    override func viewDidAppear(_ animated: Bool) {
       super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
       super.viewDidLayoutSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)

       let configuration = ARWorldTrackingConfiguration()
       arView.session.run(configuration)
       arView.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
       super.viewWillDisappear(animated)

       arView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {}
    func session(_ session: ARSession, didFailWithError error: Error)
    {}
    func session(_ session: ARSession, cameraDidChangeTrackingState
    camera: ARCamera) {}
}

// MARK: - ARViewIndicator
struct ARViewIndicator: UIViewControllerRepresentable {
   typealias UIViewControllerType = ARView

   func makeUIViewController(context: Context) -> ARView {
    ARView()
   }

   func updateUIViewController(_ uiViewController:
   ARViewIndicator.UIViewControllerType, context:
   UIViewControllerRepresentableContext<ARViewIndicator>) { }
}

// MARK: - NavigationIndicator
struct NavigationIndicator: UIViewControllerRepresentable {
   typealias UIViewControllerType = ARView

   func makeUIViewController(context: Context) -> ARView {
    ARView()
   }

   func updateUIViewController(_ uiViewController:
   NavigationIndicator.UIViewControllerType, context:
   UIViewControllerRepresentableContext<NavigationIndicator>) { }
}

struct ContentView: View {
    @State private var showPhotoPicker = false
    @State private var showIntro = true
    @State private var sketchItem: PhotosPickerItem?
    @State private var sketchImage: Image?

//    var changingNode = SKSpriteNode()
//    var selectedNode = SKSpriteNode()

    var body: some View {
        ZStack {
            NavigationIndicator()
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
        .fixedSize(horizontal: false, vertical: true)
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
