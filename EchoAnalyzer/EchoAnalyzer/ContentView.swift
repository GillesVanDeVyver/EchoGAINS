import SwiftUI

struct ContentView: View {
    @State private var selectedVideoURL: URL?
    @State private var videoFileName: String = "No video selected"
    @State private var ejectionFraction: String = "--%"

    var body: some View {
        NavigationView {
            VStack {
                VideoPickerView(selectedVideoURL: $selectedVideoURL, videoFileName: $videoFileName)
                
                VideoDisplayView(selectedVideoURL: $selectedVideoURL)
                
                EjectionFractionView(ejectionFraction: $ejectionFraction, calculateEFAction: {
                    // Placeholder for EF calculation logic
                    print("Calculate EF button tapped")
                    self.ejectionFraction = "55%" // Example value
                })
                
                Spacer()
            }
            .navigationTitle("EchoAnalyzer")
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
