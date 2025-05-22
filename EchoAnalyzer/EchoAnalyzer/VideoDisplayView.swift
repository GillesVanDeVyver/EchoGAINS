import SwiftUI
import AVKit // For AVPlayer
import UIKit // For UIImage

struct VideoDisplayView: View {
    @Binding var selectedVideoURL: URL?
    var firstFrame: UIImage?
    var segmentationMask: UIImage? // New property for the mask

    var body: some View {
        VStack {
            Text("Video Display Area")
                .font(.headline)
                .padding(.bottom, 5)

            ZStack { // Use ZStack to overlay mask on frame
                if let frame = firstFrame {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .accessibilityLabel("First frame of the selected echocardiogram")
                } else if let url = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 300)
                        .cornerRadius(10)
                        .accessibilityLabel("Video player displaying the selected echocardiogram")
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .cornerRadius(10)
                        .overlay(
                            Text("Video will be displayed here")
                                .foregroundColor(.gray)
                        )
                        .accessibilityLabel("Placeholder for video display area")
                }

                // Overlay the segmentation mask if available
                if let mask = segmentationMask {
                    Image(uiImage: mask)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .opacity(0.7) // Adjust opacity for visibility
                        .accessibilityLabel("Segmentation mask overlay")
                }
            }
            .overlay( // Keep the border around the ZStack
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            
            if segmentationMask == nil { // Show this only if no mask is yet available/processed
                Text("Segmentation mask will appear here if processed.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
        .padding()
    }
}

// Preview
struct VideoDisplayView_Previews: PreviewProvider {
    @State static var previewSelectedURL: URL? = nil
    static var previewImage: UIImage? = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 240))
        return renderer.image { context in
            UIColor.systemGray4.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 240))
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24), .foregroundColor: UIColor.white]
            ("Preview Frame" as NSString).draw(at: CGPoint(x: 80, y: 100), withAttributes: attrs)
        }
    }()
    
    static var previewMaskImage: UIImage? = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 240))
        return renderer.image { context in
            UIColor.red.withAlphaComponent(0.5).setFill() // Semi-transparent red
            // Draw a sample shape, e.g., a circle for LV
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 80, y: 60, width: 160, height: 120))
            circlePath.fill()
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.white]
            ("Sample Mask" as NSString).draw(at: CGPoint(x: 100, y: 105), withAttributes: attrs)
        }
    }()

    static var previews: some View {
        Group {
            VideoDisplayView(selectedVideoURL: .constant(nil), firstFrame: nil, segmentationMask: nil)
                .previewDisplayName("No Video, No Mask")
            
            VideoDisplayView(selectedVideoURL: .constant(nil), firstFrame: previewImage, segmentationMask: nil)
                .previewDisplayName("Frame, No Mask")

            VideoDisplayView(selectedVideoURL: .constant(nil), firstFrame: previewImage, segmentationMask: previewMaskImage)
                .previewDisplayName("Frame with Mask")
            
            // Example with a placeholder URL (if you had a sample video in bundle)
            // VideoDisplayView(selectedVideoURL: .constant(URL(string: "file:///sample.mp4")!), firstFrame: nil, segmentationMask: nil)
            //    .previewDisplayName("Video URL, No Mask")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
