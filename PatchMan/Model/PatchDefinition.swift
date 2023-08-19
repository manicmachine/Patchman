//
//  PatchDefinition.swift
//  PatchMan
//
//  Created by Corey Oliphant on 6/16/23.
//

import Foundation

struct PatchDefinition: Codable {
    let version: String
    var softwareTitleId: String? // This isn't part of the JSON response, but is added manually for tracking
    let releaseDate: String
//    let standalone: Bool
//    let minimumOperatingSystem: String
//    let rebootRequired: Bool
//    let killApps: [AppName]
//    let absoluteOrderId: String

//    struct AppName: Codable {
//        let appName: String
//    }
}

struct PatchDefinitionsResults: Codable {
    var totalCount: Int32
    var results: [PatchDefinition]
}
