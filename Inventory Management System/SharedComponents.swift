//
//  SharedComponents.swift
//  Inventory Management System
//
//  Created by Kelsey Souchereau on 2025-04-01.
//


import SwiftUI

// Sleek, compact animated header component
struct AnimatedHeaderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var offsetY: CGFloat
    let onHomeButtonTapped: () -> Void
    
    var body: some View {
        // Solid background with gradient to ensure nothing shows through
        ZStack {
            // Make the background fully opaque
            Color.black.opacity(1).edgesIgnoringSafeArea(.top)
            
            // Clean gradient background using standard colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(1.0), // Full opacity
                    Color.indigo.opacity(1.0) // Full opacity
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.top)
            
            // Single row layout with all elements aligned horizontally
            HStack(alignment: .center, spacing: 10) {
                // Back button on the left
                Button(action: onHomeButtonTapped) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Centered title and subtitle
                VStack(alignment: .center, spacing: 2) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Icon on the right
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 15)// Adjust for safe area
        }
        .frame(height: 100) // More compact height
        .offset(y: offsetY)
        .animation(.easeOut(duration: 0.4), value: offsetY)
        .shadow(color: Color.black.opacity(0.3), radius: 6, y: 4)
        .zIndex(100) // Ensure this is always on top
    }
}

// PIN Entry View Component for shared use in check-in and check-out
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
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.black)
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
