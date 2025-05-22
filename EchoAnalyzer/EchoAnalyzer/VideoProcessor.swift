import AVFoundation
import UIKit // For UIImage

class VideoProcessor {
    enum FrameExtractionError: Error {
        case assetCreationFailed
        case imageGeneratorCreationFailed
        case frameCopyFailed(Error)
        case trackLoadFailed
        case durationLoadFailed
    }

    func extractFrames(from videoURL: URL, framesPerSecond: Double = 1.0, completion: @escaping (Result<[UIImage], FrameExtractionError>) -> Void) {
        Task { // Use a Task for concurrency
            do {
                let asset = AVURLAsset(url: videoURL)
                
                // Load duration and tracks asynchronously
                guard let duration = try? await asset.load(.duration) else {
                    completion(.failure(.durationLoadFailed))
                    return
                }
                guard let tracks = try? await asset.load(.tracks) else {
                    completion(.failure(.trackLoadFailed))
                    return
                }

                let videoDuration = CMTimeGetSeconds(duration)
                guard videoDuration > 0 else {
                    completion(.success([])) // No frames if duration is zero or invalid
                    return
                }

                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true // Corrects orientation
                imageGenerator.requestedTimeToleranceBefore = .zero
                imageGenerator.requestedTimeToleranceAfter = .zero

                var frames: [UIImage] = []
                let totalFramesToExtract = Int(videoDuration * framesPerSecond)
                
                // If no frames to extract (e.g. very short video and low fps), ensure at least one frame if possible
                let actualFramesToExtract = max(1, totalFramesToExtract)

                for i in 0..<actualFramesToExtract {
                    let timeValue = Double(i) / framesPerSecond
                    let cmTime = CMTimeMakeWithSeconds(timeValue, preferredTimescale: 600) // High timescale for precision

                    do {
                        let cgImage = try imageGenerator.copyCGImage(at: cmTime, actualTime: nil)
                        frames.append(UIImage(cgImage: cgImage))
                    } catch {
                        print("Failed to copy CGImage at time \(timeValue): \(error)")
                        // Decide if one failed frame should stop the whole process or just be skipped.
                        // For now, let's continue and collect what we can.
                        // If a more critical error occurs, consider completion(.failure(.frameCopyFailed(error)))
                    }
                }
                completion(.success(frames))

            } catch {
                // This catch block is for errors not caught by specific guards above, like AVURLAsset initialization issues.
                // However, AVURLAsset initialization itself doesn't throw in Swift.
                // Errors from `load` are handled by `try?` and guards.
                // So, this is more of a fallback.
                print("An unexpected error occurred during frame extraction setup: \(error)")
                completion(.failure(.assetCreationFailed)) // Or a more generic error
            }
        }
    }
}
