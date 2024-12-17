//
//  FlappyBirdApp.swift
//  FlappyBird
//
//  Created by Om Preetham Bandi on 12/15/24.
//

import SwiftUI
import SwiftData

@main
struct FlappyBirdApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            FlappyBirdGameView()
        }
        .modelContainer(sharedModelContainer)
    }
}
