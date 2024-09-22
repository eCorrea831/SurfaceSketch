//
//  ARView.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/21/24.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class ARView: UIViewController, ARSCNViewDelegate {
    private var selectedNode: SCNNode?
    private var selectedImage: UIImage?
    var didSelectSurface: (() -> Void)?
    var configuration = ARWorldTrackingConfiguration()
    var isSurfaceSelected = false

    private var arView: ARSCNView {
        view as! ARSCNView
    }

    override func loadView() {
        view = ARSCNView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        arView.delegate = self
        arView.scene = SCNScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        arView.session.run(configuration)
        arView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectPlane))
        arView.addGestureRecognizer(tapGesture)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        arView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    internal func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor  else { return }

        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)

        let newNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        newNode.eulerAngles.x = -.pi / 2
        node.addChildNode(newNode)
    }

    func setSelectionClosure(_ didSelectSurface: @escaping () -> Void) {
        self.didSelectSurface = didSelectSurface
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
        isSurfaceSelected ? rotateImage() : selectASurface(gesture)
    }

    private func rotateImage() {
        selectedNode?.eulerAngles.y += .pi / 2
    }

    private func selectASurface(_ gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: arView)
        let hitTestResults = arView.hitTest(touchPosition, options: nil)

        guard let hitResult = hitTestResults.first else { return }

        selectedNode = hitResult.node
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = selectedImage

        configuration.planeDetection = []
        arView.session.run(configuration)
        isSurfaceSelected = true
        didSelectSurface?()
    }

    func clearSurfaces() {
        arView.scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }
        isSurfaceSelected = false
    }
}
