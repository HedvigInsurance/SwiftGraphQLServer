//
//  Map+Decodable.swift
//  SwiftGraphQLServer
//
//  Created by Sam Pettersson on 2019-04-02.
//

import Foundation
import GraphQL
import Vapor

enum MapDecodeError: Error, Debuggable {
    var identifier: String {
        return "decode error"
    }
    
    var reason: String {
        return "Could not decode GraphQL variable"
    }
    
    case unmatchedValue
}

extension Map: Decodable {
    public init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self.init(string)
        } else if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self.init(int)
        } else if let double = try? decoder.singleValueContainer().decode(Double.self) {
            self.init(double)
        } else if let bool = try? decoder.singleValueContainer().decode(Bool.self) {
            self.init(bool)
        } else if let _ = try? decoder.singleValueContainer().decodeNil() {
            self.init(nilLiteral: ())
        } else {
            throw MapDecodeError.unmatchedValue
        }
    }
}

