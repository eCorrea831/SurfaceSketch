//
//  ARNavigationIndicator.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/21/24.
//

import Foundation
import UIKit
import ARKit
import SwiftUI

// MARK: - NavigationIndicator
struct ARNavigationIndicator: UIViewControllerRepresentable {
    private let arView = ARView()

    func makeUIViewController(context: Context) -> ARView {
        arView
    }

    func setSelectionClosure(_ didSelectSurface: @escaping () -> Void) {
        arView.setSelectionClosure(didSelectSurface)
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

    func clearSurfaces() {
        arView.clearSurfaces()
    }

    func updateUIViewController(_ uiViewController: ARView, context: Context) { }
}
