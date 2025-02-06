import SwiftUI
import Foundation
 
// Define the model to store check-in/out data
struct InventoryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var productName: String
    var url: String
    var volunteerName: String
    var status: String
    var date: String
    var time: String
}
 
class InventoryData: ObservableObject {
    @Published var items: [InventoryItem] = []
 
    let filename = "inventory_log.json"
    init() {
        loadData()
    }
    // Load data from local file
    func loadData() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedItems = try JSONDecoder().decode([InventoryItem].self, from: data)
            self.items = decodedItems
        } catch {
            print("Error loading data: \(error.localizedDescription)")
        }
    }
    // Save data to a local file
    func saveData() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let encodedData = try JSONEncoder().encode(items)
            try encodedData.write(to: fileURL)
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
    // Get documents directory for file storage
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    // Check In: Update item status to "Check-in"
    func checkIn(item: InventoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].status = "Check-in"
            items[index].date = getCurrentDate()
            items[index].time = getCurrentTime()
        }
    }
    // Check Out: Add new item
    func checkOut(productName: String, url: String, volunteerName: String) {
        let newItem = InventoryItem(
            productName: productName,
            url: url,
            volunteerName: volunteerName,
            status: "Check-out",
            date: getCurrentDate(),
            time: getCurrentTime()
        )
        items.append(newItem)
    }
    // Get current date in format YYYY-MM-DD
    func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
    // Get current time in format HH:MM:SS
    func getCurrentTime() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        return timeFormatter.string(from: Date())
    }
}
 
struct Test: View {
    @StateObject var inventoryData = InventoryData()
    @State private var selectedOption = ""
    @State private var volunteerName = ""
    @State private var productName = ""
    @State private var url = ""
    @State private var checkInName = ""
    var body: some View {
        VStack {
            Text("📌 Inventory Management")
                .font(.largeTitle)
                .padding()
            // Main Menu
            VStack {
                Button(action: {
                    selectedOption = "1"
                }) {
                    Text("1) Check Out (New entry)")
                }
                .padding()
 
                Button(action: {
                    selectedOption = "2"
                }) {
                    Text("2) Check In (Return an item)")
                }
                .padding()
 
                Button(action: {
                    selectedOption = "3"
                }) {
                    Text("3) Exit")
                }
                .padding()
            }
            // Handle user selection
            if selectedOption == "1" {
                VStack {
                    TextField("Enter Product Name", text: $productName)
                        .padding()
                    TextField("Enter Product URL", text: $url)
                        .padding()
                    TextField("Enter Volunteer Name", text: $volunteerName)
                        .padding()
 
                    Button("Check Out") {
                        inventoryData.checkOut(productName: productName, url: url, volunteerName: volunteerName)
                        inventoryData.saveData()
                        productName = ""
                        url = ""
                        volunteerName = ""
                    }
                    .padding()
                }
            }
            if selectedOption == "2" {
                VStack {
                    TextField("Enter Volunteer Name to Check In", text: $checkInName)
                        .padding()
                    Button("Show Checked Out Items") {
                        // Filter items by volunteer name and show the list
                        let checkedOutItems = inventoryData.items.filter { $0.volunteerName == checkInName && $0.status == "Check-out" }
                        for item in checkedOutItems {
                            print("\(item.productName) - \(item.url)")
                        }
                    }
                    .padding()
 
                    Button("Check In All") {
                        let checkedOutItems = inventoryData.items.filter { $0.volunteerName == checkInName && $0.status == "Check-out" }
                        for item in checkedOutItems {
                            inventoryData.checkIn(item: item)
                        }
                        inventoryData.saveData()
                    }
                    .padding()
                    Button("Exit") {
                        selectedOption = "3"
                    }
                    .padding()
                }
            }
            if selectedOption == "3" {
                Text("✅ All updates saved.")
            }
        }
        .padding()
    }
}
