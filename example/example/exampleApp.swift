//
//  exampleApp.swift
//  example
//
//  Created by Qiwei Li on 4/4/26.
//

import SwiftUI

@main
struct exampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
