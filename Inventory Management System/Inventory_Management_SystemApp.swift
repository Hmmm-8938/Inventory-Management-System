import SwiftUI
import FirebaseCore
import UserNotifications
import Firebase
import FirebaseAppCheck
import FirebaseFirestore
import Foundation
import CryptoKit

@main
struct Inventory_Management_SystemApp: App {
    // Register AppDelegate for Firebase and notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// InventoryItem Model (No Local Storage)
struct InventoryItem: Identifiable {
    var id: String
    var name: String
}

struct CheckoutItem: Identifiable {
    var id: String
    var name: String
}

// InventoryItem Model (No Local Storage)
struct UserItem: Identifiable {
    var id: String
    var userID: String
    var name: String
    var userPinHash: String
    var salt: String
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// FirestoreService for Firebase interaction
class FirestoreService {
    static let shared = FirestoreService()  // Singleton
    private let db = Firestore.firestore()
    
    func getFirestoreDB() -> Firestore {
        return db
    }
    
    // Add an inventory item to Firestore
    func addInventoryItem(itemID: String, name: String, completion: @escaping (Bool) -> Void) {
        let documentID = extractDocumentID(from: itemID)
        
        db.collection("inventory").document(documentID).setData([
            "itemID": itemID,
            "name": name,
        ]) { error in
            completion(error == nil)
        }
    }
    
    // Add an inventory item to Firestore
    func addCheckoutItem(itemID: String, name: String, completion: @escaping (Bool) -> Void) {
        let documentID = extractDocumentID(from: itemID)
        
        db.collection("inventory").document(documentID).setData([
            "itemID": itemID,
            "name": name,
        ]) { error in
            completion(error == nil)
        }
    }
    
    // Fetch all inventory items from Firestore
    func fetchInventoryItems(completion: @escaping ([InventoryItem]) -> Void) {
        db.collection("inventory").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching inventory: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let items = documents.compactMap { document -> InventoryItem? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let itemID = data["itemID"] as? String else { return nil }
                
                return InventoryItem(id: document.documentID, name: name)
            }
            
            completion(items)
        }
    }
    
    // Add an user item to Firestore
    func addUser(itemID: String, userID: String, name: String, userPinHash: String, salt: Data, completion: @escaping (Bool) -> Void)
    {
        let documentID = extractDocumentID(from: itemID)
        
        db.collection("users").document(documentID).setData([
            "userID": userID,
            "name": name,
            "userPinHash": userPinHash,
            "salt": salt,
        ]) { error in
            completion(error == nil)
        }
    }
    
    // Fetch all users from FireStore
    func fetchUsers(completion: @escaping ([UserItem]) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching users: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let users = documents.compactMap { document -> UserItem? in
                let data = document.data()
                guard let userId = data["userID"] as? String,
                      let name = data["name"] as? String,
                      let userPinHash = data["userPinHash"] as? String,
                      let salt = data["salt"] as? String else { return nil } // Fix here
                
                return UserItem(id: document.documentID, userID: userId, name: name, userPinHash: userPinHash, salt: salt) // Fix here
            }
            
            completion(users)
        }
    }

    

    
    // Delete an inventory item from Firestore
    func deleteInventoryItem(itemID: String, completion: @escaping (Bool) -> Void) {
        db.collection("inventory").document(itemID).delete { error in
            completion(error == nil)
        }
    }
    
    // Helper function to extract document ID from a URL or scanned code
    private func extractDocumentID(from scannedCode: String) -> String {
        if let lastSlashIndex = scannedCode.lastIndex(of: "/") {
            let id = scannedCode[lastSlashIndex...]
            return String(id.dropFirst())
        }
        return scannedCode
    }
    
    // Generate a random 16-byte salt and return it as Data
    func generateSalt(length: Int = 16) -> Data {
        var salt = Data(count: length)
        let result = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate random salt")
        }
        
        return salt
    }

    // Hash input with SHA-256 using the provided salt
    func sha256WithSalt(_ input: String, salt: Data) -> String {
        let inputData = Data(input.utf8)
        let saltedData = salt + inputData  // Append salt to input
        let hashed = SHA256.hash(data: saltedData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
