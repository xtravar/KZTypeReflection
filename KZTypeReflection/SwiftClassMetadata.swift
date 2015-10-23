//
//  SwiftMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

// this is designed to be a thin wrapper around the built-in swift data
// caching and performance optimizations are up to the consumer

// having only one stored member, this should be treated as a pointer type
public struct SwiftClassMetadata : SwiftNominalType {
    
    public struct InstanceStructure : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x80
		public var headerValue: Int

		var superClass: AnyClass

		var buckets: COpaquePointer // this always points to 0... ?

		var vtable: Int // this is always 0... ?

		// must have 1 flag set
		var pdata: Int

		var flags: Int32 // 1 - ?, 2 - swift only
		var f2: Int32

		var size: Int32
		var tos: Int32
		var metaDataSize: Int32

		var dword: Int32 // ?

		var nominalTypeDescriptor: NominalTypeDescriptor

		////////////////////////
		// list of generic types
		////////////////////////
	}
    
    //this should be the only member
    public let pointer: UnsafePointer<InstanceStructure>
    
    public init(pointer: UnsafePointer<InstanceStructure>) {
        self.pointer = pointer
    }
    
    public var nominalTypeDescriptor: NominalTypeDescriptor {
        return self.pointer.memory.nominalTypeDescriptor
    }
    
    public var superClass: AnyClass {
        return self.pointer.memory.superClass
    }
}
