//
//  SwiftSymbolParser.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/22/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

// this entire file was an exercise in futility, probably

public indirect enum SwiftSymbolNode {
    case Tuple([(identifier: String?, type: SwiftSymbolNode)])
    case ByRef(SwiftSymbolNode)
    case ProtocolRef([SwiftSymbolNode])
    case GenericSubstitution(Int)
    case GenericType(baseType: SwiftSymbolNode, arguments: [SwiftSymbolNode])
    
    case Class(SwiftSymbolNode, String)
    case Struct(SwiftSymbolNode, String)
    case Enum(SwiftSymbolNode, String)
    case Extension(SwiftSymbolNode, String)
    case Function(SwiftSymbolNode, String)
    case Module(String)
    case Metatype(SwiftSymbolNode)
    
    case FunctionType(returns: SwiftSymbolNode, arguments: [(identifier: String?, type: SwiftSymbolNode)])
    
    case ProtocolName(module: SwiftSymbolNode, name: String)
    
    case Getter(instanceType: SwiftSymbolNode, name: String, type: SwiftSymbolNode)
    case Setter(instanceType: SwiftSymbolNode, name: String, type: SwiftSymbolNode)
    case MaterializeForSet(instanceType: SwiftSymbolNode, name: String, type: SwiftSymbolNode)
    
    case Init(instanceType: SwiftSymbolNode, arguments: [(identifier: String?, type: SwiftSymbolNode)])
    case AllocatingInit(instanceType: SwiftSymbolNode, arguments: [(identifier: String?, type: SwiftSymbolNode)])
    case Deinit(instanceType: SwiftSymbolNode)
    case DeallocatingDeinit(instanceType: SwiftSymbolNode)
    case Method(instanceType: SwiftSymbolNode, name: String, returns: SwiftSymbolNode, arguments: [(identifier: String?, type: SwiftSymbolNode)])
    
    public static func simpleStruct(module: String, _ name: String) -> SwiftSymbolNode {
        return SwiftSymbolNode.Struct(SwiftSymbolNode.Module(module), name)
    }
    
    public var description: String {
        switch(self) {
        case Class(let node, let identifier):
            return node.description + "." + identifier
            
        case .Struct(let node, let identifier):
            return node.description + "." + identifier
            
        case .Enum(let node, let identifier):
            return node.description + "." + identifier
            
        case .Extension(let node, let identifier):
            return node.description + "." + identifier
            
            
        case .Function(let node, let identifier):
            return node.description + "." + identifier
            
        case .Module(let identifier):
            return identifier
            
        default:
            return "ADGAG"
        }
    }
}

public class SwiftSymbolParser {
    private static var _swiftBuiltinMap: [Character: SwiftSymbolNode] = [
        // namespaces
        "o" : SwiftSymbolNode.Module("ObjectiveC"),
        "s" : SwiftSymbolNode.Module("Swift"),
        "C" : SwiftSymbolNode.Module("C"),
        
        "q" : SwiftSymbolNode.simpleStruct("Swift", "Optional"),
        "Q" : SwiftSymbolNode.simpleStruct("Swift", "ImplicitlyUnwrappedOptional"),
        "b" : SwiftSymbolNode.simpleStruct("Swift", "Bool"),
        "S" : SwiftSymbolNode.simpleStruct("Swift", "String"),
        "a" : SwiftSymbolNode.simpleStruct("Swift", "Array"),
        "i" : SwiftSymbolNode.simpleStruct("Swift", "Int"),
        "u" : SwiftSymbolNode.simpleStruct("Swift", "UInt"),
        "f" : SwiftSymbolNode.simpleStruct("Swift", "Float"),
        "d" : SwiftSymbolNode.simpleStruct("Swift", "Double"),
        "c" : SwiftSymbolNode.simpleStruct("Swift", "UnicodeScalar")
    ]
    
