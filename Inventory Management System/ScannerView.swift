//
//  ScannerView.swift
//  Inventory Management System
//
import SwiftUI
import CodeScanner

struct ScannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var isLoading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showFailure: Bool = false
    @State private var lastScannedItemName: String? = nil
    @State private var refreshID: UUID = UUID()  // Refresh trigger
    @State private var scannedItems: [String] = [] // Store scanned items locally
    @State private var headerOffsetY: CGFloat = -100 // For header animation

    var body: some View {
        ZStack(alignment: .top) {
            // Camera view at the bottom layer
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
            .id(refreshID)
            .ignoresSafeArea()
            
            // Header overlay
            VStack(spacing: 0) {
                AnimatedHeaderView(
                    title: "Scan Code",
                    subtitle: "Please scan a QR or barcode to add an item",
                    systemImage: "qrcode.viewfinder",
                    offsetY: $headerOffsetY,
                    onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
                )
                
                // Add a scanning indicator line
                Rectangle()
                    .fill(Color.green.opacity(0.5))
                    .frame(height: 2)
                    .shadow(color: Color.green.opacity(0.5), radius: 4)
                
                Spacer()
            }
            .ignoresSafeArea(.all, edges: .top)
            
            // Status overlays
            Group {
                // Loading indicator
                if isLoading {
                    ProgressView("Fetching data...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                // Success confirmation
                if showConfirmation, let itemName = lastScannedItemName {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("Item Added")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(itemName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(width: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    )
                    .transition(.scale)
                }
                
                // Failure message
                if showFailure {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text("Scan Failed")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Please try scanning again")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .frame(width: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                    )
                    .transition(.scale)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                headerOffsetY = 0
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
                
                self.scannedItems.append(contentsOf: titles)
                self.lastScannedItemName = titles.first
                self.showConfirmation = true
                
                // Add item to Firestore
                FirestoreService.shared.addInventoryItem(itemID: result, name: titles.first ?? "Unknown") { success in
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
        let apiURL = "https://sound-scarcely-mite.ngrok-free.app/scrape/\(result)"
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
