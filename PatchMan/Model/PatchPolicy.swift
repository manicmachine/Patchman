//
//  PatchPolicy.swift
//  PatchMan
//
//  Created by Corey Oliphant on 6/16/23.
//

import Foundation

struct PatchPolicy: Codable {
//    let id: String
//    let policyName: String
    let policyEnabled: Bool
    let policyTargetVersion: String
//    let policyDeploymentMethod: String
//    let softwareTitle: String
    let softwareTitleConfigurationId: String
//    let pending: Int
//    let completed: Int
//    let deferred: Int
//    let failed: Int
}

struct PatchPolicyResults: Codable {
    var totalCount: Int32
    var results: [PatchPolicy]
}
