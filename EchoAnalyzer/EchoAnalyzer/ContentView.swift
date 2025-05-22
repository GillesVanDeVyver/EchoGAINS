import SwiftUI
import UIKit // For UIImage

struct ContentView: View {
    // MARK: - State Variables
    @State private var selectedVideoURL: URL?
    @State private var videoFileName: String = "No video selected"
    @State private var ejectionFractionString: String = "--%" // For display in EjectionFractionView
    
    @State private var extractedFrames: [UIImage] = []
    @State private var segmentationMasks: [UIImage?] = [] // Stores all generated masks

    // UI State
    @State private var isProcessingVideo: Bool = false // Frame extraction
    @State private var isSegmenting: Bool = false      // Segmentation
    @State private var isCalculatingAFC: Bool = false  // AFC calculation
    
    // Error Handling
    @State private var processingError: String? = nil
    @State private var segmentationError: String? = nil
    @State private var afcError: String? = nil

    // AFC Results (for potential display or debugging, not strictly required by UI yet)
    @State private var lvedAreaPixels: Int? = nil
    @State private var lvesAreaPixels: Int? = nil
    @State private var afcResultValue: Double? = nil

    // MARK: - Services
    private let videoProcessor = VideoProcessor()
    private let segmentationService = SegmentationService()
    private let efCalculator = EFCalculator()

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                VideoPickerView(selectedVideoURL: $selectedVideoURL, videoFileName: $videoFileName)
                    .onChange(of: selectedVideoURL) { newURL in
                        clearAllData() // Reset everything when a new video is picked
                        guard let url = newURL else { return }
                        processVideoAndSegmentAllFrames(url: url)
                    }
                
                VideoDisplayView(
                    selectedVideoURL: $selectedVideoURL,
                    firstFrame: extractedFrames.first, 
                    segmentationMask: segmentationMasks.first(where: { $0 != nil }) ?? nil // Show first available mask
                )
                
                statusAndErrorMessages()

                EjectionFractionView(ejectionFraction: $ejectionFractionString, calculateEFAction: {
                    initiateAFCCalculation()
                })
                .disabled(segmentationMasks.compactMap { $0 }.count < 2 || isCalculatingAFC || isSegmenting || isProcessingVideo) // Need at least 2 masks for ED/ES

