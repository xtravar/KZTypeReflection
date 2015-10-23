//
//  ObjCClass.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct ObjCClass {
    private let type: AnyClass
    
    public init(type: AnyClass) {
        self.type = type
    }
    
    public var name: String {
        return String.fromCString(class_getName(self.type))!
    }
    
    public var fields: [ObjCField] {
        return ObjCFieldList(type: self.type).map { ObjCField(pointer: $0) }
    }
    
    public var methods: [ObjCMethod] {
        return ObjCMethodList(type: self.type).map { ObjCMethod(pointer: $0) }
    }
    
    public var properties: [ObjCProperty] {
        /*var retval = [ObjCProperty]()
        for prop in ObjCPropertyList(type: self.type) {
            if prop == nil {
                continue
            }
            retval.append(ObjCProperty(pointer: prop))
        }
        return retval*/
        return ObjCPropertyList(type: self.type).map{ ObjCProperty(pointer: $0) }
    }
}


internal class ObjCRuntimeAllocatedList<T, E> : CollectionType {
    internal let startIndex: Int = 0
    internal let endIndex: Int
    
    internal let elementsBase: UnsafeMutablePointer<E>
    internal let elements: UnsafeBufferPointer<E>
    
    internal subscript (position: Int) -> E {
        //print(self.elements[position])
        return self.elements[position]
    }
    
    internal init(parent: T, allocator: (T, UnsafeMutablePointer<UInt32>) -> UnsafeMutablePointer<E>) {
        var count = UInt32(0)
        self.elementsBase = allocator(parent, &count)
        self.endIndex = Int(count)
        self.elements = UnsafeBufferPointer(start: self.elementsBase, count: self.endIndex)
    }
    
    deinit {
        free(self.elementsBase)
    }
}



