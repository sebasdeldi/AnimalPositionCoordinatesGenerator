import Vision
import UIKit

class AnimalPoseDetector: NSObject, ObservableObject {
    
    @Published var animalBodyParts = [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]()

    func detectAnimalPose(in image: UIImage) {
        // Convert the UIImage to a CVPixelBuffer
        guard let pixelBuffer = image.pixelBuffer() else {
            return
        }
        
        // Create a new request to recognize an animal body pose.
        let animalBodyPoseRequest = VNDetectAnimalBodyPoseRequest(completionHandler: detectedAnimalPose)
        
        // Create a new request handler.
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            // Send the request to the request handler with a call to perform.
            try imageRequestHandler.perform([animalBodyPoseRequest])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }

    func detectedAnimalPose(request: VNRequest, error: Error?) {
        // Get the results from VNAnimalBodyPoseObservations.
        guard let animalBodyPoseResults = request.results as? [VNAnimalBodyPoseObservation] else { return }
        // Get the animal body recognized points for the .all group.
        guard let animalBodyAllParts = try? animalBodyPoseResults.first?.recognizedPoints(.all) else { return }
        self.animalBodyParts = animalBodyAllParts
    }
}

extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        let width = Int(size.width)
        let height = Int(size.height)
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer
        )
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

import Foundation
import Vision
import SwiftUI

class ImageAnalyzer: ObservableObject {
    @Published var image: UIImage?
    @Published var jointResults: [String: CGPoint] = [:]

    // Function to analyze the image and update jointResults
    func analyzeImage(fromURL urlString: String) {
        guard let imageUrl = URL(string: urlString) else {
            print("Invalid image URL")
            return
        }

        let session = URLSession.shared
        let dataTask = session.dataTask(with: imageUrl) { [weak self] (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                // Update the 'image' property
                self?.image = image

                // Perform Vision analysis on the loaded image
                self?.detectJointsInImage(image)
            }
        }

        dataTask.resume()
    }

    private func detectJointsInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to create CGImage from UIImage")
            return
        }

        let request = VNDetectAnimalBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)

        do {
            try handler.perform([request])
            guard let observations = request.results else {
                print("No body pose observations found")
                return
            }

            // Process the pose observations to extract joint information
            var results: [String: CGPoint] = [:]
            for observation in observations {
                let recognizedPoints = try observation.recognizedPoints(.all)
                for (name, point) in recognizedPoints {
                    results[name.rawValue.rawValue] = point.location
                }
            }

            // Update 'jointResults' property with the results
            DispatchQueue.main.async { [weak self] in
                self?.jointResults = results
            }
        } catch {
            print("Error performing body pose detection: \(error)")
        }
    }
}
