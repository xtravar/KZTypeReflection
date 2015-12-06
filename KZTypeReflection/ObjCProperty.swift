//
//  ObjCProperty.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

extension CollectionType {
    typealias V = Self.Generator.Element
    func firstObject(@noescape predicate: (V) throws -> Bool) rethrows -> V? {
        guard let index = try self.indexOf(predicate) else {
            return nil
        }
        return self[index]
    }
}

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

extension ObjCProperty {
    public var propertyType: Any.Type {
        for attr in self.attributes {
            if case .PropertyType(let type) = attr {
                return type
            }
        }
        preconditionFailure()
    }
    
    public var getter: Selector {
        for attr in self.attributes {
            if case .Getter(let getter) = attr {
                return getter
            }
        }
        return Selector(self.name)
    }
    
    public var setter: Selector? {
        for attr in self.attributes {
            if case .ReadOnly = attr {
                return nil
            }
            
            if case .Setter(let setter) = attr {
                return setter
            }
        }
        
        var chars = self.name.characters
        let firstChar = chars.popFirst()!
        
        
        return Selector("set" + String(firstChar).capitalizedString + String(chars) + ":")
    }
}

internal class ObjCPropertyList : ObjCRuntimeAllocatedList<AnyClass!, objc_property_t> {
    internal init(type: AnyClass) {
        super.init(parent: type, allocator: class_copyPropertyList)
    }
}
