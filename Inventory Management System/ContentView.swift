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
        NavigationView
        {
            VStack
            {
                NavigationLink(destination: ScannerView())
                {
                    Text("Check Out")
                        .frame(width: 300, height: 150, alignment: .center)
                        .background(Color .gray)
                        .foregroundColor(Color .black)
                        .cornerRadius(50)
                        .border(Color .black)
                        
                        
                }
                NavigationLink(destination: ScannerView())
                {
                    Text("Check In")
                        .frame(width: 300, height: 150, alignment: .center)
                        .background(Color .gray)
                        .foregroundColor(Color .black)
                        .cornerRadius(50)
                }
                
                NavigationLink(destination: Test())
                {
                    Text("Check In")
                        .frame(width: 300, height: 150, alignment: .center)
                        .background(Color .gray)
                        .foregroundColor(Color .black)
                        .cornerRadius(50)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
