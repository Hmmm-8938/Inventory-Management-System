import SwiftUI
import SwiftData
import FirebaseFirestore

struct CheckedOutItemsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext  // Add modelContext from SwiftData
    @Query private var items: [ApplicationData] // Query SwiftData storage
    @State private var isSyncing = false
    @State private var syncStatusMessage = ""

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
                syncInventoryData() // Sync with Firestore when the view appears
            }

            if isSyncing {
                ProgressView("Syncing...")
                    .padding()
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
    
    // Function to trigger sync operation with Firestore
    private func syncInventoryData() {
        isSyncing = true
        
        // Fetch items from Firestore
        FirestoreService.shared.getFirestoreDB().collection("inventory").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching data from Firestore: \(error.localizedDescription)")
                isSyncing = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No inventory items found.")
                isSyncing = false
                return
            }
            
            // Map Firestore documents to InventoryItem models
            let fetchedItems: [InventoryItem] = documents.compactMap { doc -> InventoryItem? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let category = data["category"] as? String,
                      let lastCheckedOutBy = data["lastCheckedOutBy"] as? String,
                      let timestamp = data["timestamp"] as? Timestamp else {
                    return nil
                }
                
                return InventoryItem(
                    id: doc.documentID,
                    name: name,
                    category: category,
                    lastCheckedOutBy: lastCheckedOutBy,
                    timestamp: timestamp.dateValue()
                )
            }
            
            // Sync the local data with Firestore
            FirestoreService.shared.syncLocalDataWithFirestore(localContext: modelContext, fetchedItems: fetchedItems) { success in
                isSyncing = false
                if success {
                    print("Sync successful!")
                } else {
                    print("Sync failed")
                }
            }
        }
    }

}
