//
//  ObjCTypeEncoder.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 11/28/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public class ObjCTypeEncoder {
    public static let sharedEncoder = ObjCTypeEncoder()
    
    public init() {}
    
    public func encode(type: Any.Type) -> String {
        if type is AnyObject {
            return ObjCTypeChar.ID.asString
        }
        
        switch(type) {
        case AnyClass.self:
            return ObjCTypeChar.CLASS.asString
            
        case Selector.self:
            return ObjCTypeChar.SEL.asString
            
        case Int8.self:
            return ObjCTypeChar.CHR.asString
            
        case UInt8.self:
            return ObjCTypeChar.UCHR.asString
            
        case Int16.self:
            return ObjCTypeChar.SHT.asString
            
        case UInt16.self:
            return ObjCTypeChar.USHT.asString
            
        case Int32.self:
            return ObjCTypeChar.INT.asString
            
        case UInt32.self:
            return ObjCTypeChar.UINT.asString
            
        case Int64.self:
            return ObjCTypeChar.LNG_LNG.asString
            
        case UInt64.self:
            return ObjCTypeChar.ULNG_LNG.asString
            
        case Float.self:
            return ObjCTypeChar.FLT.asString
            
        case Double.self:
            return ObjCTypeChar.DBL.asString
            
        case Bool.self:
            return ObjCTypeChar.BOOL.asString
        case Void.self:
            return ObjCTypeChar.VOID.asString
            
        case UnsafeMutablePointer<Int8>.self:
            return ObjCTypeChar.CHARPTR.asString
            
        default:
            let structMetadata: SwiftStructMetadata = swiftMetadataForType(type) as! SwiftStructMetadata
            return encodeStruct(structMetadata)
        }
        
    }
    
    private func encodeStruct(type: SwiftStructMetadata) -> String {
        if type.fields.count == 1 {
            return encode(type.fields[0].type)
        }
        var name = type.name
        if name.hasPrefix("__C.") {
            name = String(name.characters.dropFirst(4))
        }
        var retval = "\(ObjCTypeChar.STRUCT_B)\(name)="
        for field in type.fields {
            retval += encode(field.type)
        }
        retval += "}"
        return retval
    }
}