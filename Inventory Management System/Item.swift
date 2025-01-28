//
//  Item.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-01-28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
