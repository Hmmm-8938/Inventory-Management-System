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

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Calgary Zoo Inventory Management System")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                ActionButton(title: "Check Out", destination: ScannerView(), color: .red)
                ActionButton(title: "Check In", destination: ScannerView(), color: .green)
                ActionButton(title: "View Inventory", destination: CheckedOutItemsView(), color: .blue)

                Spacer()
            }
            .padding()
        }
    }
}

// Reusable button component for better styling
struct ActionButton<Destination: View>: View {
    let title: String
    let destination: Destination
    let color: Color

    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.title2)
                .frame(width: 300, height: 80)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(radius: 5)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
