//
//  SwiftMetadata.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public protocol SwiftMetadata {
    init(type: Any.Type)
    init(voidPointer: UnsafePointer<Void>)

    var voidPointer: UnsafePointer<Void> { get }
}

public extension SwiftMetadata {
    public init(type: Any.Type) {
        let voidPtr = unsafeBitCast(type, UnsafePointer<Void>.self)
        self.init(voidPointer: voidPtr)
    }
}


private let _typeMapping: [Int: SwiftMetadata.Type] = [
    // 1
    SwiftStructMetadata.headerConstant: SwiftStructMetadata.self,
    
    // 2
    SwiftEnumMetadata.headerConstant : SwiftEnumMetadata.self,
    
    // 3 - reserved?
    // 4 - reserved?
    // 5 - reserved?
    // 6 - reserved?
    // 7 - reserved?
    
    // 8
    SwiftOpaqueMetadata.headerConstant: SwiftOpaqueMetadata.self,
    
    // 9
    SwiftTupleMetadata.headerConstant : SwiftTupleMetadata.self,
    
    // 10
    SwiftClosureMetadata.headerConstant : SwiftClosureMetadata.self,
    
    // 11 - reserved?
    
    // 12
    SwiftProtocolMetadata.headerConstant : SwiftProtocolMetadata.self,
    
    // 13
    SwiftMetatypeMetadata.headerConstant: SwiftMetatypeMetadata.self,
    
    // 14
    SwiftObjCClassMetadata.headerConstant : SwiftObjCClassMetadata.self,
    
    // 15 - reserved?
    
    // 16
    SwiftEphemeralMetatypeMetadata.headerConstant: SwiftEphemeralMetatypeMetadata.self,
    
    // 0x80
    SwiftClassMetadata.headerConstant: SwiftClassMetadata.self
]

public func swiftMetadataForType(type: Any.Type) -> SwiftMetadata {
    var header = unsafeBitCast(type, UnsafePointer<Int>.self).memory
    if header > 0x80 {
        header = 0x80
    }
    
    let metadataType = _typeMapping[header]!
    return metadataType.init(type: type)
}

public protocol SwiftMetadataInstanceStructure {
    static var headerConstant: Int { get }
    var headerValue: Int { get }
}

// the real metadata - but it has generics
public protocol _SwiftMetadata : SwiftMetadata {
    typealias InstanceStructure: SwiftMetadataInstanceStructure
    var pointer: UnsafePointer<InstanceStructure> { get }
    init(pointer: UnsafePointer<InstanceStructure>)
}

public protocol SwiftNominalType : _SwiftMetadata {
    var nominalTypeDescriptor: NominalTypeDescriptor { get }
}

public extension _SwiftMetadata {
    init(voidPointer: UnsafePointer<Void>) {
        let pointer = UnsafePointer<InstanceStructure>(voidPointer)
        let constant = InstanceStructure.headerConstant
        let value = pointer.memory.headerValue
        precondition(constant == 0x80 ? value > 0x80 : constant == value, "Unexpected metatype")
        
        self.init(pointer: pointer)
    }
    
    public var voidPointer: UnsafePointer<Void> { return UnsafePointer<Void>(self.pointer) }
    
    public static var headerConstant: Int { return InstanceStructure.headerConstant }
}

public extension SwiftNominalType {
    public var mangledName: String {
        return self.nominalTypeDescriptor.name
    }
    
    public var name: String {
        let dec = SwiftSymbolDecoder.init(input: self.mangledName)
        let name = dec.scanTypeName()!
        return name
    }
    
    public var genericArguments: [Any.Type] {
        return self.nominalTypeDescriptor.getGenericArguments(self.pointer)
    }
    
    public var fields: [SwiftField] {
        return self.nominalTypeDescriptor.getFields(self.pointer)
    }
    
    public var symbols: [(name: String, value: UnsafePointer<Void>)] {
        if(self.dynamicType == SwiftClassMetadata.self) {
            return self.nominalTypeDescriptor.getSymbols(self.pointer)
        }
        
        return lookupSymbols()
    }
    
    private func lookupSymbols() -> [(name: String, value: UnsafePointer<Void>)] {
        return []
        /*
        let symbol = unsafeBitCast(self.pointer, UnsafePointer<Void>.self)
        var info = Dl_info()
        guard dladdr(symbol, &info) != 0 else {
            return []
        }
        
        var retval = [(name: String, value: UnsafePointer<Void>)]()
        var symSet = Set<UnsafePointer<Void>>()
        
    
        for var base = UnsafePointer<Int>(info.dli_fbase); dladdr(base, &info) != 0; base = base.advancedBy(1) {
            if info.dli_saddr == nil {
                continue
            }
            
            if symSet.contains(info.dli_saddr) {
                continue
            }
            symSet.insert(info.dli_saddr)
            
            let name = String.fromCString(info.dli_sname)!
            if !name.hasPrefix("_TF" + self.mangledName) {
                continue
            }
        
            retval.append((name: name, value: UnsafePointer<Void>(info.dli_saddr)))
        }
        
        
        return retval
        */
    }
}


public struct SwiftField {
    public let name: String
    public let offset: Int
    public let type: Any.Type
}

public extension SwiftMetadata {
    public var size: Int {
        return CommonTypeDescriptor(typePointer: self.voidPointer).size
    }
    
    public var alignment: Int {
        return CommonTypeDescriptor(typePointer: self.voidPointer).alignment
    }
    
    public var stride: Int {
        return CommonTypeDescriptor(typePointer: self.voidPointer).stride
    }
}


internal func readStringFromMemory(inout strPtr : UnsafePointer<CChar>, terminator: CChar = 0) -> String {
    var buffer = [CChar]()
    while strPtr.memory != terminator {
        buffer.append(strPtr.memory)
        strPtr = strPtr.advancedBy(1)
    }
    
    buffer.append(0)
    strPtr = strPtr.advancedBy(1) // skip terminator
    return String.fromCString(&buffer)!
}