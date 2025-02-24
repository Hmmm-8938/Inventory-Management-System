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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.teal.opacity(0.4), .blue.opacity(0.9)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 0) {
                        Image("Wilder_Institute-Calgary_Zoo_Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 150)
                        
                        Text("BioFact Management System")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 50) {
                        ActionButton(
                            title: "Check Out",
                            icon: "arrow.right.circle.fill",
                            destination: ScannerView(),
                            gradient: Gradient(colors: [.red, .orange])
                        )
                        
                        ActionButton(
                            title: "Check In",
                            icon: "arrow.left.circle.fill",
                            destination: ScannerView(),
                            gradient: Gradient(colors: [.green, .mint])
                        )
                        
                        ActionButton(
                            title: "View Inventory",
                            icon: "list.clipboard.fill",
                            destination: CheckedOutItemsView(),
                            gradient: Gradient(colors: [.blue, .purple])
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// Updated button design to look cooler
struct ActionButton<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination
    let gradient: Gradient
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                LinearGradient(
                    gradient: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
