//
//  MachOSection.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/4/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

internal func safeMachString(input: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) -> String! {
    var chars: [Int8] = [
        input.0,
        input.1,
        input.2,
        input.3,
        input.4,
        input.5,
        input.6,
        input.7,
        input.8,
        input.9,
        input.10,
        input.11,
        input.12,
        input.13,
        input.14,
        input.15,
        
        0
    ]
    
    return String.fromCString(&chars)
}

public class MachOSection {
    public let name: String
    public let address: UnsafePointer<Void>
    public let size: UInt64
    
    init<T: MachOSectionType>(section: T, baseAddress: UnsafePointer<Void>) {
        self.name = safeMachString(section.sectname)
        self.address = baseAddress.advancedBy(Int(section.offset.toIntMax()))
        self.size = section.size.toUIntMax()
    }
    
    public func containsAddress(address: UnsafePointer<Void>) -> Bool {
        let diff = Int64(address - self.address)
        if diff >= 0 && diff < Int64(self.size) {
            return true
        }
        return false
    }
}