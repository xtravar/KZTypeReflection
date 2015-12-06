//
//  ObjCTypeDecoder.swift
//
//  Created by Mike Kasianowicz on 7/26/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import ObjectiveC

internal typealias CharGenerator = PeekingGenerator<String.CharacterView.Generator>

public class ObjCTypeDecoder {
    public static let sharedDecoder = ObjCTypeDecoder()
    
    //MARK: special types
    
    // used in place of a named struct that cannot be looked up or constructed
    public struct UnrecognizedStruct {}

    // used in place of an unrecognized anonymous struct
    public struct UnrecognizedAnonymousStruct {}

    // used in place of a pointer type that cannot be looked up or constructed
    public struct UnrecognizedPointer {}

    
    //MARK: init, variables
    public var delegate: ObjCTypeDecoderDelegate? = nil
    
    public required init() {
        self.delegate = SwiftTypeRegistry.sharedRegistry
    }

    //MARK: public interface
    public func typeFromString(string: String) -> Any.Type? {
        if string == "{?=b8b4b1b1b18[8S]}" {
            return NSDecimal.self
        }
        var generator = PeekingGenerator(generator: string.characters.generate())
        return typeFromCharacters(&generator)
    }

    public func typeFromCString(CString: UnsafePointer<Int8>) -> Any.Type? {
        return typeFromString(String.fromCString(CString)!)
    }


    internal func typeFromCharacters(inout generator: PeekingGenerator<String.CharacterView.Generator>) -> Any.Type? {
        guard let ch = generator.peek() else {
            return nil
        }
        
        guard let typeChar = ObjCTypeChar(rawValue: ch) else {
            preconditionFailure("unrecognized type character")
        }
        
        switch(typeChar) {
        case .ID:
            generator.next()
            return decodeClass(&generator)
        case .STRUCT_B:
            generator.next()
            return decodeStruct(&generator)
        case .PTR:
            generator.next()
            return decodePointer(&generator)
        case .ARY_B:
            generator.next()
            return decodeArray(&generator)
            
        case .STRUCT_E:
            return nil
            
        case .ARY_E:
            return nil
            
        default:
            generator.next()
            return typeChar.toSwiftType()
        }
    }

    //MARK: internal workings
    private func decodeClass(inout generator: CharGenerator) -> Any.Type? {
        guard let nextChar = generator.next() else {
            return AnyObject.self
        }
        
        if nextChar == "?" {
            return AnyObject.self
        }

        precondition(nextChar == "\"",  "Unsupported class encoding")

        var protocols = [Protocol]()

        var className = ""
        while let ch = generator.next() {
            if ch == "\"" {
                break
            }

            if ch == "<" {
                if let newProto = decodeProtocol(&generator) {
                    protocols.append(newProto)
                }
                continue
            }

            className.append(ch)
        }


        // if we are type 'id' we can attempt to use protocols, if possible
        if className == "" {
            if !protocols.isEmpty {
                return self.compositeProtocolWithProtocols(protocols)
            }
            return AnyObject.self
        }

        return NSClassFromString(className)!
    }

    private func decodeProtocol(inout generator: CharGenerator) -> Protocol? {
        var name = ""
        while let ch = generator.next() {
            if ch == ">" {
                break
            }

            name.append(ch)
        }

        return NSProtocolFromString(name)
    }

    private func decodeStruct(inout generator: CharGenerator) -> Any.Type? {
        var name = ""
        var fieldTypes = [Any.Type]()
        while let ch = generator.next() {
            if ch == "}" {
                break
            }

            if ch == "=" {
                while let fieldType = self.typeFromCharacters(&generator) {
                    fieldTypes.append(fieldType)
                }
                continue
            }

            name.append(ch)
        }

        if name == "?" {
            return self.structFromFieldTypes(fieldTypes)
        }

        return self.structFromName(name)
    }

    private func decodePointer(inout generator: CharGenerator) -> Any.Type? {
        guard let pointedType = self.typeFromCharacters(&generator) else {
            preconditionFailure("expected type for pointer")
        }
        return self.pointerToType(pointedType)
    }

    private func decodeArray(inout generator: CharGenerator) -> Any.Type? {
        preconditionFailure("'solid' arrays not supported in Swift")
    }

    func structFromName(name: String) -> Any.Type {
        if let type = delegate?.typeDecoder(self, typeForStructName: name) {
            return type
        }

        return UnrecognizedStruct.self
    }

    func structFromFieldTypes(types: [Any.Type]) -> Any.Type {
        if let type = delegate?.typeDecoder(self, typeForAnonymousStructWithFields: types) {
            return type
        }

        return UnrecognizedAnonymousStruct.self
    }

    func compositeProtocolWithProtocols(protocols: [Protocol]) -> Any.Type {
        if let type = delegate?.typeDecoder(self, compositeProtocolWithProtocols: protocols) {
            return type
        }

        return AnyObject.self
    }

    func pointerToType(type: Any.Type) -> Any.Type {
        if let type = delegate?.typeDecoder(self, pointerToType: type) {
            return type
        }

        return UnrecognizedPointer.self
    }
}

public protocol ObjCTypeDecoderDelegate {
    func typeDecoder(decoder: ObjCTypeDecoder, typeForStructName structName: String) -> Any.Type?
    func typeDecoder(decoder: ObjCTypeDecoder, typeForAnonymousStructWithFields fields: [Any.Type]) -> Any.Type?
    func typeDecoder(decoder: ObjCTypeDecoder, compositeProtocolWithProtocols: [Protocol]) -> Any.Type?
    func typeDecoder(decoder: ObjCTypeDecoder, pointerToType type: Any.Type) -> Any.Type?
}






