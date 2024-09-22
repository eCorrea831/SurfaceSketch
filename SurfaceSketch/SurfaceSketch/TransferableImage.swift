//
//  TransferableImage.swift
//  SurfaceSketch
//
//  Created by Erica Correa on 9/21/24.
//

import SwiftUI

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
