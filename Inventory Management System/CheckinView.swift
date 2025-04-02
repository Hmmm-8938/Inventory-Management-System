//
//  CheckinView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-04-01.
//

import SwiftUI
import CodeScanner
import CryptoKit
import FirebaseFirestore


struct CheckinView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var isLoading: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var isSyncing = false
    @State private var items: [CheckinItem] = []
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


    var body: some View {
        if (isLoggedIn) {
            // IMPORTANT: Match the ZStack structure EXACTLY to CheckoutView
            ZStack {
                VStack(spacing: 0) {
                    AnimatedHeaderView(
                        title: "Check In Items",
                        subtitle: "Welcome \(loggedUser ?? "user")! Check-in items here.",
                        systemImage: "arrow.left.circle.fill",
                        offsetY: $headerOffsetY,
                        onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
                    )
                    
                    // Content area - this stays inside the VStack but not in a nested VStack
                    Text("Checked Out Items")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    List {
                        if items.isEmpty {
                            Text("No items checked out.")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                        } else {
                            ForEach(items, id: \.id) { item in
                                if (item.userID == scannedUserID)
                                {
                                    Text(item.name)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .onAppear {
                        syncInventoryData()
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        headerOffsetY = 0
                    }
                }
                
                // Moved outside the VStack to match CheckoutView structure
                if isSyncing {
                    ProgressView("Syncing...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
        }
        else {
            ZStack {
                VStack(spacing: 0) {
                    AnimatedHeaderView(
                        title: "User Authentication",
                        subtitle: "Please scan your User ID to continue",
                        systemImage: "person.badge.key.fill",
                        offsetY: $headerOffsetY,
                        onHomeButtonTapped: { presentationMode.wrappedValue.dismiss() }
                    )
                    
                    // Important: The scanner is directly in this VStack, not wrapped in another VStack
                    CodeScannerView(codeTypes: [.code128]) { response in
                        switch response {
                            case .success(let result):
                                scannedUserID = result.string
                                print("Scanning user ID: \(scannedUserID)")

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

                                Text("Enter PIN")
                                    .font(.headline)

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
                                
                                Text("Enter Your Name:")
                                    .font(.headline)
                                
                                TextField("Name", text: $userInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                
                                if userInput != "" {
                                    Text("Create a PIN:")
                                        .font(.headline)
                                        .padding(.top, 8)
                                        
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
    
    // The rest of the code remains unchanged
    private func syncInventoryData() {
        isSyncing = true
        FirestoreService.shared.getFirestoreDB().collection("CheckedOutItems").getDocuments { snapshot, error in
            isSyncing = false
            if let error = error {
                print("Error fetching data from Firestore: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No inventory items found in Firestore.")
                return
            }

            print("Fetched \(documents.count) items from Firestore.")
            print("Fetched documents: \(documents)")  // Debugging
            
            items = documents.compactMap { doc -> CheckinItem? in
                let data = doc.data()
                print("Document ID: \(doc.documentID)")  // Print the document ID for each item
                print("Document data: \(data)")  // Print the data of each document

                // Convert checkOutTime from FIRTimestamp to Date
                guard let checkOutTimeTimestamp = data["checkOutTime"] as? Timestamp else {
                    print("Missing or invalid checkOutTime in document \(doc.documentID)")
                    return nil
                }
                let checkOutTime = checkOutTimeTimestamp.dateValue()

                guard let itemID = data["itemID"] as? String else {
                    print("Missing or invalid itemID in document \(doc.documentID)")
                    return nil
                }
                guard let name = data["name"] as? String else {
                    print("Missing or invalid name in document \(doc.documentID)")
                    return nil
                }
                guard let userID = data["userID"] as? String else {
                    print("Missing or invalid userID in document \(doc.documentID)")
                    return nil
                }
                guard let usersName = data["usersName"] as? String else {
                    print("Missing or invalid usersName in document \(doc.documentID)")
                    return nil
                }

                let checkinItem = CheckinItem(
                    id: itemID,
                    checkOutTime: checkOutTime,
                    name: name,
                    userID: userID,
                    usersName: usersName
                )
                print("Added CheckinItem: \(checkinItem)")  // Debugging
                return checkinItem
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
                    completion(true, name) // User exists
                } else {
                    print("User not found.")
                    completion(false, nil) // User does not exist
                }
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
        }
        else {
            self.showError = true
            self.userPinEntry = "" // Reset the PIN entry
        }
    }
    
    private func completeRegistration() {
        let salt = generateSalt()
        let hashedPin = hashWithSalt(userPinEntry, salt: salt)
        addUser(result: scannedUserID, userID: scannedUserID, name: userInput, userPinHash: hashedPin, salt: salt)
        showUserRegistration = false
        self.isLoggedIn = true
        self.loggedUser = userInput
        globalUserName = userInput
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
