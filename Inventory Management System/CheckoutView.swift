//
//  CheckoutView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-03-13.
//

import SwiftUI
import CodeScanner
import CryptoKit
import FirebaseFirestore


struct CheckoutView: View {
    @Environment(\.presentationMode) private var presentationMode
    let shared = sharedFunctions()
    @State private var isLoading: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var isSyncing = false
    @State private var items: [InventoryItem] = []
    @State private var lastScannedItemName: String? = nil
    @State private var loggedUser: String? = nil
    @State private var pin: [String] = Array(repeating: "", count: 4)
    @State private var refreshID: UUID = UUID()  // Refresh trigger
    @State private var scannedItems: [String] = [] // Store scanned items locally
    @State private var scannedUserID: String = ""
    @State private var showConfirmation: Bool = false
    @State private var showError: Bool = false
    @State private var showFailure: Bool = false
    @State private var showPinEntry: Bool = false
    @State private var showUserRegistration: Bool = false // To track if user registration is needed
    @State private var userName: String? = nil
    @State private var userPinEntry: String = ""
    @State private var users: [UserItem] = []
    @State private var salt: String = ""
    @State private var userSalt: Data = Data() // To hold the generated salt
    @State private var userInput: String = ""
    @State private var showPrompt: Bool = false
    @State private var globalUserPinHash: String = ""
    @State private var globalUserName: String = ""
    @State private var newItemName: String = ""
    @State private var headerOffsetY: CGFloat = -100 // For header animation
    @State private var showAlreadyCheckedOut: Bool = false
    
