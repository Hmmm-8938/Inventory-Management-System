import SwiftUI
import FirebaseFirestore

struct CheckedOutItemsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var isSyncing = false
    @State private var items: [InventoryItem] = []

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
                    Text("No items checked out.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(items, id: \..id) { item in
                        Text(item.name)
                            .padding(.vertical, 8)
                    }
                }
            }
            .onAppear {
                syncInventoryData()
            }

            if isSyncing {
                ProgressView("Syncing...")
                    .padding()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
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
    
    // Function to fetch inventory data directly from Firestore
    private func syncInventoryData() {
        isSyncing = true
        FirestoreService.shared.getFirestoreDB().collection("inventory").getDocuments { snapshot, error in
            isSyncing = false
            if let error = error {
                print("Error fetching data from Firestore: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No inventory items found.")
                return
            }
            
            // Map Firestore documents to InventoryItem models
            items = documents.compactMap { doc -> InventoryItem? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let itemID = data["itemID"] as? String else { return nil }
                
                return InventoryItem(
                    id: doc.documentID,
                    name: name
                )
            }
        }
    }
}
