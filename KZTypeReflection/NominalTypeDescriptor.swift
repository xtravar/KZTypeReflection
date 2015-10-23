//
//  MetaTypePointer.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/18/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation


public struct NominalTypeDescriptor {
    struct InstanceStructure {
        // 0x00
        var _header : Int // 1 for struct, 0 for class
        
        // 0x08
        var name : UnsafePointer<CChar>
        
        // 0x10
        var fieldCount : Int32
        
        // goes up by 3 for each property and 1 for each method
        var fieldTypesOffset : Int32
        
        // 0x18
        var fieldNames : UnsafePointer<CChar>
        
        // 0x20
        var getFieldData: COpaquePointer
        
        // 0x28
        var genericMetaData: UnsafePointer<GenericMetadataStruct>
        
        // 0x30
        var genericArgumentsOffset : Int32
        
        var genericArgumentsCount : Int32
        
        // 0x38
        var genericArgumentsCount2 : Int32 // could this be fulfilled? x out of y?
        
        var genericArgumentsFlags: Int32 // only 1 on dictionaries, why?
    }
    
    let pointer: UnsafePointer<InstanceStructure>
    
    init(pointer: UnsafePointer<Void>) {
        self.pointer = UnsafePointer<InstanceStructure>(pointer)
    }
    
    internal var name: String {
        return String.fromCString(pointer.memory.name)!
    }
    
    internal var genericArgumentsCount: Int {
        return Int(self.pointer.memory.genericArgumentsCount)
    }
    
    internal var genericArgumentsOffset: Int {
        return Int(self.pointer.memory.genericArgumentsOffset)
    }
    
    internal var isEnum: Bool {
        return self.pointer.memory._header == SwiftEnumMetadata.headerConstant
    }
    
    internal var isRawEnum: Bool {
        return self.isEnum && self.pointer.memory.fieldCount == 0
    }
    
    internal var fieldCount: Int {
        return Int(self.pointer.memory.fieldCount)
    }
    
    internal var fieldTypesOffset: Int {
        return Int(self.pointer.memory.fieldTypesOffset)
    }
    
    internal func getGenericArguments<T>(basePointer: UnsafePointer<T>) -> [Any.Type] {
        var retval = [Any.Type]()
        
        // COMMON CONSTANTS
        let endOfMetadataPtr = UnsafePointer<Int>(basePointer.successor())
        let metadataSizeInWords = sizeof(T.self) / sizeof(Int.self)
        
        // GENERIC AND FIELD TYPE PREP
        let genericCount = self.genericArgumentsCount
        
        // GENERIC PARAMETERS
        let genericTypeOffset = self.genericArgumentsOffset - metadataSizeInWords
        let genericPtr = UnsafePointer<Any.Type>(endOfMetadataPtr.advancedBy(genericTypeOffset))
        
        for j in 0 ..< genericCount {
            retval.append(genericPtr[j])
        }
        
        return retval
    }
    
    internal func getFieldTypePointer(basePointer: UnsafePointer<Void>) -> UnsafePointer<Any.Type> {
        let retval : UnsafePointer<Any.Type>
        
        typealias FieldCall = (@convention(c) (UnsafePointer<Void>) -> UnsafePointer<Void>)
        typealias GenericFieldCall = (@convention(c) (UnsafePointer<Void>, UnsafePointer<Void>) -> UnsafePointer<Void>)

        if self.genericArgumentsCount == 0 {
            let fn = unsafeBitCast(self.pointer.memory.getFieldData, FieldCall.self)
            retval = UnsafePointer<Any.Type>(fn(basePointer))
        } else {
            let fn = unsafeBitCast(self.pointer.memory.getFieldData, GenericFieldCall.self)
            retval = UnsafePointer<Any.Type>(fn(basePointer, self.pointer.memory.genericMetaData))
        }
        
        return retval
    }
    
