//
//  LibraryConfig.swift
//  SwiftOPAC
//
//  Created by Benjamin Bruch on 27.07.25.
//

public struct LibraryConfig: Codable, Sendable {
    public let api: String
    public let baseurl: String
    public let branches: [String]
    public let city: String
    public let country: String
    public let geo: [Double]
    public let id: Int
    public let login: Bool
    public let title: String
    public let website: String
    
    public init(api: String, baseurl: String, branches: [String], city: String, country: String, geo: [Double], id: Int, login: Bool, title: String, website: String) {
        self.api = api
        self.baseurl = baseurl
        self.branches = branches
        self.city = city
        self.country = country
        self.geo = geo
        self.id = id
        self.login = login
        self.title = title
        self.website = website
    }
}       