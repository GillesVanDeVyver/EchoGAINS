import SwiftUI
import UniformTypeIdentifiers // Required for UTType

struct VideoPickerView: View {
    @Binding var selectedVideoURL: URL?
    @Binding var videoFileName: String
    @State private var isPickerPresented: Bool = false

    var body: some View {
        VStack {
            Button("Select Video") {
                isPickerPresented = true
            }
            .padding()
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [UTType.mpeg4Movie], // Specifically allow MP4 movies
                allowsMultipleSelection: false
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    if let firstFile = selectedFiles.first {
                        // Gain access to the URL
                        let isSecured = firstFile.startAccessingSecurityScopedResource()
                        defer {
                            if isSecured {
                                firstFile.stopAccessingSecurityScopedResource()
                            }
                        }
                        selectedVideoURL = firstFile
                        videoFileName = firstFile.lastPathComponent
                    }
                } catch {
                    // Handle error
                    print("Error picking video: \(error.localizedDescription)")
                    videoFileName = "Failed to load video"
                }
            }
            
            Text(videoFileName)
                .padding(.bottom)
        }
    }
}

// Preview
struct VideoPickerView_Previews: PreviewProvider {
    @State static var previewSelectedURL: URL? = nil
    @State static var previewVideoFileName: String = "No video selected (Preview)"
    
    static var previews: some View {
        VideoPickerView(selectedVideoURL: $previewSelectedURL, videoFileName: $previewVideoFileName)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