    /*
    private static var _builtinMap: [Character: SwiftSymbolNode] = [
        "b" : "Builtin.BridgeObject",
        "o" : "Builtin.NativeObject",
        "i" : "Builtin.Int",
        "p" : "Builtin.RawPointer",
        "w" : "Builtin.Word",
        "f" : "Builtin.Float"
        
        //UnsafeValueBuffer
        //Vec
        //UnknownObject
        //NativeObject
    ]*/
    
    private let _scanner : NSScanner
    private var _substitutions = [SwiftSymbolNode]()
    
    public required init(input: String) {
        _scanner = NSScanner(string: input, caseSensitive: true)
    }
    
    private func scanIndex() -> Int? {
        if _scanner.scanString("_") {
            return 0
        }
        
        guard let num = _scanner.scanInteger() else {
            return nil
        }
        
        precondition(_scanner.scanString("_"))
        
        return num + 1
    }
    
    private func addSubstitution(string: SwiftSymbolNode) {
        _substitutions.append(string)
    }
    
    private func substitution(index: Int) -> SwiftSymbolNode {
        return _substitutions[index]
    }
    
    private func scanSubstitution() -> SwiftSymbolNode? {
        guard let index = scanIndex() else {
            return nil
        }
        return substitution(index)
    }
    
    private func scanGenericSubstitution() -> SwiftSymbolNode {
        precondition(_scanner.scanString("q"))
        
        guard let index = scanIndex() else {
            preconditionFailure()
        }
        
        return SwiftSymbolNode.GenericSubstitution(index)
    }
    
    
    public func scanSymbol() -> SwiftSymbolNode? {
        if !_scanner.scanString("_T") {
            return nil
        }
        
        return scanFunctionDeclaration()
    }
    
    public func scanFunctionDeclaration() -> SwiftSymbolNode {
        precondition(_scanner.scanString("F"))
        
        let part1 = scanTypeName()!
        
        guard let peekCh = _scanner.peekCharacter() else {
            preconditionFailure()
        }
        
        switch(peekCh) {
        case "g":
            _scanner.nextCharacter()
            let name = _scanner.scanSwiftIdentifier()!
            let type = scanType()!
            return SwiftSymbolNode.Getter(
                instanceType: part1,
                name: name,
                type: type
            )
            
        case "s":
            _scanner.nextCharacter()
            let name = _scanner.scanSwiftIdentifier()!
            let type = scanType()!
            return SwiftSymbolNode.Setter(
                instanceType: part1,
                name: name,
                type: type
            )
            
        case "m":
            _scanner.nextCharacter()
            let name = _scanner.scanSwiftIdentifier()!
            let type = scanType()!
            
            return SwiftSymbolNode.MaterializeForSet(
                instanceType: part1,
                name: name,
                type: type
            )
            
            
        case "c":
            _scanner.nextCharacter()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            guard case .FunctionType(returns: let returns, arguments: let arguments) = F else {
                preconditionFailure()
            }
            return SwiftSymbolNode.Init(instanceType: part1, arguments: arguments)
            
        case "C":
            _scanner.nextCharacter()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            guard case .FunctionType(returns: let returns, arguments: let arguments) = F else {
                preconditionFailure()
            }
            return SwiftSymbolNode.AllocatingInit(instanceType: part1, arguments: arguments)
            
        case "d":
            _scanner.nextCharacter()
            return SwiftSymbolNode.Deinit(instanceType: part1)
            
        case "D":
            _scanner.nextCharacter()
            return SwiftSymbolNode.DeallocatingDeinit(instanceType: part1)
            
        default:
            let name = _scanner.scanSwiftIdentifier()!
            let constraints = scanGenericConstraints()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            guard case .FunctionType(returns: var returns, arguments: var arguments) = F else {
                preconditionFailure()
            }
            return SwiftSymbolNode.Method(
                instanceType: curried,
                name: name,
                returns: returns,
                arguments: arguments
            )
        }
    }
    
