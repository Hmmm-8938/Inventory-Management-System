//
//  ApplicationData.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-02-24.
//

import Foundation
import SwiftData

@Model
class ApplicationData: Identifiable
{
    var id: String
    var name: String
    
    init(name: String)
    {
        self.id = UUID().uuidString
        self.name = name
    }
}
