//
//  CheckoutView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-03-13.
//

import SwiftUI
import CodeScanner
import CryptoKit

struct CheckoutView: View {
    @Environment(\.presentationMode) private var presentationMode
    
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
    @State private var userSalt: String = "" // To hold the generated salt
    @State private var userInput: String = ""
    @State private var showPrompt: Bool = false


    var body: some View {
        if (isLoggedIn)
        {
            ZStack
            {
                VStack
                {
                    VStack{}
                        .navigationBarBackButtonHidden(true)
                        .toolbar
                        {
                            ToolbarItem(placement: .navigationBarLeading)
                            {
                                HStack
                                {
                                    Button(action: { presentationMode.wrappedValue.dismiss() })
                                    {
                                        Image(systemName: "house")
                                        Text("Home")
                                    }
                                    Spacer()
                                    Text("Welcome \(loggedUser ?? "user")! Scan Biofact QR Code!")
                                        .fontWeight(.thin)
                                }
                            }
                        }
                    // Code Scanner
                    CodeScannerView(codeTypes: [.qr]) { response in
                        switch response {
                        case .success(let result):
                            let scannedItemID = result.string
                            print("Scanning item QR Code: \(scannedItemID)")
                            // Check if item exists and fetch name
                            checkIfItemExists(itemID: scannedItemID) { exists, name in
                                if exists, let itemName = name
                                {
                                    print("Item already exists: \(scannedItemID) - Name: \(itemName)")
                                }
                                else
                                {
                                    print("Adding new item: \(scannedItemID)")
                                    // Handle adding new item if necessary
                                    addItem(result: scannedItemID) // Add the item if it doesn't exist
                                }
                            }
                        case .failure(let error):
                            print("Scanner error: \(error.localizedDescription)")
                            triggerFailure()
                        }
                    }
                    .id(refreshID) // Force refresh when ID changes

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

                        Text(itemName)
                            .font(.footnote) // Smaller font for long item names
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil) // Allow full item name display
                            .frame(maxWidth: 300) // Limit width to avoid overflow

                        Text("You can continue scanning more items or proceed to checkout.")
                            .font(.caption)
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
            }
        }
        else
        {
            ZStack
            {
                VStack
                {
                    VStack{}
                        .navigationBarBackButtonHidden(true)
                        .toolbar
                        {
                            ToolbarItem(placement: .navigationBarLeading)
                            {
                                HStack
                                {
                                    Button(action: { presentationMode.wrappedValue.dismiss() })
                                    {
                                        Image(systemName: "house")
                                        Text("Home")
                                    }
                                    Spacer()
                                    Text("Please scan User ID!")
                                        .fontWeight(.thin)
                                }
                            }
                        }
                    // Code Scanner
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
                    .id(scannedUserID) // Refresh scanner when a new user is scanned
                    
                    if showPinEntry, let userName = userName
                    {
                        Text("Welcome, \(userName)")
                            .font(.headline)

                        Text("Enter PIN")
                            .font(.headline)

                        PinEntryView(pin: $userPinEntry) { enteredPin in
                            print("Entered PIN: \(enteredPin)")
                            userPinEntry = enteredPin
                            validatePin()
                            
                        }

                        if showError {
                            Text("Incorrect PIN, try again.")
                                .foregroundColor(.red)
                                .padding()
                        }

                    }
                    if showUserRegistration
                    {
                        let name = ""
                        let hashedPin = ""
                        
                        Text("Welcome, \(scannedUserID)")
                            .font(.headline)
                        
                        Text("Enter Your Name:")
                            .font(.headline)
                        
                        TextField("Name", text: $userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        if userInput != ""
                        {
                            PinEntryView(pin: $userPinEntry)
                            {
                                enteredPin in
                                print("Entered Name: \(userInput)")
                                print("Entered PIN: \(enteredPin)")
                                userPinEntry = enteredPin
                                completeRegistration()
                            }
                        }
                        
                    }
                }
                .padding()
            }
        }
    }
    
    private func validatePin()
    {
        if userPinEntry == "1234" {
            DispatchQueue.main.async
            {
                self.isLoggedIn = true
                self.loggedUser = userName
            }
        }
        else
        {
            self.showError = true
            self.userPinEntry = "" // Reset the PIN entry
        }
    }
    
    private func completeRegistration()
    {
        let salt = generateSalt()
        let hashedPin = hashWithSalt(userPinEntry, salt: salt)
        addUser(result: scannedUserID, userID: scannedUserID, name: userInput, userPinHash: hashedPin, salt: salt)
        showUserRegistration = false
        self.isLoggedIn = true
        self.loggedUser = userInput
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
                
                // Add item to Firestore-
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
            
            // Map Firestore documents to InventoryItem models
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
                    print("User found: \(name)")
                    completion(true, name) // User exists
                } else {
                    print("User not found.")
                    completion(false, nil) // User does not exist
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
                    
                    // Refresh scanner after item is found in Firestore
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.refreshScanner() // Refresh the scanner
                    }
                    
                    // Show confirmation message for fetched item
                    DispatchQueue.main.async {
                        self.lastScannedItemName = name
                        self.showConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3)
                        {
                            self.showConfirmation = false
                        }
                    }
                    
                    completion(true, name) // Item exists
                } else {
                    print("Item not found.")
                    completion(false, nil) // Item does not exist
                }
            }
    }
    
    func addUser(result: String, userID: String, name: String, userPinHash: String, salt: Data) {
        // Add user to Firestore
        FirestoreService.shared.addUser(itemID: result, userID: userID, name: name, userPinHash: userPinHash, salt: salt) { success in
            if success {
                print("Successfully added user to Firestore")
            } else {
                print("Failed to add user to Firestore")
            }
        }
        
        // Refresh scanner after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            refreshScanner()
        }
    }

    func hashWithSalt(_ input: String, salt: Data) -> String {
        let inputData = Data(input.utf8)
        let saltedData = salt + inputData  // Append salt to input
        let hashed = SHA256.hash(data: saltedData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    // Generate a random 16-byte salt
    func generateSalt(length: Int = 16) -> Data {
        var salt = Data(count: length)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        return salt
    }
    
    struct PinEntryView: View {
        @Binding var pin: String
        var onComplete: ((String) -> Void)?

        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]

        var body: some View {
            VStack {
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .frame(width: 20, height: 20)
                            .foregroundColor(index < pin.count ? .black : .gray)
                    }
                }
                .padding()

                ForEach(numbers, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { number in
                            Button(action: {
                                handleInput(number)
                            }) {
                                Text(number)
                                    .font(.largeTitle)
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .disabled(number.isEmpty)
                        }
                    }
                }
            }
        }

        private func handleInput(_ value: String) {
            if value == "⌫" {
                if !pin.isEmpty {
                    pin.removeLast()
                }
            } else if pin.count < 4 {
                pin.append(value)
                if pin.count == 4 {
                    onComplete?(pin)
                }
            }
        }
    }

    
}
