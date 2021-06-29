//
//  CaptureImageView.swift
//  awsApp
//
//  Created by Dhruv Rawat on 2021-06-07.
//

import Foundation
import UIKit
import SwiftUI

struct CaptureImageView {

  /// MARK: - Properties
  @Binding var isShown: Bool
  @Binding var image: UIImage?

  func makeCoordinator() -> Coordinator {
    return Coordinator(isShown: $isShown, image: $image)// Sends in binded variables
  }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  @Binding var isCoordinatorShown: Bool
  @Binding var imageInCoordinator: UIImage?
    
    // Parameters are binded to smth else (in this case, the variables in the CaptureImageView struct)
  init(isShown: Binding<Bool>, image: Binding<UIImage?>) {
    _isCoordinatorShown = isShown
    _imageInCoordinator = image
  }
    
    // If we pick an image
  func imagePickerController(_ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return } // Gets image and stores it
     imageInCoordinator = unwrapImage
     isCoordinatorShown = false
  }
    
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { // If we dismiss/cancel picking an image
     isCoordinatorShown = false
  }
}

// This inherits the struct CaptureImageView
extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController() // Opens image picker
        picker.delegate = context.coordinator

        // picker.sourceType = .camera // on real devices, you can capture image from the camera
        // see https://medium.com/better-programming/how-to-pick-an-image-from-camera-or-photo-library-in-swiftui-a596a0a2ece

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CaptureImageView>) {

    }
}
