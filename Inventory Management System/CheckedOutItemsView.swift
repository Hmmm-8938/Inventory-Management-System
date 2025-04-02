import SwiftUI
import FirebaseFirestore

struct CheckedOutItemsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var isSyncing = false
    @State private var items: [InventoryItem] = []
    @State private var headerOffsetY: CGFloat = -100 // For header animation

    var body: some View {
        VStack(spacing: 0) { // Ensure no spacing between header and content
            AnimatedHeaderView(
                title: "Checked Out Items",
                subtitle: "List of currently checked out items from all users",
                systemImage: "list.bullet.rectangle.fill",
                offsetY: $headerOffsetY,
                onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
            )
            
            List {
                if items.isEmpty {
                    Text("No items checked out.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(items, id: \.id) { item in
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                headerOffsetY = 0
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Function to fetch inventory data directly from Firestore
    private func syncInventoryData() {
        isSyncing = true
        FirestoreService.shared.getFirestoreDB().collection("CheckedOutItems").getDocuments { snapshot, error in
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
