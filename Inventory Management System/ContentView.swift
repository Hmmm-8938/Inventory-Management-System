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
   
   @Environment(\.modelContext) private var context
   @Query private var items: [Item]
   @Environment(\.colorScheme) private var colorScheme
   
   var body: some View {
       NavigationStack {
           ZStack {
               // Background gradient with the blue hex color - lighter at top, darker at bottom
               LinearGradient(
                   gradient: Gradient(colors: [Color(hex: "001058").opacity(0.4), Color(hex: "001058")]),
                   startPoint: .top,
                   endPoint: .bottom
               )
               .ignoresSafeArea()
               
               VStack(spacing: 32) {
                   VStack(spacing: 0) {
                       Image("Wilder_Institute-Calgary_Zoo_Logo")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 300, height: 150)
                       
                       Text("Educational Resource Collection Digital Signout")
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
                           gradient: Gradient(colors: [Color(hex: "E87722"), Color(hex: "E87722")])
                       )
                       
                       ActionButton(
                           title: "Check In",
                           icon: "arrow.left.circle.fill",
                           destination: ScannerView(),
                           gradient: Gradient(colors: [Color(hex: "64A70B"), Color(hex: "64A70B")])
                       )
                       
                       ActionButton(
                           title: "View Inventory",
                           icon: "list.clipboard.fill",
                           destination: CheckedOutItemsView(),
                           gradient: Gradient(colors: [Color(hex: "D40F7D"), Color(hex: "D40F7D")])
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
 
// Extension to create Color from hex code
extension Color {
   init(hex: String) {
       let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
       var int: UInt64 = 0
       Scanner(string: hex).scanHexInt64(&int)
       let a, r, g, b: UInt64
       switch hex.count {
       case 3: // RGB (12-bit)
           (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
       case 6: // RGB (24-bit)
           (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
       case 8: // ARGB (32-bit)
           (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
       default:
           (a, r, g, b) = (1, 1, 1, 0)
       }
       self.init(
           .sRGB,
           red: Double(r) / 255,
           green: Double(g) / 255,
           blue: Double(b) / 255,
           opacity: Double(a) / 255
       )
   }
}
 
#Preview {
   ContentView()
       .modelContainer(for: Item.self, inMemory: true)
}
