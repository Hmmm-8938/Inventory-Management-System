//
//  CheckedOutItemsView.swift
//  Inventory Management System
//
//  Created by Kelsey Souchereau on 2025-02-24.
//

import SwiftUI

// Updated to support multiple items per person
struct CheckedOutRecord: Identifiable {
    let id = UUID()
    let personName: String
    let items: [String]
    let checkoutTime: Date
}

struct CheckedOutItemsView: View {
    @State private var checkedOutRecords: [CheckedOutRecord] = [
        CheckedOutRecord(personName: "John Doe", items: ["Femur Bone", "Dinosaur Skull"], checkoutTime: Date(timeIntervalSinceNow: -3600)),
        CheckedOutRecord(personName: "Jane Smith", items: ["Lion Pelt", "Tiger Claw"], checkoutTime: Date(timeIntervalSinceNow: -7200)),
        CheckedOutRecord(personName: "Michael Lee", items: ["Shark Tooth"], checkoutTime: Date(timeIntervalSinceNow: -5400))
    ]

    var body: some View {
        NavigationStack {
            VStack {
                Text("Checked Out Items")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                List {
                    ForEach(checkedOutRecords) { record in
                        CheckedOutRecordRow(record: record)
                    }
                }
                .listStyle(.plain)
            }
            .padding()
        }
    }
}

// Row component to display multiple items per person
struct CheckedOutRecordRow: View {
    let record: CheckedOutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.personName)
                .font(.headline)

            Text("Items:")
                .font(.subheadline)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                ForEach(record.items, id: \.self) { item in
                    Text("- \(item)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Text("Checked out at: \(formattedDate(record.checkoutTime))")
                .font(.footnote)
                .foregroundColor(.gray)

            Button(action: {
                // Logic for checking the items back in will go here
            }) {
                Text("Check In All Items")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 3)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    CheckedOutItemsView()
}
