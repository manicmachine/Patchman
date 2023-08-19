//
//  AuthToken.swift
//  PatchMan
//
//  Created by Corey Oliphant on 6/16/23.
//

import Foundation

class AuthToken: Codable {
    let token: String
    let expires: Date
}