    public func scanType() -> SwiftSymbolNode? {
        guard let ch = _scanner.peekCharacter() else {
            return nil
        }
        
        switch(ch) {
        case "C":
            return scanClass()
            
        case "V":
            return scanStruct()
            
        case "O":
            return scanEnum()
            
        case "S":
            return scanSwiftTypeName()
            
        case "B":
            preconditionFailure()
            //return scanBuiltinTypeName()
            
        case "T":
            return scanTupleType()
            
        case "F":
            return scanFunctionType("F")
            
            // auto-closure
        case "K":
            return scanFunctionType("K")
            
            // c-style closure
        case "c":
            return scanFunctionType("c")
            
            // block
        case "b":
            return scanFunctionType("b")
            
            // thin
        case "X":
            _scanner.scanString("X")
            return scanFunctionType("f")
            
        case "M":
            return scanMetaType()
            
        case "G":
            return scanGenericType()
            
        case "q":
            return scanGenericSubstitution()
            
        case "P":
            return scanProtocol()
            
        case "R":
            _scanner.scanString("R")
            return SwiftSymbolNode.ByRef(scanType()!)
        default:
            preconditionFailure()
        }
    }
    
    public func scanTypeName() -> SwiftSymbolNode? {
        guard let ch = _scanner.peekCharacter() else {
            return nil
        }
        
        switch(ch) {
        case "C":
            return scanClass()
            
        case "V":
            return scanStruct()
            
        case "O":
            return scanEnum()
            
        case "F":
            return scanFunctionName()
            
        case "E":
            return scanExtensionName()
            
        case "e":
            // generics
            //return scanTypeNameSegment("e")
            preconditionFailure()
        case "S":
            return scanSwiftTypeName()
            
        case "B":
            preconditionFailure()
            //return scanBuiltinTypeName()
            
        case "P":
            return scanProtocol()
            
        default: return nil
        }
    }
    
    func scanClass() -> SwiftSymbolNode {
        let vars = scanTypeNameSegment("C")
        let retval = SwiftSymbolNode.Class(vars.0, vars.1)
        addSubstitution(retval)
        return retval
    }
    
    
    func scanStruct() -> SwiftSymbolNode {
        let vars = scanTypeNameSegment("V")
        let retval = SwiftSymbolNode.Struct(vars.0, vars.1)
        addSubstitution(retval)
        return retval
    }
    
    func scanEnum() -> SwiftSymbolNode {
        let vars = scanTypeNameSegment("O")
        let retval = SwiftSymbolNode.Enum(vars.0, vars.1)
        addSubstitution(retval)
        return retval
    }
    
    func scanFunctionName() -> SwiftSymbolNode {
        let vars = scanTypeNameSegment("F")
        let retval = SwiftSymbolNode.Function(vars.0, vars.1)
        addSubstitution(retval)
        return retval
    }
    
    func scanExtensionName() -> SwiftSymbolNode {
        let vars = scanTypeNameSegment("E")
        let retval = SwiftSymbolNode.Extension(vars.0, vars.1)
        addSubstitution(retval)
        return retval
    }
    
    func scanModule() -> SwiftSymbolNode {
        let name = _scanner.scanSwiftIdentifier()!
        return SwiftSymbolNode.Module(name)
    }
    
    func scanTypeNameSegment(char: String) -> (SwiftSymbolNode, String) {
        precondition(_scanner.scanString(char))
        
        let piece1: SwiftSymbolNode
        if let typeName = scanTypeName() {
            piece1 = typeName
        } else {
            piece1 = scanModule()
            addSubstitution(piece1)
        }
        let piece2 = _scanner.scanSwiftIdentifier()!
        
        return (piece1, piece2)
    }
    
    func scanSwiftTypeName() -> SwiftSymbolNode {
        precondition(_scanner.scanString("S"))
        
        if let subs = scanSubstitution() {
            return subs
        }
        
        guard let ch = _scanner.nextCharacter() else {
            preconditionFailure()
        }
        
        
        guard let retval = SwiftSymbolParser._swiftBuiltinMap[ch] else {
            preconditionFailure()
        }
        
        return retval
    }
    
