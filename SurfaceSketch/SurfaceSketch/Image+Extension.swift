//
//  Image+Extension.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/20/24.
//

import SwiftUI
import UIKit

extension Image {
    init?(data: Data) {
    #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
    #endif
    }

    func asUIImage() -> UIImage? {
            let controller = UIHostingController(rootView: self)
            let view = controller.view

            let targetSize = CGSize(width: 300, height: 300) // Set your desired size
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
            }
        }
}
