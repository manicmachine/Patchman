//
//  PatchData.swift
//  PatchMan
//
//  Created by Corey Oliphant on 6/16/23.
//

import Foundation

struct PatchData: Identifiable {
    var id = UUID()

    var name: String
    var policyTargetVersion: String
    var availableVersion: String
    var availableDate: String
    var enabled: Bool
    
    var enabledString: String {
        enabled ? "True" : "False"
    }
}
