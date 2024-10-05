//
//  Notes_AppApp.swift
//  Notes App
//
//  Created by Busha on 02/10/2024.
//

import SwiftUI

@main
struct Notes_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Note.self)
        }
    }
}