                Spacer()
            }
            .navigationTitle("EchoAnalyzer")
            .padding()
        }
    }

    // MARK: - UI Helper for Status/Errors
    @ViewBuilder
    private func statusAndErrorMessages() -> some View {
        Group { // Use Group to allow multiple conditional blocks
            if isProcessingVideo {
                ProgressView("Extracting frames...")
            } else if isSegmenting { // Show segmenting only if not extracting
                ProgressView("Segmenting all frames...")
            } else if isCalculatingAFC { // Show calculating only if not segmenting/extracting
                ProgressView("Calculating AFC...")
            }
        }.padding(.vertical, 5)
        
        if let error = processingError {
            Text("Frame Extraction Error: \(error)").foregroundColor(.red).padding(.horizontal).font(.caption)
        }
        if let error = segmentationError {
            Text("Segmentation Error: \(error)").foregroundColor(.red).padding(.horizontal).font(.caption)
        }
        if let error = afcError {
            Text("AFC Error: \(error)").foregroundColor(.red).padding(.horizontal).font(.caption)
        }
        
        // Display count of extracted frames and successfully segmented frames
        if !extractedFrames.isEmpty && !isProcessingVideo && !isSegmenting && !isCalculatingAFC {
            let validMasksCount = segmentationMasks.compactMap { $0 }.count
            Text("Extracted \(extractedFrames.count) frames. Successfully segmented \(validMasksCount) frames.")
                .font(.footnote)
                .padding(.vertical, 2)
            
            if validMasksCount < extractedFrames.count && extractedFrames.count > 0 && validMasksCount > 0 {
                 Text("Note: Not all frames were successfully segmented. AFC might be less accurate.")
                    .font(.caption).foregroundColor(.orange).padding(.horizontal)
            } else if validMasksCount == 0 && extractedFrames.count > 0 {
                Text("Warning: No frames were successfully segmented. Cannot calculate AFC.")
                    .font(.caption).foregroundColor(.red).padding(.horizontal)
            }
        }
    }
    
    // MARK: - Data Handling & Processing Flow
    private func clearAllData() {
        // Video and processing data
        extractedFrames = []
        segmentationMasks = []
        selectedVideoURL = nil // Also clear the URL to allow re-selection of same video if needed
        videoFileName = "No video selected"
        
        // Errors
        processingError = nil
        segmentationError = nil
        afcError = nil
        
        // AFC results
        lvedAreaPixels = nil
        lvesAreaPixels = nil
        afcResultValue = nil
        ejectionFractionString = "--%" // Reset display string
        
        // UI State flags
        isProcessingVideo = false
        isSegmenting = false
        isCalculatingAFC = false
    }

    private func processVideoAndSegmentAllFrames(url: URL) {
        isProcessingVideo = true
        // Reset errors specifically for this new processing attempt
        processingError = nil
        segmentationError = nil
        afcError = nil
        ejectionFractionString = "--%"

        videoProcessor.extractFrames(from: url, framesPerSecond: 5.0) { result in // Increased FPS for more masks
            DispatchQueue.main.async {
                isProcessingVideo = false
                switch result {
                case .success(let frames):
                    self.extractedFrames = frames
                    if frames.isEmpty {
                        self.processingError = "No frames could be extracted from the video."
                        self.segmentationMasks = [] // Ensure masks are also empty
                    } else {
                        print("Successfully extracted \(frames.count) frames.")
                        performSegmentationOnAllFrames(frames: frames)
                    }
                case .failure(let error):
                    self.processingError = error.localizedDescription
                    print("Failed to extract frames: \(error.localizedDescription)")
                    self.extractedFrames = []
                    self.segmentationMasks = []
                }
            }
        }
    }

    private func performSegmentationOnAllFrames(frames: [UIImage]) {
        guard !frames.isEmpty else {
            self.segmentationError = "No frames provided for segmentation."
            self.segmentationMasks = []
            return
        }
        isSegmenting = true
        self.segmentationMasks = Array(repeating: nil, count: frames.count) // Initialize with nil
        let dispatchGroup = DispatchGroup()

        for (index, frame) in frames.enumerated() {
            dispatchGroup.enter()
            Task {
                let (maskImage, _, error) = await segmentationService.segment(frame: frame)
                DispatchQueue.main.async {
                    if let err = error {
                         print("Segmentation failed for frame \(index): \(err.localizedDescription)")
                         // self.segmentationMasks[index] remains nil
                         if self.segmentationError == nil { // Store first error
                             self.segmentationError = "Segmentation failed for one or more frames."
                         }
                    } else if let mi = maskImage {
                        self.segmentationMasks[index] = mi
                    } else {
                        // No image and no error, unusual.
                        print("Segmentation returned no image and no error for frame \(index).")
                        if self.segmentationError == nil {
                             self.segmentationError = "Segmentation returned no image for one or more frames."
                         }
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.isSegmenting = false
            let successfulMasks = self.segmentationMasks.compactMap { $0 }.count
            print("Segmentation completed for all frames. Successfully segmented \(successfulMasks) out of \(frames.count).")
            if successfulMasks == 0 && !frames.isEmpty {
                self.segmentationError = (self.segmentationError ?? "") + " No frames were successfully segmented."
            } else if successfulMasks < frames.count && !frames.isEmpty {
                 self.segmentationError = (self.segmentationError ?? "") + " Some frames could not be segmented."
            }
            // Automatically trigger AFC calculation if enough masks are present and no other process is running
            if successfulMasks >= 2 && !isCalculatingAFC {
                initiateAFCCalculation()
            } else if successfulMasks < 2 && !frames.isEmpty {
                self.afcError = "Not enough masks (\(successfulMasks)) for AFC. Need at least 2."
                self.ejectionFractionString = "Error: Low Masks"
            }
        }
    }
    
    private func initiateAFCCalculation() {
        let validMasks = segmentationMasks.compactMap { $0 }
        guard validMasks.count >= 2 else {
            self.afcError = "Not enough valid masks (\(validMasks.count)) for AFC calculation. Need at least 2."
            self.ejectionFractionString = "Error: Low Masks"
            return
        }
        
        isCalculatingAFC = true
        afcError = nil // Clear previous AFC error
        
        let edEsResult = efCalculator.identifyEDandESFrames(masks: self.segmentationMasks) // Pass all, including nils
        
        guard case .success(let (edMask, esMask)) = edEsResult, let ed = edMask, let es = esMask else {
            if case .failure(let error) = edEsResult {
                self.afcError = "ED/ES ID failed: \(error.localizedDescription)"
            } else {
                self.afcError = "Could not identify ED and ES frames from available masks."
            }
            self.ejectionFractionString = "Error: ED/ES ID"
            isCalculatingAFC = false
            return
        }
        
        let edAreaResult = efCalculator.calculateLVArea(from: ed)
        let esAreaResult = efCalculator.calculateLVArea(from: es)

        guard case .success(let edArea) = edAreaResult, case .success(let esArea) = esAreaResult else {
            self.afcError = "Failed to calculate LV area for ED or ES frame. ED: \(edAreaResult), ES: \(esAreaResult)"
            self.ejectionFractionString = "Error: Area Calc"
            isCalculatingAFC = false
            return
        }
        self.lvedAreaPixels = edArea
        self.lvesAreaPixels = esArea
        
        let afcCalcResult = efCalculator.calculateAFC(lvedaPixels: edArea, lvesaPixels: esArea)
        
        switch afcCalcResult {
        case .success(let afc):
            self.afcResultValue = afc
            self.ejectionFractionString = String(format: "AFC: %.1f%%", afc)
            print("AFC Calculated: \(self.ejectionFractionString)")
        case .failure(let error):
            self.afcError = "AFC calculation error: \(error.localizedDescription)"
            self.ejectionFractionString = "Error: AFC Calc"
            print(self.afcError!)
        }
        isCalculatingAFC = false
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
