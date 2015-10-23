//
//  SwiftStructMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftStructMetadata : SwiftNominalType {
    public struct InstanceStructure : SwiftMetadataInstanceStructure {
        public static let headerConstant = 0x01
        
        public var headerValue: Int // 0x01
        
        var nominalTypeDescriptor: NominalTypeDescriptor
        
        var unknown01: UInt32
        var unknown02: UInt32
        
        /////////////////////////////////
        // begin word-sized field offsets
        // then generic parameter types
        ////////////////////////////////
    }
    
    
    //this should be the only member
    public let pointer: UnsafePointer<InstanceStructure>
    
    public init(pointer: UnsafePointer<InstanceStructure>) {
        self.pointer = pointer
    }
    
    public var nominalTypeDescriptor: NominalTypeDescriptor {
        return self.pointer.memory.nominalTypeDescriptor
    }
}