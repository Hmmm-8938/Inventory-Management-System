import SwiftUI
import SwiftData

struct CheckedOutItemsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Query private var items: [ApplicationData] // Query SwiftData storage

    var body: some View {
        VStack {
            Text("Checked Out Items")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            NavigationLink(destination: ScannerView()) {
                Text("Scan ID")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)

            List {
                if items.isEmpty {
                    Text("No items scanned yet.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(items) { item in
                        Text(item.name)
                            .padding(.vertical, 8)
                    }
                }
            }
            .onAppear {
                print("Fetched items: \(items.map { $0.name })") // Debugging
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true) // Hide default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "house")
                            .foregroundColor(.blue)
                        Text("Home")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CheckedOutItemsView()
    }
}
