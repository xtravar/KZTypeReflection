//
//  SwiftTupleMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftTupleMetadata : _SwiftMetadata {
    
    public struct InstanceStructure   : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x09
        public var headerValue: Int

		var count: Int
        
        var fieldNames: UnsafePointer<CChar>
        

        ////////////////////
		// begin items
        ////////////////////

		struct Item {
			var type: Any.Type
			var offset: Int
		}
	}


	// this should be the only member
	public let pointer: UnsafePointer <InstanceStructure>

	public init(pointer: UnsafePointer <InstanceStructure>) {
		self.pointer = pointer
	}
    
    public var fields: [SwiftField] {
        var retval = [SwiftField]()
        
        let count = self.pointer.memory.count
        
        let itemPtr = UnsafePointer<InstanceStructure.Item>(self.pointer.advancedBy(1))
        
        var fieldNames = self.pointer.memory.fieldNames
        
        for i in 0 ..< count {
            let item = itemPtr[i]
            let name: String = fieldNames != nil ? readStringFromMemory(&fieldNames, terminator: 32) : ""
            
            let ti = SwiftField(
                name: name,
                offset: item.offset,
                type: item.type
                )
            
            retval.append(ti)
        }
        return retval
    }
}