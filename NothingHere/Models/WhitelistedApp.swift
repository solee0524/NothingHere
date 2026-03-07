//
//  WhitelistedApp.swift
//  NothingHere
//

import Foundation

struct WhitelistedApp: Codable, Identifiable, Equatable {
    let bundleIdentifier: String
    let displayName: String

    var id: String { bundleIdentifier }
}
