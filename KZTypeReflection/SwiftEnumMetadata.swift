//
//  SwiftEnumMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftEnumMetadata : SwiftNominalType {

    public struct InstanceStructure : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x02
        public var headerValue: Int
        
        var nominalTypeDescriptor: NominalTypeDescriptor
        
        ///////////////////////////////////////////
        // field offset - 0
        // begin generic parameters (eg - optional)
        ///////////////////////////////////////////
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