//
//  Library.swift
//  SwiftOPAC
//
//  Created by Benjamin Bruch on 27.07.25.
//

public enum Library : Sendable {
    case dresdenBibo

    public var remoteConfigURL: String {
        switch self {
        case .dresdenBibo:
            return "https://benjaminbruch.github.io/SwiftOPACLibraryConfig/bibs/Dresden.json"
        }
    }
}


