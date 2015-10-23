//
//  SwiftObjCClassInfo.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftObjCClassMetadata : _SwiftMetadata {
    
    public struct InstanceStructure   : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x0E
        public var headerValue: Int
        
        var type: AnyClass
        
        ///////////////////////////////////////////
        ///////////////////////////////////////////
    }
    
    //this should be the only member
    public let pointer: UnsafePointer<InstanceStructure>
    
    public init(pointer: UnsafePointer<InstanceStructure>) {
        self.pointer = pointer
    }
    
    public var type: AnyClass {
        return self.pointer.memory.type
    }
}

