//
//  CheckedOutItemsView.swift
//  Inventory Management System
//
//  Created by Kelsey Souchereau on 2025-02-24.
//
import SwiftUI

struct CheckedOutRecord: Identifiable {
    let id = UUID()
    let personName: String
    let items: [String]
    let checkoutTime: Date
}
// Dummy Data, will be pulled from caching/offline
struct CheckedOutItemsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var checkedOutRecords: [CheckedOutRecord] = [
        CheckedOutRecord(personName: "John Doe", items: ["Femur Bone", "Dinosaur Skull"], checkoutTime: Date(timeIntervalSinceNow: -3600)),
        CheckedOutRecord(personName: "Jane Smith", items: ["Lion Pelt", "Tiger Claw"], checkoutTime: Date(timeIntervalSinceNow: -7200)),
        CheckedOutRecord(personName: "Michael Lee", items: ["Shark Tooth"], checkoutTime: Date(timeIntervalSinceNow: -5400))
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Checked Out Items")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Scan ID button
            NavigationLink(destination: ScannerView()) {
                Text("Scan ID")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)

            List {
                ForEach(checkedOutRecords) { record in
                    CheckedOutRecordRow(record: record)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                }
            }
            .listStyle(.plain)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(.blue)
        })
    }
}

// Row component to display multiple items per person
struct CheckedOutRecordRow: View {
    let record: CheckedOutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(record.personName)
                .font(.title2)
                .fontWeight(.bold)

            Text("Items:")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(record.items, id: \.self) { item in
                    Text("- \(item)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Text("Checked out at: \(formattedDate(record.checkoutTime))")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 4)

            Button(action: {
                // Logic for checking the items back in will go here
            }) {
                Text("Check In All Items")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            .padding(.top, 12)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 5)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        CheckedOutItemsView()
    }
}
