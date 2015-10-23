//
//  SwiftClosureMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftClosureMetadata : _SwiftMetadata {
    
    public struct InstanceStructure : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x0A
        public var headerValue: Int
        
		var flags: Int

		var resultType: Any.Type
		var argumentTypes: Any.Type

		///////////////////////////////////////////
		///////////////////////////////////////////
	}


	// this should be the only member
	public let pointer: UnsafePointer <InstanceStructure>

	public init(pointer: UnsafePointer <InstanceStructure>) {
		self.pointer = pointer
	}
    
    public var resultType : Any.Type {
        return self.pointer.memory.resultType
    }
    
    public var argumentTypes : Any.Type {
        return self.pointer.memory.argumentTypes
    }
    
    public var convention: SwiftClosureConvention {
        return SwiftClosureConvention(rawValue: self.pointer.memory.flags)!
    }
}


public enum SwiftClosureConvention : Int {
    case Native = 0b00000000000000000000000001
    case Thin = 0b10000000000000000000000001
    case Block = 0b01000000000000000000000001
    case C = 0b11000000000000000000000001
    // case Method
    // case ObjCMethod
}