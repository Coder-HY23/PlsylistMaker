//
//  Item.swift
//  PlaylistMaker
//
//  Created by Yuya HIRAMA on 2026/02/15.
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
