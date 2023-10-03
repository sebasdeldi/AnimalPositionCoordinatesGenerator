import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var imageAnalyzer = ImageAnalyzer()
    @State private var currentImageIndex = 1
    let maxImageIndex = 11936
    var baseURL = "https://raw.githubusercontent.com/sebasdeldi/dog_image_dataset/main/"
    
    var body: some View {
        VStack {
            if let image = imageAnalyzer.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Text("Loading Image...")
                    .font(.title)
                    .foregroundColor(.gray)
            }

            if !imageAnalyzer.jointResults.isEmpty {
                JointResultsView(jointResults: imageAnalyzer.jointResults)
            }
            
            Text("Image URL: \(currentImageURLString)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
        }
        .onAppear {
            // Load the initial image and start the timer
            loadImageAndStartTimer()
        }
    }
    
    var currentImageURLString: String {
        return "\(baseURL)\(currentImageIndex).jpg?raw=true"
    }
    
    func loadImageAndStartTimer() {
        let imageURLString = currentImageURLString
        imageAnalyzer.analyzeImage(fromURL: imageURLString)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            currentImageIndex += 1
            if currentImageIndex > maxImageIndex {
                // Stop the timer when we've reached the last image
                timer.invalidate()
            } else {
                let imageURLString = currentImageURLString
                imageAnalyzer.analyzeImage(fromURL: imageURLString)
            }
        }
    }
}


struct JointResultsView: View {
    let jointResults: [String: CGPoint]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Joint Results:")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            ForEach(jointResults.sorted(by: { $0.key < $1.key }), id: \.key) { name, point in
                Text("\(name): \(point.x), \(point.y)")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}
