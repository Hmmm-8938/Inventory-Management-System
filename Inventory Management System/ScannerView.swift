import SwiftUI
import CodeScanner
import SwiftData

struct ScannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var context
    @Query private var items: [ApplicationData] // This should reflect stored items
    
    @State private var isLoading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showFailure: Bool = false
    @State private var lastScannedItemName: String? = nil
    @State private var refreshID: UUID = UUID()  // Refresh trigger

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Image(systemName: "house")
                                    Text("Home")
                                }
                                Spacer()
                                Text("Scan Code")
                            }
                        }
                    }
                
                // Code Scanner
                CodeScannerView(codeTypes: [.code128, .qr, .ean8, .code39, .code93, .ean13]) { response in
                    switch response {
                    case .success(let result):
                        print("Scanned code: \(result.string)")
                        addItem(result: result.string)
                    case .failure(let error):
                        print("Scanner error: \(error.localizedDescription)")
                        triggerFailure()
                    }
                }
                .id(refreshID) // Force refresh when ID changes
            }
            
            // Loading indicator
            if isLoading {
                ProgressView("Fetching data...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(10)
            }
            
            // Success confirmation
            if showConfirmation, let itemName = lastScannedItemName {
                VStack {
                    Text("Item Added Successfully!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text(itemName)
                        .font(.headline)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .frame(width: 300, height: 150)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 2))
                .transition(.scale)
            }
            
            // Failure message
            if showFailure {
                VStack {
                    Text("Failed to Fetch Item")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Please try again.")
                        .font(.headline)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .frame(width: 300, height: 150)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
                .transition(.scale)
            }
        }
    }
    
    func addItem(result: String) {
        isLoading = true

        fetchTitlesFromAPI(result: result) { titles in
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let titles = titles else {
                    self.triggerFailure()
                    return
                }
                
                // Insert new items into the context
                for title in titles {
                    let item = ApplicationData(name: title)
                    self.context.insert(item)
                }
                
                // Save to the context
                do {
                    try self.context.save() // Explicitly save
                    print("Saved items: \(items.map { $0.name })") // Debugging
                } catch {
                    print("Failed to save context: \(error.localizedDescription)")
                }
                
                self.lastScannedItemName = titles.first
                self.showConfirmation = true
                
                // Add item to Firestore
                FirestoreService.shared.addInventoryItem(itemID: result, name: titles.first ?? "Unknown", category: "General", user: "User") { success in
                    if success {
                        print("Successfully added to Firestore")
                    } else {
                        print("Failed to add to Firestore")
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showConfirmation = false
                    refreshScanner()  // Refresh scanner after success
                }
            }
        }
    }
    
    func fetchTitlesFromAPI(result: String, completion: @escaping ([String]?) -> Void) {
        let apiURL = "https://usable-logically-squirrel.ngrok-free.app/scrape/\(result)"
        guard let url = URL(string: apiURL) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let json = try JSONDecoder().decode([String: [String]].self, from: data)
                completion(json["titles"])
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }

    func triggerFailure() {
        showFailure = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showFailure = false
            refreshScanner() // Refresh scanner after failure
        }
    }
    
    func refreshScanner() {
        refreshID = UUID()  // Reset refresh trigger for scanner
    }
}
