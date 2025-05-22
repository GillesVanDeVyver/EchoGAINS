import SwiftUI

struct EjectionFractionView: View {
    @Binding var ejectionFraction: String // This will now display AFC or status/error
    var calculateEFAction: () -> Void

    var body: some View {
        VStack {
            Text("Area Fraction Change (AFC)") // Updated Label
                .font(.headline)
            
            Text(ejectionFraction)
                .font(.title) // Slightly smaller if it can be long error messages
                .padding(.vertical, 5)
                .multilineTextAlignment(.center)
                .lineLimit(2) // Allow for two lines for error messages
                .minimumScaleFactor(0.75) // Allow text to shrink
                .accessibilityLabel("Area Fraction Change value")
                .accessibilityValue(ejectionFraction.isEmpty || ejectionFraction == "--%" ? "Not yet calculated" : ejectionFraction)

            Button("Calculate AFC") { // Updated Button Text
                calculateEFAction()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Tap to start the Area Fraction Change calculation process using available segmented frames.")
        }
        .padding()
    }
}

// Preview
struct EjectionFractionView_Previews: PreviewProvider {
    @State static var previewAFC_calculated: String = "AFC: 55.3%"
    @State static var previewAFC_initial: String = "--%"
    @State static var previewAFC_error: String = "Error: Low Masks"
    
    static var previews: some View {
        Group {
            EjectionFractionView(ejectionFraction: .constant(previewAFC_initial), calculateEFAction: {
                print("Preview Calculate AFC button tapped (Initial)")
            })
            .previewDisplayName("Initial State")

            EjectionFractionView(ejectionFraction: .constant(previewAFC_calculated), calculateEFAction: {
                print("Preview Calculate AFC button tapped (Calculated)")
            })
            .previewDisplayName("AFC Calculated")
            
            EjectionFractionView(ejectionFraction: .constant(previewAFC_error), calculateEFAction: {
                print("Preview Calculate AFC button tapped (Error)")
            })
            .previewDisplayName("AFC Error")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
