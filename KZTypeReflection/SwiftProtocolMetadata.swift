//
//  SwiftCompositeProtocolMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct SwiftProtocolMetadata : _SwiftMetadata {
    
    public struct InstanceStructure : SwiftMetadataInstanceStructure  {
        public static let headerConstant = 0x0C
        public var headerValue: Int
        // 0x80000001 - swift-only
        // 0x00000001 - swift + objc
        // 0x00000000 - objc-only
        var flags: Int
        
        var numberOfProtocols: Int

        ///////////////////////////////////////////
		// list of pointer to Protocol or nil followed by CString
		///////////////////////////////////////////
	}


	// this should be the only member
    public let pointer: UnsafePointer <InstanceStructure>
    
    public init(pointer: UnsafePointer <InstanceStructure>) {
        self.pointer = pointer
    }
    
    public var protocols: [SwiftProtocolType] {
        var retval = [SwiftProtocolType]()
        
        var protoPtr = UnsafePointer<UnsafePointer<UnsafePointer<Void>>>(self.pointer.advancedBy(1))
        let numProtocols = self.pointer.memory.numberOfProtocols
        
        for i in 0 ..< numProtocols {
            let ptr = protoPtr[i]
            let value = ptr.memory
            if value == nil {
                let nameCString = UnsafePointer<CChar>(ptr[1])
                let name = String.fromCString(nameCString)!
                retval.append(.Swift(name))
            } else {
                retval.append(.ObjC(unsafeBitCast(value, Protocol.self)))
            }
            
            protoPtr = protoPtr.advancedBy(1)
        }
        
        return retval;
    }
}

public enum SwiftProtocolType {
    case Swift(String)
    case ObjC(Protocol)
}