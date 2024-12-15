//
//  Item.swift
//  FlappyBird
//
//  Created by Om Preetham Bandi on 12/15/24.
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