    var body: some View {
        if (isLoggedIn) {
            ZStack {
                VStack(spacing: 0) {
                    AnimatedHeaderView(
                        title: "Check Out Items",
                        subtitle: "Welcome \(loggedUser ?? "user")! Scan Biofact QR Code!",
                        systemImage: "arrow.right.circle.fill",
                        offsetY: $headerOffsetY,
                        onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
                    )
                    
                    CodeScannerView(codeTypes: [.qr]) { response in
                        switch response {
                        case .success(let result):
                            let scannedItemID = result.string
                            print("Scanning item QR Code: \(scannedItemID)")

                            // Check if item exists and fetch name
                            checkIfItemExists(itemID: scannedItemID) { exists, name in
                                if exists, let itemName = name {
                                    print("Item already exists: \(scannedItemID) - Name: \(itemName)")
                                    checkOutItem(itemID: scannedItemID, name: itemName, userID: scannedUserID, usersName: globalUserName)
                                } else {
                                    print("Adding new item: \(scannedItemID)")
                                    addItem(result: scannedItemID) { newItemName in
                                        if let newItemName = newItemName {
                                            checkOutItem(itemID: scannedItemID, name: newItemName, userID: scannedUserID, usersName: globalUserName)
                                        } else {
                                            print("Failed to add item, check out not performed.")
                                        }
                                    }
                                }
                            }

                        case .failure(let error):
                            print("Scanner error: \(error.localizedDescription)")
                            triggerFailure()
                        }
                    }
                    .id(refreshID)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        headerOffsetY = 0
                    }
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
                    VStack(spacing: 10) {
                        Text("✅ Item Added Successfully!")
                            .font(.headline) // Smaller size
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text("You have successfully added:")
                            .font(.subheadline)
                            .foregroundColor(.black) // Changed to black

                        Text(itemName)
                            .font(.footnote) // Smaller font for long item names
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil) // Allow full item name display
                            .frame(maxWidth: 300) // Limit width to avoid overflow

                        Text("You can continue scanning more items or proceed to checkout.")
                            .font(.caption)
                            .foregroundColor(.black) // Changed to black
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .frame(width: 350, height: 180) // Adjusted for better readability
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
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
                
                // Item already checked out message
                if showAlreadyCheckedOut, let itemName = lastScannedItemName {
                    VStack(spacing: 10) {
                        Text("❌ Item Already Checked Out!")
                            .font(.headline) // Smaller size
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        Text("This item is currently checked out:")
                            .font(.subheadline)
                            .foregroundColor(.black) // Changed to black

                        Text(itemName)
                            .font(.footnote) // Smaller font for long item names
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil) // Allow full item name display
                            .frame(maxWidth: 300) // Limit width to avoid overflow

                        Text("Item must be checked back in before checking out.")
                            .font(.caption)
                            .foregroundColor(.black) // Changed to black
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .frame(width: 350, height: 180) // Adjusted for better readability
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 2))
                    .transition(.scale)
                }
            }
            .navigationBarHidden(true)
        } else {
            ZStack {
                VStack(spacing: 0) {
                    AnimatedHeaderView(
                        title: "User Authentication",
                        subtitle: "Please scan your User ID to continue",
                        systemImage: "person.badge.key.fill",
                        offsetY: $headerOffsetY,
                        onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
                    )
                    
                    CodeScannerView(codeTypes: [.code128]) { response in
                        switch response {
                            case .success(let result):
                                scannedUserID = result.string
                                print("Scanning user ID: \(scannedUserID)")

                                // Check if user exists and fetch name
                                checkIfUserExists(userID: scannedUserID) { exists, name in
                                    DispatchQueue.main.async {
                                        if exists, let userName = name {
                                            print("User already exists: \(scannedUserID) - Name: \(userName)")
                                            self.userName = userName
                                            self.showPinEntry = true
                                            self.userPinEntry = ""  // Reset PIN on new scan
                                            self.showError = false
                                        } else {
                                            print("New user detected. Prompting for details...")
                                            self.showUserRegistration = true
                                        }
                                    }
                                }
                            
                            case .failure(let error):
                                print("Scanner error: \(error.localizedDescription)")
                                triggerFailure()
                        }
                    }
                    .id(scannedUserID)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        headerOffsetY = 0
                    }
                }
                
                // Overlays are directly in the ZStack, outside the VStack
                if showPinEntry || showUserRegistration {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    if showPinEntry, let userName = userName {
                        VStack {
                            Spacer(minLength: 120)
                            
                            VStack(spacing: 20) {
                                Text("Welcome, \(userName)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)

                                Text("Enter PIN")
                                    .font(.headline)
                                    .foregroundColor(.black)

                                // Using the shared PinEntryView component
                                PinEntryView(pin: $userPinEntry) { enteredPin in
                                    print("Entered PIN: \(enteredPin)")
                                    userPinEntry = hashWithSalt(enteredPin, salt: userSalt)
                                    validatePin()
                                }

                                if showError {
                                    Text("Incorrect PIN, try again.")
                                        .foregroundColor(.red)
                                        .padding(.top, 8)
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.95))
                                    .shadow(radius: 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    )
                            )
                            .padding()
                            
                            Spacer()
                        }
                    }
                    
                    if showUserRegistration {
                        VStack {
                            Spacer(minLength: 120)
                            
                            VStack(spacing: 20) {
                                Text("Welcome, \(scannedUserID)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("Enter Your Name:")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                TextField("Name", text: $userInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                
                                if userInput != "" {
                                    Text("Create a PIN:")
                                        .font(.headline)
                                        .padding(.top, 8)
                                        
                                    // Using the shared PinEntryView component
                                    PinEntryView(pin: $userPinEntry) { enteredPin in
                                        print("Entered Name: \(userInput)")
                                        print("Entered PIN: \(enteredPin)")
                                        userPinEntry = enteredPin
                                        completeRegistration()
                                    }
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.95))
                                    .shadow(radius: 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    )
                            )
                            .padding()
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func validatePin() {
        print(userPinEntry)
        print(globalUserPinHash)
        if userPinEntry == globalUserPinHash {
            DispatchQueue.main.async {
                self.isLoggedIn = true
                self.loggedUser = userName
            }
        } else {
            self.showError = true
            self.userPinEntry = "" // Reset the PIN entry
        }
    }
    
    private func completeRegistration() {
        let salt = generateSalt()
        let hashedPin = hashWithSalt(userPinEntry, salt: salt)
        shared.addUser(result: scannedUserID, userID: scannedUserID, name: userInput, userPinHash: hashedPin, salt: salt)
        showUserRegistration = false
        self.isLoggedIn = true
        self.loggedUser = userInput
        globalUserName = userInput
    }
    
    func checkOutItem(itemID: String, name: String, userID: String, usersName: String) {
        // First, check if the item is already checked out
        Firestore.firestore().collection("CheckedOutItems")
            .whereField("itemID", isEqualTo: itemID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking if item is already checked out: \(error.localizedDescription)")
                    // Handle error (e.g., show an alert to the user)
                    return
                }

                guard let snapshot = snapshot else {
                    print("Error: Snapshot is nil")
                    return
                }

                if !snapshot.documents.isEmpty {
                    // Item is already checked out
                    print("Item \(name) with ID \(itemID) is already checked out.")
                    // Handle this case (e.g., show an alert to the user)
                    
                    // Set the state to show the "already checked out" message
                    DispatchQueue.main.async {
                        self.lastScannedItemName = name
                        self.showAlreadyCheckedOut = true
                        self.showConfirmation = false // Ensure success message is not shown
                        
                        // Hide the message after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            self.showAlreadyCheckedOut = false
                            shared.refreshScanner()
                        }
                    }
                    return
                }

                // If the item is not already checked out, proceed with the checkout
                let checkOutTime = Timestamp(date: Date())

                let checkoutData: [String: Any] = [
                    "itemID": itemID,
                    "name": name,
                    "checkOutTime": checkOutTime,
                    "userID": userID,
                    "usersName": usersName
                ]

                Firestore.firestore().collection("CheckedOutItems").addDocument(data: checkoutData) { error in
                    if let error = error {
                        print("Error checking out item: \(error.localizedDescription)")
                    } else {
                        print("Successfully checked out item \(name) with ID \(itemID) to \(usersName) with UserID of \(userID)")
                        
                        // Set the state to show the success message
                        DispatchQueue.main.async {
                            self.lastScannedItemName = name
                            self.showConfirmation = true
                            self.showAlreadyCheckedOut = false // Ensure "already checked out" message is not shown
                            
                            // Hide the message after 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                self.showConfirmation = false
                                shared.refreshScanner()
                            }
                        }
                    }
                }
            }
    }

    func addItem(result: String, completion: @escaping (String?) -> Void) {
        isLoading = true

        fetchTitlesFromAPI(result: result) { titles in
            DispatchQueue.main.async {
                self.isLoading = false

                guard let titles = titles, let itemName = titles.first else {
                    self.triggerFailure()
                    completion(nil)
                    return
                }

                self.scannedItems.append(contentsOf: titles)
                self.lastScannedItemName = itemName
                self.showConfirmation = true
                self.newItemName = itemName

                FirestoreService.shared.addInventoryItem(itemID: result, name: itemName) { success in
                    if success {
                        print("Successfully added to Firestore")
                        completion(itemName)
                    } else {
                        print("Failed to add to Firestore")
                        completion(nil)
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showConfirmation = false
                    shared.refreshScanner()
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
            shared.refreshScanner()
        }
    }
    
//    func refreshScanner() {
//        refreshID = UUID()
//    }
    
    private func syncUsersData() {
        isSyncing = true
        FirestoreService.shared.getFirestoreDB().collection("users").getDocuments { snapshot, error in
            isSyncing = false
            if let error = error {
                print("Error fetching data from Firestore: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No inventory items found.")
                return
            }
            
            users = documents.compactMap { doc -> UserItem? in
                let data = doc.data()
                guard let userID = data["userID"] as? String,
                      let name = data["name"] as? String,
                      let userPinHash = data["userPinHash"] as? String,
                      let salt = data["salt"] as? String else { return nil }
                
                return UserItem(
                    id: doc.documentID,
                    userID: userID,
                    name: name,
                    userPinHash: userPinHash,
                    salt: salt
                )
            }
        }
    }
    
    private func checkIfUserExists(userID: String, completion: @escaping (Bool, String?) -> Void) {
        print("Checking if user exists in Firestore: \(userID)")
        FirestoreService.shared.getFirestoreDB().collection("users")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking user: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }
                
                if let document = snapshot?.documents.first {
                    let name = document.data()["name"] as? String ?? "Unknown"
                    globalUserName = name
                    let salt = document.data()["salt"] as? Data
                    let userPinHash = document.data()["userPinHash"] as? String
                    globalUserPinHash = userPinHash ?? ""
                    userSalt = salt!
                    print("User found: \(name)")
                    completion(true, name)
                } else {
                    print("User not found.")
                    completion(false, nil)
                }
            }
    }
    
    private func checkIfItemExists(itemID: String, completion: @escaping (Bool, String?) -> Void) {
        print("Checking if item exists in Firestore: \(itemID)")
        FirestoreService.shared.getFirestoreDB().collection("inventory")
            .whereField("itemID", isEqualTo: itemID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking item: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }
                
                if let document = snapshot?.documents.first {
                    let name = document.data()["name"] as? String ?? "Unknown"
                    print("Item found: \(name)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        shared.refreshScanner()
                    }
                    
                    DispatchQueue.main.async {
                        self.lastScannedItemName = name
                        self.showConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showConfirmation = false
                        }
                    }
                    
                    completion(true, name)
                } else {
                    print("Item not found.")
                    completion(false, nil)
                }
            }
    }
    
//    func addUser(result: String, userID: String, name: String, userPinHash: String, salt: Data) {
//        FirestoreService.shared.addUser(itemID: result, userID: userID, name: name, userPinHash: userPinHash, salt: salt) { success in
//            if success {
//                print("Successfully added user to Firestore")
//            } else {
//                print("Failed to add user to Firestore")
//            }
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            refreshScanner()
//        }
//    }

    func hashWithSalt(_ input: String, salt: Data) -> String {
        let inputData = Data(input.utf8)
        let saltedData = salt + inputData
        let hashed = SHA256.hash(data: saltedData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    func generateSalt(length: Int = 16) -> Data {
        var salt = Data(count: length)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        return salt
    }
}
