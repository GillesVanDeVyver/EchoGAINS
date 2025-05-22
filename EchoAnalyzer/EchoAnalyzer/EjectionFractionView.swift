import SwiftUI

struct EjectionFractionView: View {
    @Binding var ejectionFraction: String
    var calculateEFAction: () -> Void // Action to be performed when button is tapped

    var body: some View {
        VStack {
            Text("Ejection Fraction (EF)")
                .font(.headline)
            
            Text(ejectionFraction)
                .font(.largeTitle)
                .padding(.vertical, 5)
                .accessibilityLabel("Ejection fraction value")
                .accessibilityValue(ejectionFraction.isEmpty || ejectionFraction == "--%" ? "Not yet calculated" : ejectionFraction)

            Button("Calculate EF") {
                calculateEFAction()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Tap to start the ejection fraction calculation process")
        }
        .padding()
    }
}

// Preview
struct EjectionFractionView_Previews: PreviewProvider {
    @State static var previewEF: String = "60%" // Example EF for preview
    
    static var previews: some View {
        EjectionFractionView(ejectionFraction: $previewEF, calculateEFAction: {
            print("Preview Calculate EF button tapped")
            // In a real scenario, this would trigger a dummy calculation or update for preview
            // For now, just print a message or update the previewEF if needed.
            previewEF = (previewEF == "60%") ? "62%" : "60%" // Toggle for visual feedback
        })
        .previewLayout(.sizeThatFits)
    }
}
