//
//  Inventory_Management_SystemApp.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-01-28.
//

import SwiftUI
import SwiftData

@main
struct Inventory_Management_SystemApp : App
{
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ApplicationData.self)
    }
}

//@main
//struct Inventory_Management_SystemApp: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}
