//
//  ViewController.swift
//  MobileNetTest
//
//  Created by Shay Dubrovsky on 19/11/2023.
//

import UIKit
import CoreML
import Vision
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    private let imagePicker = UIImagePickerController()
    var photoPicker: PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        
        let photoPicker = PHPickerViewController(configuration: config)
        photoPicker.delegate = self
        
        return photoPicker
    }
    
    let predictionsToShow = 2
    let imagePredictor = ImagePredictor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
//        updatePredictionLabel("Making predictions for the photo...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }
    
    func showAlert(_ message: String) {
        var dialogMessage = UIAlertController(title: "Verified!", message: message, preferredStyle: .alert)
        self.present(dialogMessage, animated: true)
    }
    
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            print("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        print("Shay: \(predictionString)")
//        updatePredictionLabel(predictionString)
    }
    
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }

            return "\(name) - \(prediction.confidencePercentage)%"
        }

        return topPredictions
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(photoPicker, animated: true)
    }
    
}

extension ViewController: PHPickerViewControllerDelegate, UINavigationControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            return
        }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            if let error = error {
                print("Photo picker error: \(error)")
                return
            }
            
            guard let photo = object as? UIImage else {
                fatalError("The Photo Picker's image isn't a/n \(UIImage.self) instance.")
            }
            self.userSelectedPhoto(photo)
        }
    }
}

