//
//  ContentView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott & Maxwell Souchereau on 2025-01-28.
//

import SwiftUI
import SwiftData
import CodeScanner
import WebKit
 
struct ContentView: View {
   
   @Environment(\.modelContext) private var context
   @Query private var items: [Item]
   @Environment(\.colorScheme) private var colorScheme
   
   // Admin functionality states
   @State private var showAdminLogin = false
   @State private var adminPassword = ""
   @State private var showAdminWebView = false
   @State private var showInvalidPasswordAlert = false
   
   var body: some View {
       NavigationStack {
           ZStack {
               
               LinearGradient(
                   gradient: Gradient(colors: [Color(hex: "4949FF").opacity(0.6), Color(hex: "A3A3FF")]),
                   startPoint: .bottom,
                   endPoint: .top
               )
               .ignoresSafeArea()
               
               VStack(spacing: 32) {
                   VStack(spacing: 0) {
                       Image("Wilder_Institute-Calgary_Zoo_Logo")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 350, height: 200)
                       
                       Text("E.R.C. Digital Signout")
                           .font(.title)
                           .fontWeight(.bold)
                           .multilineTextAlignment(.center)
                           .foregroundStyle(.white)
                   }
                   .padding(.top, 40)
                   
                   Spacer()
                   
                   // Buttons with intro text
                   VStack(spacing: 24) {
                       
                       ActionButton(
                           title: "Check Out",
                           icon: "arrow.right.circle.fill",
                           destination: CheckoutView(),
                           gradient: Gradient(colors: [Color(hex: "E87722"), Color(hex: "FF9F45")])
                       )
                       
                       ActionButton(
                           title: "Check In",
                           icon: "arrow.left.circle.fill",
                           destination: CheckinView(),
                           gradient: Gradient(colors: [Color(hex: "64A70B"), Color(hex: "8FCC2F")])
                       )
                       
                       ActionButton(
                           title: "View All Items",
                           icon: "list.clipboard.fill",
                           destination: CheckedOutItemsView(),
                           gradient: Gradient(colors: [Color(hex: "D40F7D"), Color(hex: "F064A6")])
                       )
                   }
                   .padding(.horizontal, 16)
                   
                   Spacer()
                   
                   // Admin button at bottom
                   HStack {
                       Button(action: {
                           showAdminLogin = true
                       }) {
                           HStack {
                               Image(systemName: "lock.shield")
                                   .font(.body)
                               Text("Admin")
                                   .font(.subheadline)
                                   .fontWeight(.medium)
                           }
                           .padding(.vertical, 10)
                           .padding(.horizontal, 16)
                           .background(
                               LinearGradient(
                                   gradient: Gradient(colors: [Color(hex: "001058").opacity(0.6), Color(hex: "001058").opacity(0.8)]),
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                           .foregroundColor(.white)
                           .clipShape(RoundedRectangle(cornerRadius: 12))
                           .overlay(
                               RoundedRectangle(cornerRadius: 12)
                                   .stroke(.white.opacity(0.3), lineWidth: 1)
                           )
                       }
                       
                       Spacer()
                   }
                   .padding(.top, -20)
               }
               .padding(.horizontal, 24)
               .padding(.bottom, 40)
           }
           // Admin login sheet
           .sheet(isPresented: $showAdminLogin) {
               ZStack {
                   // Use the same background color as the main view
                   Color(hex: "001058").opacity(0.95)
                       .ignoresSafeArea()
                   
                   VStack(spacing: 24) {
                       Text("Administrator Login")
                           .font(.title2)
                           .fontWeight(.bold)
                           .foregroundColor(.white)
                       
                       SecureField("Password", text: $adminPassword)
                           .padding()
                           .background(Color.white.opacity(0.2))
                           .cornerRadius(12)
                           .padding(.horizontal)
                           .foregroundColor(.white)
                           .autocapitalization(.none)
                           .overlay(
                               RoundedRectangle(cornerRadius: 12)
                                   .stroke(.white.opacity(0.3), lineWidth: 1)
                                   .padding(.horizontal)
                           )
                       
                       HStack(spacing: 20) {
                           // Login button
                           Button(action: {
                               if adminPassword == "password" {
                                   adminPassword = "" // Clear password
                                   showAdminLogin = false // Close dialog
                                   showAdminWebView = true // Show the web view
                               } else {
                                   showInvalidPasswordAlert = true
                               }
                           }) {
                               Text("Login")
                                   .font(.title3)
                                   .fontWeight(.semibold)
                                   .frame(maxWidth: .infinity)
                                   .padding(.vertical, 14)
                                   .background(
                                       LinearGradient(
                                           gradient: Gradient(colors: [Color(hex: "D40F7D"), Color(hex: "D40F7D")]),
                                           startPoint: .leading,
                                           endPoint: .trailing
                                       )
                                   )
                                   .foregroundColor(.white)
                                   .cornerRadius(12)
                                   .overlay(
                                       RoundedRectangle(cornerRadius: 12)
                                           .stroke(.white.opacity(0.3), lineWidth: 1)
                                   )
                           }
                           
                           // Cancel button
                           Button(action: {
                               adminPassword = "" // Clear password
                               showAdminLogin = false // Close dialog
                           }) {
                               Text("Cancel")
                                   .font(.title3)
                                   .fontWeight(.semibold)
                                   .frame(maxWidth: .infinity)
                                   .padding(.vertical, 14)
                                   .background(Color.gray.opacity(0.3))
                                   .foregroundColor(.white)
                                   .cornerRadius(12)
                                   .overlay(
                                       RoundedRectangle(cornerRadius: 12)
                                           .stroke(.white.opacity(0.3), lineWidth: 1)
                                   )
                           }
                       }
                       .padding(.horizontal)
                   }
                   .padding(.vertical, 40)
                   .alert(isPresented: $showInvalidPasswordAlert) {
                       Alert(
                           title: Text("Invalid Password"),
                           message: Text("The password you entered is incorrect."),
                           dismissButton: .default(Text("Try Again"))
                       )
                   }
               }
               .presentationDetents([.height(280)])
           }
           // Admin web view
           .fullScreenCover(isPresented: $showAdminWebView) {
               ZStack {
                   AdminWebView(url: URL(string: "https://calgary-zoo-admin.vercel.app")!)
                       .ignoresSafeArea()
                   
                   // Close button
                   VStack {
                       HStack {
                           Spacer()
                           Button(action: {
                               showAdminWebView = false
                           }) {
                               Image(systemName: "xmark.circle.fill")
                                   .font(.title)
                                   .foregroundColor(.white)
                                   .padding(8)
                                   .background(Color.black.opacity(0.7))
                                   .clipShape(Circle())
                                   .padding()
                                   .shadow(radius: 3)
                           }
                       }
                       Spacer()
                   }
               }
           }
       }
   }
}

// Cool lil' button animation
struct ActionButton<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination
    let gradient: Gradient
    @State private var isPressed = false
    @State private var animateIcon = false
    
    var body: some View {
        NavigationLink(destination:
            destination
            .navigationBarBackButtonHidden(true)
        ) {
            HStack(spacing: 16) {
                // Left icon with animation
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                gradient: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: Color(gradient.stops.first?.color ?? .clear).opacity(0.5), radius: 8, x: 0, y: 4)
                    )
                    .rotationEffect(Angle(degrees: animateIcon ? 10 : 0))
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animateIcon = true
                        }
                    }
                
                // Text with subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                }
                
                Spacer()
                
                // Right arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // Main background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Top highlight
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.5), .clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPressed ? 0.5 : 1.5
                        )
                }
            )
            .cornerRadius(16)
            .shadow(color: Color(gradient.stops.first?.color ?? .clear).opacity(0.4), radius: isPressed ? 5 : 12, x: 0, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
                self.isPressed = pressing
            }, perform: {})
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

// WebView for Admin Panel
struct AdminWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No update needed
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
