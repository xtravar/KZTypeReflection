//
//  SwiftEphemeralMetatypeMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftEphemeralMetatypeMetadata : _SwiftMetadata {

    public struct InstanceStructure  : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x0F
        public var headerValue: Int
        
        var type: Any.Type
        
        ///////////////////////////////////////////
        ///////////////////////////////////////////
    }
    
    //this should be the only member
    public let pointer: UnsafePointer<InstanceStructure>
    
    public init(pointer: UnsafePointer<InstanceStructure>) {
        self.pointer = pointer
    }
    
    public var type: Any.Type {
        return self.pointer.memory.type
    }
}