//
//  LibraryConfig.swift
//  SwiftOPAC
//
//  Created by Benjamin Bruch on 27.07.25.
//

public struct LibraryConfig: Codable, Sendable {
    public let baseurl: String
    public let branches: [String]
    public let city: String
    public let country: String
    public let geo: [Double]
    public let id: Int
    public let login: Bool
    public let system: LibrarySystem
    public let title: String
    public let website: String

    public init(baseurl: String, branches: [String], city: String, country: String, geo: [Double], id: Int, login: Bool, system: String, title: String, website: String) {
        self.baseurl = baseurl
        self.branches = branches
        self.city = city
        self.country = country
        self.geo = geo
        self.id = id
        self.login = login
        self.system = LibrarySystem(rawValue: system) 
        self.title = title
        self.website = website
    }
}      

public enum LibrarySystem: String, Codable, Sendable {
    case sisisSunrise = "sisis"
    case unknown

    public init(rawValue: String) {
        switch rawValue {
        case "sisis":
            self = .sisisSunrise
        default:
            self = .unknown
        }
    }
}


