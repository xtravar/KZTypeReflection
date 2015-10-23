//
//  SwiftMetatypeMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftMetatypeMetadata : _SwiftMetadata {
    
    public struct InstanceStructure   : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x0D
        public var headerValue: Int
        
        var type: Any.Type
        var word0: COpaquePointer
        var word1: COpaquePointer
        var word2: COpaquePointer
        
        ///////////////////////////////////////////
        ///////////////////////////////////////////
    }
    
    
    //this should be the only member
    public let pointer: UnsafePointer<InstanceStructure>
    
    public init(pointer: UnsafePointer<InstanceStructure>) {
        self.pointer = pointer
    }
}