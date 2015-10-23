//
//  ObjCInstanceVariable.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct ObjCField {
    public let name: String
    public let offset: Int
    public let type: Any.Type?
    
    public init(pointer: Ivar) {
        self.name = String.fromCString(ivar_getName(pointer))!
        self.offset = ivar_getOffset(pointer)
        let encoding = ivar_getTypeEncoding(pointer)
        let encodingStr = String.fromCString(encoding)!
        self.type = ObjCTypeDecoder.sharedDecoder.typeFromString(encodingStr)
    }
    
    /*
    private let pointer: Ivar
    
    public init(pointer: Ivar) {
        self.pointer = pointer
    }
    
    public var name: String {
        return String.fromCString(ivar_getName(self.pointer))!
    }
    
    public var offset: Int {
        return ivar_getOffset(self.pointer)
    }
    
    public var type: Any.Type {
        return ObjCTypeDecoder.sharedDecoder.typeFromCString(ivar_getTypeEncoding(self.pointer))!
    }
*/
}


internal class ObjCFieldList : ObjCRuntimeAllocatedList<AnyClass!, Ivar> {
    internal init(type: AnyClass!) {
        super.init(parent: type, allocator: class_copyIvarList)
    }
}