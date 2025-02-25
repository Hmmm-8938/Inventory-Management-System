import SwiftUI
import CodeScanner
import Foundation
import SwiftData

struct ScannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var context
    @Query private var items: [ApplicationData]
    
    @State private var isLoading: Bool = false   // Controls loading indicator
    @State private var showConfirmation: Bool = false  // Shows confirmation for 3 sec
    @State private var lastScannedItemName: String? = nil // Holds the name of the last scanned item

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem (placement: .navigationBarLeading) {
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
                                Text("Scan Code")
                            }
                        }
                    }
                
                // Code Scanner
                CodeScannerView(codeTypes: [.code128, .qr, .ean8, .code39, .code93, .ean13], simulatedData: "https://catalogit.app/collections/d8ad2d30-d37f-11ef-942e-a9ab53bb22fc/entries/4d18cef0-d384-11ef-970e-0dcfb0428747") { response in
                    switch response {
                    case .success(let result):
                        print("Found code: \(result.string)")
                        addItem(result: result.string)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
            
            // Show loading indicator while fetching
            if isLoading {
                ProgressView("Fetching data...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .font(.title)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.7), alignment: .center)
                    .cornerRadius(10)
            }
            
            // Show confirmation message when title is found (disappears after 3 sec)
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
        }
    }
    
    func addItem(result: String) {
        isLoading = true  // Start loading
        
        fetchTitlesFromAPI(result: result) { titles in
            DispatchQueue.main.async {
                isLoading = false  // Stop loading
                
                guard let titles = titles else {
                    print("Failed to fetch titles, items not saved.")
                    return
                }
                
                for title in titles {
                    let item = ApplicationData(name: title)
                    context.insert(item)
                }
                
                // Show confirmation message with the last scanned item name
                if let firstTitle = titles.first {
                    lastScannedItemName = firstTitle
                }
                showConfirmation = true
                
                // Hide confirmation message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfirmation = false
                }
            }
        }
    }

    func fetchTitlesFromAPI(result: String, completion: @escaping ([String]?) -> Void) {
        let apiURL = "http://127.0.0.1:5000/scrape/\(result)"  // Pass scanned result dynamically
        guard let url = URL(string: apiURL) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONDecoder().decode([String: [String]].self, from: data)
                if let titles = json["titles"] {
                    print("Fetched Titles: \(titles)") // Will print only after fetching
                    completion(titles)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error decoding JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