    internal func getFields<T>(basePointer: UnsafePointer<T>) -> [SwiftField] {
        var retval = [SwiftField]()
        
        // COMMON CONSTANTS
        let endOfMetadataPtr = UnsafePointer<Int>(basePointer.successor())
        let metadataSizeInWords = sizeof(T.self) / sizeof(Int.self)
        
        // ENUM SHENANIGANS FOR FIELDS
        let isRawEnum = self.isRawEnum
        
        
        // FIELDS
        let fieldCount = isRawEnum ? self.fieldTypesOffset : self.fieldCount
        var fieldNamePtr = self.pointer.memory.fieldNames
        let fieldOffsetOffset = self.fieldTypesOffset - metadataSizeInWords
        let fieldOffsetPtr = endOfMetadataPtr.advancedBy(fieldOffsetOffset)
        let fieldTypePtr = getFieldTypePointer(basePointer)
        
        for i in 0 ..< fieldCount {
            let name = readStringFromMemory(&fieldNamePtr)
            let offset = isRawEnum ? 0 : fieldOffsetPtr[i]
            let type = isRawEnum ? Any.Type.self : fieldTypePtr[i]
            let field = SwiftField(name: name, offset: offset, type: type)
            retval.append(field)
        }
        return retval
    }
    
    // REMAINDER SYMBOLS - what could go wrong?
    internal func getSymbols<T>(basePointer: UnsafePointer<T>) -> [(name: String, value: UnsafePointer<Void>)] {
        var symbols = [(name: String, value: UnsafePointer<Void>)]()
        
        // COMMON CONSTANTS
        let endOfMetadataPtr = UnsafePointer<Int>(basePointer.successor())
        
        // raw enums don't have symbols
        if self.isRawEnum {
            return symbols
        }
        
        let maxLength = max(self.fieldTypesOffset + self.fieldCount, self.genericArgumentsOffset + self.genericArgumentsCount)
        /*
        let isFieldTypeIndex = { (index: Int) -> Bool in
            return index >= self.fieldTypesOffset && index < self.fieldTypesOffset + self.fieldCount
            }
        
        let isGenericParameterIndex = { (index: Int) -> Bool in
            return index >= self.genericParameterOffset && index < self.genericParameterOffset + self.genericParameterCount
            }
            */
        
        for k in 0 ..< maxLength {
            //if isFieldTypeIndex(k) || isGenericParameterIndex(k) {
            //    continue
            //}
            
            let symbol = unsafeBitCast(endOfMetadataPtr[k], UnsafePointer<Void>.self)
            var info = Dl_info()
            if dladdr(unsafeBitCast(endOfMetadataPtr[k], UnsafePointer<Void>.self), &info) != 0 {
                let symbolName = String.fromCString(info.dli_sname)!
                symbols.append((name: symbolName, value: symbol))
            }
        }
        return symbols
    }
    
    
    // this is the reference algorithm which we will ignore in liu of proper structures
    static func fromType(type: Any.Type) -> NominalTypeDescriptor? {
        let basePtr = unsafeBitCast(type, COpaquePointer.self)
        let baseWordPtr = UnsafePointer<Int>(basePtr)
        var header = baseWordPtr[0]
        if header > 0x80 {
            header = 0
        }
        
        if header < 3 {
            return NominalTypeDescriptor.init(pointer: UnsafePointer<Void>(bitPattern:baseWordPtr[1]))
        }
        
        if header != 0 {
            return nil
        }
        
        if baseWordPtr[4] & 1 == 0 {
            return nil
        }
        
        return NominalTypeDescriptor.init(pointer: UnsafePointer<Void>(bitPattern:baseWordPtr[8]))
    }
}

extension NominalTypeDescriptor : Equatable, Hashable, NilLiteralConvertible {
    public var hashValue: Int {return self.pointer.hashValue }
    
    public init(nilLiteral: ()) {
        self.pointer = nil
    }
}

public func ==(lhs: NominalTypeDescriptor, rhs: NominalTypeDescriptor) -> Bool {
    return lhs.pointer == rhs.pointer
}


// haven't need this... don't want to
internal struct GenericMetadataStruct {
    // first parameter: this
    // second parameter: actual type?
    var get_genericMetaData: UnsafePointer<(@convention(c) (arg1: Int, arg2: Int) -> Int)>
    var item0: Int32
    var item1: Int16
    var item2: Int16
    
    var item3: Int
    var stringOfSomeKid: UnsafePointer<Int8>
    var item4: Int
    var item5: Int
}