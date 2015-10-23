//
//  SwiftSymbolDecoder.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/6/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

public enum SwiftSymbol {
    case Unknown
    // ...g
    case Getter(instanceType: Any.Type, name: String, type: Any.Type)
    // ...s
    case Setter(instanceType: Any.Type, name: String, type: Any.Type)
    // ...m
    case MaterializeForSet(instanceType: Any.Type, name: String, type: Any.Type)
    
    case Method(instanceType: Any.Type, name: String, returnType: Any.Type, parameters: [SwiftParameter])
    // ...c
    case Constructor(instanceType: Any.Type, parameters: [SwiftParameter])
    // ...C
    case AllocatingConstructor(instanceType: Any.Type, parameters: [SwiftParameter])
    // ...d
    case Destructor(instanceType: Any.Type)
    // ...D
    case DeallocatingDestructor(instanceType: Any.Type)
    // ...E
    case IVarDestroyer(instanceType: Any.Type)
}

public struct SwiftParameter {
    public let name: String
    public let type: Any.Type
}

public struct SwiftFunction {
    public let returnType: Any.Type
    public let parameters: [SwiftParameter]
}

public class SwiftSymbolDecoder {
    private static var _swiftBuiltinMap: [Character: String] = {
        var retval: [Character: String] = [
        // namespaces
        "o" : "ObjectiveC",
        "s" : "Swift",
        "C" : "C",
        
        "q" : "Swift.Optional",
        "Q" : "Swift.ImplicitlyUnwrappedOptional",
        "b" : "Swift.Bool",
        "S" : "Swift.String",
        "a" : "Swift.Array",
        "i" : "Swift.Int",
        "u" : "Swift.UInt",
        "f" : "Swift.Float",
        "d" : "Swift.Double",
        "c" : "Swift.UnicodeScalar"
    ]
        
        // if SDK 9.1
            retval["C"] = "__C"
        
        return retval
    }()
    
    private static var _builtinMap: [Character: String] = [
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
    ]
    
    
    public var delegate: SwiftSymbolDecoderDelegate!
    
    private let _scanner : NSScanner
    private var _substitutions = [String]()
    public var genericArguments = [Any.Type]()
    
    public required init(input: String) {
        _scanner = NSScanner(string: input, caseSensitive: true)
        self.delegate = SwiftTypeRegistry.sharedRegistry
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
    
    private func addSubstitution(string: String) {
        _substitutions.append(string)
    }
    
    private func substitution(index: Int) -> String {
        return _substitutions[index]
    }
    
    private func scanSubstitution() -> String? {
        guard let index = scanIndex() else {
            return nil
        }
        return substitution(index)
    }
    
    private func scanGenericSubstitution() -> String {
        precondition(_scanner.scanString("q"))
        
        guard let index = scanIndex() else {
            preconditionFailure()
        }
        
        if index < self.genericArguments.count {
            return self.nameForType(self.genericArguments[index])
        }
        let ch = UnicodeScalar("A").value + UInt32(index)
        return String(UnicodeScalar(ch))
    }
    
    
    public func scanSymbol() -> SwiftSymbol? {
        if !_scanner.scanString("_T") {
            return nil
        }
        
        return scanFunctionDeclaration()
    }
    
    public func scanFunctionDeclaration() -> SwiftSymbol {
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
            return SwiftSymbol.Getter(
                instanceType: self.typeForName(part1),
                name: name,
                type: self.typeForName(type)
            )
            
        case "s":
            _scanner.nextCharacter()
            let name = _scanner.scanSwiftIdentifier()!
            let type = scanType()!
            return SwiftSymbol.Setter(
                instanceType: self.typeForName(part1),
                name: name,
                type: self.typeForName(type)
            )
            
        case "m":
            _scanner.nextCharacter()
            let name = _scanner.scanSwiftIdentifier()!
            let type = scanType()!
            
            return SwiftSymbol.MaterializeForSet(
                instanceType: self.typeForName(part1),
                name: name,
                type: self.typeForName(type)
            )
            
        case "c":
            _scanner.nextCharacter()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            return SwiftSymbol.Constructor(instanceType: self.typeForName(part1),  parameters: F.parameters)
            
        case "C":
            _scanner.nextCharacter()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            return SwiftSymbol.AllocatingConstructor(instanceType: self.typeForName(part1),  parameters: F.parameters)
            
        case "d":
            _scanner.nextCharacter()
            return SwiftSymbol.Destructor(instanceType: self.typeForName(part1))
            
        case "D":
            _scanner.nextCharacter()
            return SwiftSymbol.DeallocatingDestructor(instanceType: self.typeForName(part1))
            
        default:
            let name = _scanner.scanSwiftIdentifier()!
            let constraints = scanGenericConstraints()
            precondition(_scanner.scanString("f"))
            let curried = scanType()!
            let F = scanFunctionType("F")
            
            return SwiftSymbol.Method(
                instanceType: self.typeForName(curried),
                name: name,
                returnType: F.returnType,
                parameters: F.parameters
            )
        }
    }
    
