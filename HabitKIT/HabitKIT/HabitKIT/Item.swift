//
//  Item.swift
//  HabitKIT
//
//  Created by Deepak Roshan on 2026-06-01.
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
