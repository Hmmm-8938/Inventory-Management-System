//
//  CheckoutView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-03-13.
//

import SwiftUI
import CodeScanner

struct CheckoutView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var isLoading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showFailure: Bool = false
    @State private var lastScannedItemName: String? = nil
    @State private var refreshID: UUID = UUID()  // Refresh trigger
    @State private var scannedItems: [String] = [] // Store scanned items locally
    @State private var isLoggedIn: Bool = false
    @State private var isSyncing = false
    @State private var items: [InventoryItem] = []
    @State private var users: [UserItem] = []
    @State private var loggedUser: String? = nil

    var body: some View {
        if (isLoggedIn)
        {
            ZStack
            {
                VStack
                {
                    Spacer()
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
                    VStack {
                        Text("Item Added Successfully!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text(itemName)
                            .font(.headline)
                            .padding(.top, 10)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .frame(width: 300, height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 2))
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
                    Spacer()
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
                                    Text("Scan User ID // Enter User Credentials")
                                }
                            }
                        }
                    // Code Scanner
                    CodeScannerView(codeTypes: [.code128]) { response in
                        switch response {
                            case .success(let result):
                                let scannedUserID = result.string
                                print("Scanning user ID: \(scannedUserID)")
                                // Check if user exists and fetch name
                                checkIfUserExists(userID: scannedUserID) { exists, name in
                                if exists, let userName = name
                                {
                                    print("User already exists: \(scannedUserID) - Name: \(userName)")
                                    DispatchQueue.main.async {
                                        self.isLoggedIn = true
                                        self.loggedUser = userName
                                    }
                                }
                                else
                                {
                                    print("Adding new user: \(scannedUserID)")
                                    addUser(result: scannedUserID, userID: scannedUserID, name: "Tester2")
                                }
                            }
                            case .failure(let error):
                                print("Scanner error: \(error.localizedDescription)")
                                triggerFailure()
                        }
                    }
                    .id(refreshID) // Force refresh when ID changes
                    // User Picker
                }
            }
        }
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
                      let name = data["name"] as? String else { return nil }
                
                return UserItem(
                    id: doc.documentID,
                    userID: userID,
                    name: name
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





    
    func addUser(result: String, userID: String, name: String) {
        // Add user to Firestore
        FirestoreService.shared.addUser(itemID: result, userID: userID, name: name) { success in
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


}
