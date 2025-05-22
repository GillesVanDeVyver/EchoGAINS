import SwiftUI
import AVKit // For AVPlayer

struct VideoDisplayView: View {
    @Binding var selectedVideoURL: URL?

    var body: some View {
        VStack {
            Text("Video Display Area")
                .font(.headline)
                .padding(.bottom, 5)

            if let url = selectedVideoURL {
                // Attempt to display the video if a URL is available
                // Note: For a real app, more robust error handling and video controls would be needed.
                // AVPlayerViewController is more suitable for full video playback controls.
                // Here, we use a simple VideoPlayer for display purposes.
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 300) // Adjust height as needed
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .accessibilityLabel("Video player displaying the selected echocardiogram")
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300) // Adjust height as needed
                    .cornerRadius(10)
                    .overlay(
                        Text("Video will be displayed here")
                            .foregroundColor(.gray)
                    )
                    .accessibilityLabel("Placeholder for video display area")
            }
            
            // Placeholder for segmentation mask overlay
            Text("Segmentation masks will appear here (Optional)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
        .padding()
    }
}

// Preview
struct VideoDisplayView_Previews: PreviewProvider {
    @State static var previewSelectedURL: URL? = nil // No video by default in preview
    // To preview with a dummy video, you'd need a sample video in your project and load its URL here.
    // For example: @State static var previewSelectedURL: URL? = Bundle.main.url(forResource: "sample", withExtension: "mp4")

    static var previews: some View {
        VideoDisplayView(selectedVideoURL: $previewSelectedURL)
            .previewLayout(.sizeThatFits)
    }
}
