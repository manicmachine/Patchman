//
//  PatchManApp.swift
//  PatchMan
//
//  Created by Corey Oliphant on 5/26/23.
//

import SwiftUI

@main
struct PatchManApp: App {
    @StateObject private var patchService = PatchService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(patchService)
        }
    }
}
