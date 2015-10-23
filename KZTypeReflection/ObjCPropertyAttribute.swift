//
//  ObjCPropertyAttribute.swift
//  KZObjCRuntime
//
//  Created by Mike Kasianowicz on 7/9/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

internal enum ObjCPropertyAttributeName : UnicodeScalar {
    init?(rawCCharValue: CChar) {
        let uni = UnicodeScalar(Int(rawCCharValue))
        self.init(rawValue: uni)
    }
    case PropertyType = "T"
    case Setter = "S"
    case Getter = "G"
    case Variable = "V"
    case Copy = "C"
    case ReadOnly = "R"
    case Weak = "W"
    case Strong = "&"
    case Nonatomic = "N"
    case Dynamic = "D"
}

public enum ObjCPropertyAttribute {
    public init?(attribute: objc_property_attribute_t) {
        guard let name = ObjCPropertyAttributeName(rawCCharValue: attribute.name.memory) else {
            preconditionFailure("unrecognized objc property attribute")
        }
        switch(name) {
        case ObjCPropertyAttributeName.PropertyType:
            self = .PropertyType(ObjCTypeDecoder.sharedDecoder.typeFromCString(attribute.value)!)

        case ObjCPropertyAttributeName.Setter:
            self = .Setter(sel_registerName(attribute.value))

        case ObjCPropertyAttributeName.Getter:
            self = .Getter(sel_registerName(attribute.value))

        case ObjCPropertyAttributeName.Variable:
            self = .Variable(String.fromCString(attribute.value)!)

        case ObjCPropertyAttributeName.Copy:
            self = .Copy

        case ObjCPropertyAttributeName.ReadOnly:
            self = .ReadOnly

        case ObjCPropertyAttributeName.Weak:
            self = .Weak

        case ObjCPropertyAttributeName.Strong:
            self = .Strong

        case ObjCPropertyAttributeName.Nonatomic:
            self = .Nonatomic
            
        case ObjCPropertyAttributeName.Dynamic:
            self = .Dynamic
        }

    }

    case PropertyType(Any.Type)
    case Setter(ObjectiveC.Selector)
    case Getter(ObjectiveC.Selector)
    case Variable(Swift.String)
    case ReadOnly
    case Copy
    case Weak
    case Strong
    case Nonatomic
    case Dynamic
}


internal class ObjCPropertyAttributeList : ObjCRuntimeAllocatedList<objc_property_t, objc_property_attribute_t> {
    internal init(property: objc_property_t) {
        super.init(parent: property, allocator: property_copyAttributeList)
    }
}

