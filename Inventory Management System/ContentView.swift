//
//  ContentView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-01-28.
//

import SwiftUI
import SwiftData
import CodeScanner

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View
    {
        VStack(spacing: 20)
        {
            CodeScannerView(codeTypes: [.code128, .qr], simulatedData: "Paul Hudson") { response in
                switch response
                {
                    case .success(let result):
                    print("Found code: \(result.string)")
                    case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            Button("Sign in")
            {
                // Handle sign in
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
            
            Button("Sign out")
            {
                // Handle sign out
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 2))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
