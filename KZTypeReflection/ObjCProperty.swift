//
//  ObjCProperty.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation


public struct ObjCProperty {
    public let name: String
    public let attributes: [ObjCPropertyAttribute]
    
    public init(pointer: objc_property_t) {
        let propName = property_getName(pointer)
        self.name = String.fromCString(propName)!
        self.attributes = ObjCPropertyAttributeList(property: pointer).map{ ObjCPropertyAttribute(attribute: $0)! }
    }
    
    /*
    private let pointer: objc_property_t
    
    public init(pointer: objc_property_t) {
        self.pointer = pointer
    }
    
    public var name: String {
        return String.fromCString(property_getName(self.pointer))!
    }
    
    public var attributes: [ObjCPropertyAttribute] {
        return [ObjCPropertyAttribute]()
    }
*/
}



internal class ObjCPropertyList : ObjCRuntimeAllocatedList<AnyClass!, objc_property_t> {
    internal init(type: AnyClass) {
        super.init(parent: type, allocator: class_copyPropertyList)
    }
}