    /*
    func scanBuiltinTypeName() -> String {
        precondition(_scanner.scanString("B"))
        
        guard let ch = _scanner.nextCharacter() else {
            preconditionFailure()
        }
        
        
        guard var retval = SwiftSymbolDecoder._builtinMap[ch] else {
            preconditionFailure()
        }
        
        
        if retval == "i" || retval == "f" {
            let bits = _scanner.scanInteger()!
            retval = "\(retval)\(bits)"
        }
        return retval
    }
    */
    
    func scanFunctionType(type: String) -> SwiftSymbolNode {
        precondition(_scanner.scanString(type))
        
        let input = scanType()!
        let output = scanType()!
        
        var args: [(identifier: String?, type: SwiftSymbolNode)]
        
        if case .Tuple(let tupleArgs) = input {
            args = tupleArgs
        } else {
            args = [(identifier: nil, type: input)]
        }
        
        return SwiftSymbolNode.FunctionType(returns: output, arguments: args)
    }
    
    func scanMetaType() -> SwiftSymbolNode {
        precondition(_scanner.scanString("M"))
        return SwiftSymbolNode.Metatype(scanTypeName()!)
    }
    
    func scanTupleType() -> SwiftSymbolNode {
        precondition(_scanner.scanString("T"))
        
        var pieces = [(identifier: String?, type: SwiftSymbolNode)]()
        while !_scanner.scanString("_") {
            let identifier = _scanner.scanSwiftIdentifier()
            let type = scanType()!
            
            pieces.append((identifier: identifier, type: type))
        }
        
        return SwiftSymbolNode.Tuple(pieces)
    }
    
    func scanGenericType() -> SwiftSymbolNode {
        precondition(_scanner.scanString("G"))
        
        let baseType = scanType()!
        
        var args = [SwiftSymbolNode]()
        while !_scanner.scanString("_") {
            let type = scanType()!
            args.append(type)
        }
        
        return SwiftSymbolNode.GenericType(baseType: baseType, arguments: args)
    }
    
    private func scanGenericConstraints() -> String {
        if !_scanner.scanString("u") {
            return ""
        }
        
        if let num = _scanner.scanInteger() {
            precondition(_scanner.scanString("_"))
        }
        
        let ch = _scanner.nextCharacter()!
        if ch == "r" {
            return ""
        }
        
        preconditionFailure()
    }
    
    private func scanProtocol() -> SwiftSymbolNode {
        precondition(_scanner.scanString("P"))
        
        if _scanner.peekString("M") {
            return scanMetaType()
        }
        
        var types = [SwiftSymbolNode]()
        while !_scanner.scanString("_") {
            let typename = scanProtocolName()
            
            types.append(typename)
        }
        
        return SwiftSymbolNode.ProtocolRef(types)
    }
    
    private func scanIdentifiers(limit: Int = 1) -> String {
        var count = 0
        var idents = ""
        while let ident = _scanner.scanSwiftIdentifier() {
            idents += "." + ident
            count++
            if count >= limit {
                break
            }
        }
        return idents
    }
    
    private func scanProtocolName() -> SwiftSymbolNode {
        var module: SwiftSymbolNode
        
        if _scanner.peekString("S") {
            let symbol = scanSwiftTypeName()
            if case .ProtocolName = symbol {
                return symbol
            }
            guard case .Module = symbol else {
                preconditionFailure()
            }
            module = symbol
        } else {
            module = SwiftSymbolNode.Module(_scanner.scanSwiftIdentifier()!)
        }
        
        let retval = SwiftSymbolNode.ProtocolName(module: module, name: _scanner.scanSwiftIdentifier()!)
        
        addSubstitution(retval)
        return retval
    }
}
