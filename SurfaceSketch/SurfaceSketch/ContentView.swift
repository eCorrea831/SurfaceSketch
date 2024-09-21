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
    private var selectedImage: Image?

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

       let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
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

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)

        changingNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        changingNode?.eulerAngles.x = -.pi / 2
        node.addChildNode(changingNode!)
    }

    func setSelectedImage(_ image: Image?) {
        selectedImage = image
    }

    @objc func selectPlane(_ gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: arView)
        let hitTestResults = arView.hitTest(touchPosition, options: nil)

        guard let hitResult = hitTestResults.first else { return }

        selectedNode = hitResult.node
        highlightNode(hitResult.node)

        if let image = selectedImage?.asUIImage() {
            selectedNode?.geometry?.firstMaterial?.diffuse.contents = image
        }
        //unhighlight the others
    }

    func highlightNode(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let zCoord = node.position.z
        let topLeft = SCNVector3Make(min.x, max.y, zCoord)
        let bottomLeft = SCNVector3Make(min.x, min.y, zCoord)
        let topRight = SCNVector3Make(max.x, max.y, zCoord)
        let bottomRight = SCNVector3Make(max.x, min.y, zCoord)

        let bottomSide = createLineNode(fromPos: bottomLeft, toPos: bottomRight, color: .red)
        let leftSide = createLineNode(fromPos: bottomLeft, toPos: topLeft, color: .red)
        let rightSide = createLineNode(fromPos: bottomRight, toPos: topRight, color: .red)
        let topSide = createLineNode(fromPos: topLeft, toPos: topRight, color: .red)

        [bottomSide, leftSide, rightSide, topSide].forEach {
            $0.name = "test"
            node.addChildNode($0)
        }
    }

    func createLineNode(fromPos origin: SCNVector3, toPos destination: SCNVector3, color: UIColor) -> SCNNode {
        let line = lineFrom(vector: origin, toVector: destination)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]

        return lineNode
    }

    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }

    func unhighlightNode(_ node: SCNNode) {
        let highlightningNodes = node.childNodes { (child, stop) -> Bool in
            child.name == "test"
        }
        highlightningNodes.forEach {
            $0.removeFromParentNode()
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

    func setArViewSelectedImage(_ image: Image?) {
        arView.setSelectedImage(image)
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

    let navIndicator = NavigationIndicator()

    var body: some View {
        ZStack {
            navIndicator
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
                    navIndicator.setArViewSelectedImage(sketchImage)
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
