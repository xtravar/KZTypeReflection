//
//  ObjCTypeChar.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 8/2/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public enum ObjCTypeChar : Character {
    case ID  = "@"
    case CLASS  = "#"
    case SEL  = ":"
    case CHR  = "c"
    case UCHR  = "C"
    case SHT  = "s"
    case USHT  = "S"
    case INT  = "i"
    case UINT  = "I"
    case LNG  = "l"
    case ULNG  = "L"
    case LNG_LNG = "q"
    case ULNG_LNG = "Q"
    case FLT  = "f"
    case DBL  = "d"
    case BFLD  = "b"
    case BOOL  = "B"
    case VOID  = "v"
    case UNDEF  = "?"
    case PTR  = "^"
    case CHARPTR = "*"
    case ATOM  = "%"
    case ARY_B  = "["
    case ARY_E  = "]"
    case UNION_B = "("
    case UNION_E = ")"
    case STRUCT_B = "{"
    case STRUCT_E = "}"
    case VECTOR  = "!"
    case CONST  = "r"
    
    public func toSwiftType() -> Any.Type {
        switch(self) {
        case .CLASS:
            return AnyClass.self
        case .SEL:
            return Selector.self
        case .CHR:
            return Int8.self
        case .UCHR:
            return UInt8.self
        case .SHT:
            return Int16.self
        case .USHT:
            return UInt16.self
        case .INT:
            return Int32.self
        case .UINT:
            return UInt32.self
        case .LNG_LNG:
            return Int64.self
        case .ULNG_LNG:
            return UInt64.self
        case .LNG:
            return Int.self
        case .ULNG:
            return UInt.self
        case .FLT:
            return Float.self
        case .DBL:
            return Double.self
        case .BOOL:
            return Bool.self
        case .VOID:
            return Void.self
        case .CHARPTR:
            return UnsafeMutablePointer<Int8>.self
        default:
            preconditionFailure("Basic type not supported")
        }
    }
}