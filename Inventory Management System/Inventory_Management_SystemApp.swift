import SwiftUI
import FirebaseCore
import UserNotifications
import SwiftData
import Firebase
import FirebaseAppCheck
import FirebaseFirestore
import Foundation
 
@main
struct Inventory_Management_SystemApp: App
{
    
    // Register AppDelegate for Firebase and notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
 
    // Register SwiftData model container safely
    var sharedModelContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(for: ApplicationData.self, isStoredInMemoryOnly: false)
            return try ModelContainer(for: ApplicationData.self, configurations: config) // Pass single config, not array
        } catch {
            fatalError("Failed to initialize model container: \(error.localizedDescription)")
        }
    }()
 
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer) // Attach SwiftData model container
        }
    }
}



//struct InventoryItem
//{
//    var id: String
//    var name: String
//    var category: String
//    var lastCheckedOutBy: String
//    var timestamp: Date
//}

@Model
class InventoryItem {
    @Attribute var id: String // Define the id attribute
    @Attribute var name: String
    @Attribute var category: String
    @Attribute var lastCheckedOutBy: String
    @Attribute var timestamp: Date
    
    // Required initializer
    init(id: String, name: String, category: String, lastCheckedOutBy: String, timestamp: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.lastCheckedOutBy = lastCheckedOutBy
        self.timestamp = timestamp
    }
}

 
// AppDelegate to handle Firebase and push notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Set up push notifications
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Handle incoming notifications while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
 
// FirestoreService for Firebase interaction

class FirestoreService {
    static let shared = FirestoreService()  // Singleton to easily access FirestoreService
    
    private let db = Firestore.firestore()
    
    func getFirestoreDB() -> Firestore {
        return db
    }
    
    // Method to add an inventory item to Firestore
    func addInventoryItem(itemID: String, name: String, category: String, user: String, completion: @escaping (Bool) -> Void) {
        
        // Make sure the itemID doesn't contain any invalid characters (e.g., double slashes, spaces, etc.)
        // If itemID is a full URL, extract the ID correctly
        let documentID = extractDocumentID(from: itemID)
        
        // Add to Firestore collection with the valid document ID
        db.collection("inventory").document(documentID).setData([
            "name": name,
            "category": category,
            "lastCheckedOutBy": user,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Error adding item: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Item successfully added!")
                completion(true)
            }
        }
    }

    func syncLocalDataWithFirestore(localContext: ModelContext, fetchedItems: [InventoryItem], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // Fetch existing items from local context
                let fetchDescriptor = FetchDescriptor<InventoryItem>()
                let existingItems = try localContext.fetch(fetchDescriptor)
                print("Existing items in local context: \(existingItems.map { $0.name })") // Debugging
                
                // Remove items that are in local but not in Firestore
                for localItem in existingItems {
                    if !fetchedItems.contains(where: { $0.id == localItem.id }) {
                        localContext.delete(localItem)
                        print("Deleted item: \(localItem.name)") // Debugging
                    }
                }

                // Add or update items from Firestore
                for fetchedItem in fetchedItems {
                    if let existingItem = existingItems.first(where: { $0.id == fetchedItem.id }) {
                        // Update existing item
                        existingItem.name = fetchedItem.name
                        existingItem.category = fetchedItem.category
                        existingItem.lastCheckedOutBy = fetchedItem.lastCheckedOutBy
                        existingItem.timestamp = fetchedItem.timestamp
                        print("Updated item: \(existingItem.name)") // Debugging
                    } else {
                        // Insert new item
                        localContext.insert(fetchedItem)
                        print("Inserted new item: \(fetchedItem.name)") // Debugging
                    }
                }
                
                // Save the changes to the local context
                try localContext.save()
                print("Local context saved.") // Debugging
                completion(true)
            } catch {
                print("Error syncing local data with Firestore: \(error.localizedDescription)")
                completion(false)
            }
        }
    }


    // Helper function to extract document ID from a URL or scanned code
    private func extractDocumentID(from scannedCode: String) -> String {
        // Assuming the scanned code is a URL like 'https://catalogit.app/entry/4d18cef0-d384-11ef-970e-0dcfb0428747'
        // Extracting the ID part after the last slash
        if let lastSlashIndex = scannedCode.lastIndex(of: "/") {
            let id = scannedCode[lastSlashIndex...]
            return String(id.dropFirst()) // Remove the leading '/'
        }
        return scannedCode // If not a URL, return the code as is
    }
}
