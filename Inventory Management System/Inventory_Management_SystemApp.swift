import SwiftUI
import FirebaseCore
import UserNotifications
import SwiftData
import FirebaseFirestore

@main
struct Inventory_Management_SystemApp: App {
    
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