    public func scanType() -> String? {
        guard let ch = _scanner.peekCharacter() else {
            return nil
        }
        
        switch(ch) {
        case "C":
            return scanTypeNameSegment("C")
            
        case "V":
            return scanTypeNameSegment("V")
            
        case "O":
            return scanTypeNameSegment("O")
            
        case "S":
            return scanSwiftTypeName()
            
        case "B":
            return scanBuiltinTypeName()
            
            
        case "T":
            if _scanner.scanString("T_") {
                return "()";
            }
            preconditionFailure()
//            return scanTupleType()*/
            
        case "F":
            preconditionFailure();
//            return scanFunctionType("F")
            
            // auto-closure
        case "K":
            preconditionFailure();
//            return scanFunctionType("K")
            
            // c-style closure
        case "c":
            preconditionFailure();
//            return scanFunctionType("c")
            
            // block
        case "b":
            preconditionFailure();
//            return scanFunctionType("b")
        
            // thin
        case "X":
            preconditionFailure();
//            _scanner.scanString("X")
//            return scanFunctionType("f")
            
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
            return "Swift.UnsafeMutablePointer" + "<" + scanType()! + ">"
        default:
            preconditionFailure()
        }
    }
    
    public func scanTypeName() -> String? {
        guard let ch = _scanner.peekCharacter() else {
            return nil
        }
        
        switch(ch) {
        case "C":
            return scanTypeNameSegment("C")
            
        case "V":
            return scanTypeNameSegment("V")
            
        case "O":
            return scanTypeNameSegment("O")
            
        case "F":
            return scanTypeNameSegment("F")
            
        case "E":
            return scanTypeNameSegment("E")
            
        case "e":
            // generics
            return scanTypeNameSegment("e")
            
        case "S":
            return scanSwiftTypeName()
            
        case "B":
            return scanBuiltinTypeName()
            
        case "P":
            return scanProtocol()
            
        default: return nil
        }
    }
    
    func scanTypeNameSegment(char: String) -> String {
        precondition(_scanner.scanString(char))
        
        let piece1: String
        if let typeName = scanTypeName() {
            piece1 = typeName
        } else {
            piece1 = _scanner.scanSwiftIdentifier()!
            addSubstitution(piece1)
        }
        let piece2 = _scanner.scanSwiftIdentifier()!
        
        let retval = "\(piece1).\(piece2)"
        
        addSubstitution(retval)
        
        return retval
    }
    
    func scanSwiftTypeName() -> String {
        precondition(_scanner.scanString("S"))
        
        if let subs = scanSubstitution() {
            return subs
        }
        
        guard let ch = _scanner.nextCharacter() else {
            preconditionFailure()
        }
        
        
        guard let retval = SwiftSymbolDecoder._swiftBuiltinMap[ch] else {
            preconditionFailure()
        }
        
        return retval
    }
    
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
    
    
    func scanFunctionType(type: String) -> SwiftFunction {
        precondition(_scanner.scanString(type))
        
        var params: [SwiftParameter]
        
        if(_scanner.peekString("T")) {
            params = scanTupleType();
        } else {
            let input = typeForName(scanType()!)
            params = [SwiftParameter(name: "", type: input)]
        }
        let output = typeForName(scanType()!)
        
        return SwiftFunction(returnType: output, parameters: params)
    }
    
    func scanMetaType() -> String {
        precondition(_scanner.scanString("M"))
        
        return scanTypeName()! + ".Type"
    }
    
    func scanTupleType() -> [SwiftParameter] {
        precondition(_scanner.scanString("T"))
        
        var pieces = [SwiftParameter]()
        while !_scanner.scanString("_") {
            let identifier = _scanner.scanSwiftIdentifier() ?? ""
            let type = typeForName(scanType()!)
            pieces.append(SwiftParameter(name: identifier, type: type))
        }
        
        
        return pieces
    }
    
    func scanGenericType() -> String {
        precondition(_scanner.scanString("G"))
        
        let type = scanType()!
        
        var types = [String]()
        while !_scanner.scanString("_") {
            let type = scanType()!
            
            types.append(type)
        }
        
        var retval = "\(type)<"
        var first = true
        for p in types {
            if !first {
                retval += ", "
            } else {
                first = false
            }
            retval += p
        }
        
        retval += ">"
        return retval
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
    
    private func scanProtocol() -> String {
        precondition(_scanner.scanString("P"))
        
        if _scanner.peekString("M") {
            return scanMetaType()
        }
        
        var types = [String]()
        while !_scanner.scanString("_") {
            let typename = scanProtocolName()
            
            types.append(typename)
        }
        
        var retval = "protocol<"
        var first = true
        for p in types {
            if !first {
                retval += ", "
            } else {
                first = false
            }
            retval += p
        }
        
        retval += ">"
        
        if retval == "protocol<Swift.AnyObject>" {
            return "Swift.AnyObject"
        }
        return retval
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
    
    private func scanProtocolName() -> String {
        var retval: String
        if _scanner.peekString("S") {
            retval = scanSwiftTypeName()
        } else {
            retval = _scanner.scanSwiftIdentifier()!
        }
        
        if !retval.containsString(".") {
            retval += "." + _scanner.scanSwiftIdentifier()!
        }
    
        addSubstitution(retval)
        return retval
    }
    
    private func typeForName(name: String) -> Any.Type {
        return self.delegate!.symbolDecoder(self, typeForName: name)
    }
    
    private func nameForType(type: Any.Type) -> String {
        return self.delegate.symbolDecoder(self, nameForType: type)
    }
}


public protocol SwiftSymbolDecoderDelegate {
    func symbolDecoder(decoder: SwiftSymbolDecoder, typeForName name: String) -> Any.Type
    func symbolDecoder(decoder: SwiftSymbolDecoder, nameForType type: Any.Type) -> String
}
