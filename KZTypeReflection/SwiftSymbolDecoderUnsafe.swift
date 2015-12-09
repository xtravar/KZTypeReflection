//
//  SwiftSymbolDecoder.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/6/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

public class SwiftSymbolDecoderUnsafe {
    private static var swiftBuiltinMap: [Character: String] = {
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
    
    private static var builtinMap: [Character: String] = [
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

    
    private let stringScanner : NSScanner
    private var substitutions = [String]()
    public var genericArguments = [Any.Type]()
    
    public required init(input: String) {
        stringScanner = NSScanner(string: input, caseSensitive: true)
    }
    
    private func scanIndex() -> Int? {
        if stringScanner.scanString("_") {
            return 0
        }
        
        guard let num = stringScanner.scanInteger() else {
            return nil
        }
        
        precondition(stringScanner.scanString("_"))
        
        return num + 1
    }
    
    private func addSubstitution(string: String) {
        substitutions.append(string)
    }
    
    private func substitution(index: Int) -> String {
        return substitutions[index]
    }
    
    private func scanSubstitution() -> String? {
        guard let index = scanIndex() else {
            return nil
        }
        return substitution(index)
    }
    
    private func scanGenericSubstitution() -> String {
        precondition(stringScanner.scanString("q"))
        
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
        if !stringScanner.scanString("_T") {
            return nil
        }
        
        return scanFunctionDeclaration()
    }
    
    public func scanFunctionDeclaration() -> SwiftSymbol {
        precondition(stringScanner.scanString("F"))
        
        let type1 = self.typeForName(scanTypeName()!)
        
        
        guard let peekCh = stringScanner.peekCharacter() else {
            preconditionFailure()
        }
        
        switch(peekCh) {
        case "g":
            stringScanner.nextCharacter()
            let name = stringScanner.scanSwiftIdentifier()!
            let type2 = self.typeForName(scanType()!)
            
            return SwiftSymbol.Getter(
                instanceType: type1,
                name: name,
                type: type2
            )
            
            
        case "s":
            stringScanner.nextCharacter()
            let name = stringScanner.scanSwiftIdentifier()!
            let type = scanType()!
            return SwiftSymbol.Setter(
                instanceType: type1,
                name: name,
                type: self.typeForName(type)
            )
            
        case "m":
            stringScanner.nextCharacter()
            let name = stringScanner.scanSwiftIdentifier()!
            let type = scanType()!
            
            return SwiftSymbol.MaterializeForSet(
                instanceType: type1,
                name: name,
                type: self.typeForName(type)
            )
            
        case "c":
            stringScanner.nextCharacter()
            precondition(stringScanner.scanString("f"))
            let _ = scanType()!
            let F = scanFunctionType("F")
            return SwiftSymbol.Constructor(instanceType: type1,  parameters: F.parameters)
            
        case "C":
            stringScanner.nextCharacter()
            precondition(stringScanner.scanString("f"))
            let _ = scanType()!
            let F = scanFunctionType("F")
            return SwiftSymbol.AllocatingConstructor(instanceType: type1,  parameters: F.parameters)
            
        case "d":
            stringScanner.nextCharacter()
            return SwiftSymbol.Destructor(instanceType: type1)
            
        case "D":
            stringScanner.nextCharacter()
            return SwiftSymbol.DeallocatingDestructor(instanceType: type1)
            
        default:
            let name = stringScanner.scanSwiftIdentifier()!
            let _ = scanGenericConstraints()
            precondition(stringScanner.scanString("f"))
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
    
    private func scanMangledTypeName() -> String? {
        let start = stringScanner.scanLocation
        
        let _ = self.scanType()
        
        let end = stringScanner.scanLocation
        
        let chars = stringScanner.string.characters
        let mangledName = String(chars.dropFirst(start).dropLast(chars.count - end))
        
        
        
        return mangledName
    }
    
    
    
    
    public func scanType() -> String? {
        guard let ch = stringScanner.peekCharacter() else {
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
            if stringScanner.scanString("T_") {
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
            stringScanner.scanString("R")
            return "Swift.UnsafeMutablePointer" + "<" + scanType()! + ">"
        default:
            preconditionFailure()
        }
    }
    
    public func scanTypeName() -> String? {
        guard let ch = stringScanner.peekCharacter() else {
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
        precondition(stringScanner.scanString(char))
        
        let piece1: String
        if let typeName = scanTypeName() {
            piece1 = typeName
        } else {
            piece1 = stringScanner.scanSwiftIdentifierMangled()!
            addSubstitution(piece1)
        }
        let piece2 = stringScanner.scanSwiftIdentifierMangled()!
        
        let retval = char + "\(piece1)\(piece2)"
        
        addSubstitution(retval)
        
        return retval
    }
    
    func scanSwiftTypeName() -> String {
        precondition(stringScanner.scanString("S"))
        
        if let subs = scanSubstitution() {
            return subs
        }
        
        guard let ch = stringScanner.nextCharacter() else {
            preconditionFailure()
        }
        
        
        guard let _ = SwiftSymbolDecoderUnsafe.swiftBuiltinMap[ch] else {
            preconditionFailure()
        }
        
        return "S" + String(ch)
    }
    
    func scanBuiltinTypeName() -> String {
        precondition(stringScanner.scanString("B"))
        
        guard let ch = stringScanner.nextCharacter() else {
            preconditionFailure()
        }
        
        
        guard var retval = SwiftSymbolDecoderUnsafe.builtinMap[ch] else {
            preconditionFailure()
        }
        
        
        if retval == "i" || retval == "f" {
            let bits = stringScanner.scanInteger()!
            retval = "\(retval)\(bits)"
        }
        
        return retval
    }
    
    
    func scanFunctionType(type: String) -> SwiftFunction {
        precondition(stringScanner.scanString(type))
        
        var params: [SwiftParameter]
        
        if(stringScanner.peekString("T")) {
            params = scanTupleType();
        } else {
            let input = typeForName(scanType()!)
            params = [SwiftParameter(name: "", type: input)]
        }
        let output = typeForName(scanType()!)
        
        return SwiftFunction(returnType: output, parameters: params)
    }
    
    func scanMetaType() -> String {
        precondition(stringScanner.scanString("M"))
        
        return scanTypeName()! + ".Type"
    }
    
    func scanTupleType() -> [SwiftParameter] {
        precondition(stringScanner.scanString("T"))
        
        var pieces = [SwiftParameter]()
        while !stringScanner.scanString("_") {
            let identifier = stringScanner.scanSwiftIdentifierMangled() ?? ""
            let type = typeForName(scanType()!)
            pieces.append(SwiftParameter(name: identifier, type: type))
        }
        
        
        return pieces
    }
    
    func scanGenericType() -> String {
        precondition(stringScanner.scanString("G"))
        
        let type = scanType()!
        
        var types = [String]()
        while !stringScanner.scanString("_") {
            let type = scanType()!
            
            types.append(type)
        }
        
        var retval = "G\(type)"
        for p in types {
            retval += p
        }
        
        retval += "_"
        return retval
    }
    
    private func scanGenericConstraints() -> String {
        if !stringScanner.scanString("u") {
            return ""
        }
        
        if let _ = stringScanner.scanInteger() {
            precondition(stringScanner.scanString("_"))
        }
        
        let ch = stringScanner.nextCharacter()!
        if ch == "r" {
            return ""
        }
        
        preconditionFailure()
    }
    
    private func scanProtocol() -> String {
        precondition(stringScanner.scanString("P"))
        
        if stringScanner.peekString("M") {
            return scanMetaType()
        }
        
        var types = [String]()
        while !stringScanner.scanString("_") {
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
    
    private func scanProtocolName() -> String {
        var retval: String
        if stringScanner.peekString("S") {
            retval = scanSwiftTypeName()
        } else {
            retval = stringScanner.scanSwiftIdentifier()!
        }
        
        if !retval.containsString(".") {
            retval += "." + stringScanner.scanSwiftIdentifier()!
        }
        
        addSubstitution(retval)
        return retval
    }
    
    private func typeForName(name: String) -> Any.Type {
        guard let retval = SwiftMachoOSymbolScanner.sharedScanner.findTypeMetadata(name) else {
            preconditionFailure("could not find metadata for type \(name)")
        }
        
        return retval
    }
    
    private func nameForType(type: Any.Type) -> String {
        return ""
    }
}
