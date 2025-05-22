import UIKit
import CoreGraphics // For CGImage and pixel data access

struct EFCalculator {

    enum EFCalculationError: Error {
        case invalidMaskImage
        case noMasksProvided
        case areaCalculationFailed
        case edEsIdentificationFailed
        case divisionByZero
    }
    
    private let lvMaskTargetRed: UInt8 = 255
    private let lvMaskTargetGreen: UInt8 = 0
    private let lvMaskTargetBlue: UInt8 = 0
    private let lvMaskMinAlpha: UInt8 = 10 // Pixels must be at least this alpha to be counted

    // MARK: - LV Area Calculation
    /// Calculates the area of the Left Ventricle (LV) from a given mask image.
    /// Assumes LV pixels are primarily red and non-transparent.
    func calculateLVArea(from lvMask: UIImage) -> Result<Int, EFCalculationError> {
        guard let cgImage = lvMask.cgImage else {
            return .failure(.invalidMaskImage)
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0 && height > 0 else {
            return .success(0) // No area if image is empty
        }

        // Get pixel data
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let pixelData = CFDataGetBytePtr(data) else {
            return .failure(.invalidMaskImage)
        }

        let bytesPerRow = cgImage.bytesPerRow
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        guard bytesPerPixel == 4 else { // Expecting RGBA
            print("Warning: calculateLVArea expected RGBA8 format (4 bytes per pixel), got \(bytesPerPixel) BPP. Area may be inaccurate.")
            // We can try to proceed if it's RGB (3 BPP) but alpha check will be problematic.
            // For now, strict check.
            return .failure(.invalidMaskImage)
        }

        var lvPixelCount = 0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let red   = pixelData[offset]
                let green = pixelData[offset + 1]
                let blue  = pixelData[offset + 2]
                let alpha = pixelData[offset + 3]

                // Check if the pixel matches the LV mask criteria (e.g., red and sufficiently opaque)
                if red == lvMaskTargetRed && green == lvMaskTargetGreen && blue == lvMaskTargetBlue && alpha >= lvMaskMinAlpha {
                    lvPixelCount += 1
                }
            }
        }
        return .success(lvPixelCount)
    }

    // MARK: - ED and ES Frame Identification
    /// Identifies End-Diastolic (largest area) and End-Systolic (smallest area) frames from a sequence of LV masks.
    func identifyEDandESFrames(masks: [UIImage?]) -> Result<(edFrameMask: UIImage?, esFrameMask: UIImage?), EFCalculationError> {
        let validMasksWithAreas: [(mask: UIImage, area: Int)] = masks.compactMap { optionalMask in
            guard let mask = optionalMask else { return nil }
            let areaResult = calculateLVArea(from: mask)
            switch areaResult {
            case .success(let area):
                return (mask, area)
            case .failure(let error):
                print("Failed to calculate area for one mask: \(error)")
                return nil
            }
        }

        guard !validMasksWithAreas.isEmpty else {
            return .failure(.noMasksProvided) // Or perhaps .success((nil,nil)) if no valid masks is acceptable
        }

        var edCandidate: (mask: UIImage, area: Int)? = nil
        var esCandidate: (mask: UIImage, area: Int)? = nil

        for item in validMasksWithAreas {
            // Identify End-Diastole (max area)
            if edCandidate == nil || item.area > edCandidate!.area {
                edCandidate = item
            }
            // Identify End-Systole (min area)
            if esCandidate == nil || item.area < esCandidate!.area {
                esCandidate = item
            }
        }
        
        guard let ed = edCandidate, let es = esCandidate else {
            // This should not happen if validMasksWithAreas is not empty
            return .failure(.edEsIdentificationFailed)
        }

        return .success((edFrameMask: ed.mask, esFrameMask: es.mask))
    }

    // MARK: - AFC Calculation
    /// Calculates Area Fraction Change (AFC).
    func calculateAFC(lvedaPixels: Int, lvesaPixels: Int) -> Result<Double, EFCalculationError> {
        guard lvedaPixels > 0 else {
            return .failure(.divisionByZero) // Cannot divide by zero LVEDA
        }
        guard lvedaPixels >= lvesaPixels else {
            // This is possible if ED/ES identification is imperfect or areas are very similar
            print("Warning: LVEDA (\(lvedaPixels)px) is less than LVESA (\(lvesaPixels)px). AFC will be negative or zero.")
            // Proceed with calculation, but it might indicate an issue upstream.
        }

        let afc = (Double(lvedaPixels - lvesaPixels) / Double(lvedaPixels)) * 100.0
        return .success(afc)
    }
}
