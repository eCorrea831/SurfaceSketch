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
import UIKit

class ARView: UIViewController, ARSCNViewDelegate {
    private var changingNode: SCNNode?
    private var selectedNode: SCNNode?
    private var selectedImage: UIImage?

    var configuration = ARWorldTrackingConfiguration()

    private var arView: ARSCNView {
        self.view as! ARSCNView
    }

    override func loadView() {
        self.view = ARSCNView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        arView.delegate = self
        arView.scene = SCNScene()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectPlane))
        arView.addGestureRecognizer(tapGesture)
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

    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor  else { return }

        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)

        changingNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        changingNode?.eulerAngles.x = -.pi / 2
        node.addChildNode(changingNode!)
    }

    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
    }

    func adjustNodeOpacity(opacity: Double) {
        selectedNode?.opacity = opacity
    }

    func startPlaneDetection() {
        configuration.planeDetection = [.vertical, .horizontal]
        arView.session.run(configuration)
    }

    @objc func selectPlane(_ gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: arView)
        let hitTestResults = arView.hitTest(touchPosition, options: nil)

        guard let hitResult = hitTestResults.first else { return }

        selectedNode = hitResult.node
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = selectedImage
        arView.scene.rootNode.addChildNode(selectedNode!) //this is wrong node

        configuration.planeDetection = []
        arView.session.run(configuration)

        for node in arView.scene.rootNode.childNodes where node != selectedNode {
            node.removeFromParentNode()
        }
    }
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

    private let arView = ARView()

    func makeUIViewController(context: Context) -> ARView {
        arView
    }

    func setArViewSelectedImage(_ image: UIImage?) {
        arView.setSelectedImage(image)
    }

    func adjustNodeOpacity(opacity: Double) {
        arView.adjustNodeOpacity(opacity: opacity)
    }

    func startPlaneDetection() {
        arView.startPlaneDetection()
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
    @State private var sketchUIImage: UIImage?
    @State private var opacity: Double = 1.0

    let navIndicator = NavigationIndicator()

    var body: some View {
        ZStack {
            navIndicator
            foreground
            .padding(16)
            .sheet(isPresented: $showPhotoPicker) {
                photoPicker
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
            slider
            Spacer()
            HStack(spacing: 30) {
                sketchImage?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                StrokeText(text: "Choose a surface to sketch your image", width: 0.2, color: .white)
            }
        }
    }

    private var slider: some View {
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
        ZStack {
            Color(.white)
                .cornerRadius(30)
                .frame(width: 250, height: 200)
            Image(systemName: "camera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        }
    }

    private var introInstructions: some View {
        Group {
            if sketchImage == nil {
                StrokeText(text: "Tap the camera below to select an image", width: 0.5, color: .white)
            } else {
                StrokeText(text: "Tap the image below to select a new image", width: 0.5, color: .white)
            }
        }
        .font(.largeTitle)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var nextButton: some View {
        if let sketchImage {
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

    private func dismissIntro() {
        showIntro = false
        navIndicator.startPlaneDetection()
    }
}

#Preview {
    ContentView()
}

struct TransferableImage: Transferable {
    let image: Image
    let uiImage: UIImage

    enum TransferError: Error {
        case importFailed
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return TransferableImage(image: image, uiImage: uiImage)
        }
    }
}

struct StrokeText: View {
    let text: String
    let width: CGFloat
    let color: Color

    var body: some View {
        ZStack{
            ZStack{
                Text(text).offset(x:  width, y:  width)
                Text(text).offset(x: -width, y: -width)
                Text(text).offset(x: -width, y:  width)
                Text(text).offset(x:  width, y: -width)
            }
            .foregroundColor(color)
            Text(text)
        }
    }
}
