//
//  SwiftTypeRegistry.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/15/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation
import KZSwiftBridging

private typealias VoidPointer = UnsafePointer<Void>

public typealias BridgeToConverter = (@convention(block) (inputPointer: UnsafePointer<Void>) -> AnyObject?)
public typealias BridgeFromConverter = (@convention(block) (input: AnyObject?, outputPointer: UnsafeMutablePointer<Void>) -> Void)


public class SwiftTypeRegistry {
    //MARK: singleton
    public static let sharedRegistry: SwiftTypeRegistry = {
        var registry = SwiftTypeRegistry()
        registry.registerBasicTypes()
        registry.registerCGTypes()
        registry.registerUITypes()
        return registry
    }()
    
    
    //MARK: class-level convenience
    public class func typeForName(name: String) -> Any.Type? {
        return SwiftTypeRegistry.sharedRegistry.typeForName(name)
    }
    
    public class func nameForType(type: Any.Type) -> String {
        return SwiftTypeRegistry.sharedRegistry.nameForType(type)
    }
    
    public class func registerType<T>(type: T.Type, includeRelated: Bool = true) {
        SwiftTypeRegistry.sharedRegistry.registerType(type, includeRelated: includeRelated)
    }
    
    public class func registerTypeOpaque(type: Any.Type) {
        SwiftTypeRegistry.sharedRegistry.registerTypeOpaque(type)
    }
    
    //MARK: instance
    private var registeredTypes = [String: Any.Type]()
    private var bridgeToObjectiveCConverters = [VoidPointer: BridgeToConverter]()
    private var bridgeFromObjectiveCConverters = [VoidPointer : BridgeFromConverter]()
    
    private init() {
        // no need to have more than one instance
    }
    
    public func typeForName(name: String) -> Any.Type? {
        if let retval = self.registeredTypes[name] {
            return retval
        }
        var className = name
        
        if name.hasPrefix("Swift.ImplicitlyUnwrappedOptional<") {
            var chars = name.characters
            chars = chars.dropFirst("Swift.ImplicitlyUnwrappedOptional<".characters.count)
            chars = chars.dropLast()
            className = String(chars)
        } else if name.hasPrefix("Swift.Optional<") {
            var chars = name.characters
            chars = chars.dropFirst("Swift.ImplicitlyUnwrappedOptional<".characters.count)
            chars = chars.dropLast()
            className = String(chars)
        }
        
        if className.hasPrefix("ObjectiveC.") {
            className = String(className.characters.dropFirst("ObjectiveC.".characters.count))
        }
        return NSClassFromString(className)
        //return self.registeredTypes[name]
    }

    private func registerTypeInner<T>(type: T.Type) {
        registerTypeOpaque(type)
    }
    

    
    private func registerTypeInner<T : NSValueWrappable>(type: Optional<T>.Type) {
        registerTypeOpaque(type)
        registerBridge(type,
            
            bridgeTo: {
                let value : T? = $0
                return value?.toNSValue()
            
        },
            bridgeFrom: {
                return T?(optionalValue: $0 as! NSValue?)
        })
    }
    
    private func registerTypeInner<T : NSValueWrappable>(type: ImplicitlyUnwrappedOptional<T>.Type) {
        registerTypeOpaque(type)
        registerBridge(type,
            
            bridgeTo: {
                let value : T? = $0
                return value?.toNSValue()
                
            },
            bridgeFrom: {
                return T?(optionalValue: $0 as! NSValue?)
        })
    }
    
    private func registerTypeInner<T: _ObjectiveCBridgeable>(type: T.Type) {
        registerTypeOpaque(type)
        registerBridge(type, bridgeTo: { return $0._bridgeToObjectiveC() as? NSObject },
            bridgeFrom: {
                var retval: T? = nil
                let obj = $0 as! T._ObjectiveCType
                T._forceBridgeFromObjectiveC(obj, result: &retval)
                return retval!
        })
    }
    
    private func registerTypeInner<T: _ObjectiveCBridgeable>(type: Optional<T>.Type) {
        registerTypeOpaque(type)
        registerBridge(type,
            bridgeTo: {
                if case .Some(let value) = $0 {
                    return value._bridgeToObjectiveC() as? NSObject
                }
                return nil
            },
            bridgeFrom: {
                if $0 == nil {
                    return nil
                }
                var retval: T? = nil
                let obj = $0 as! T._ObjectiveCType
                T._forceBridgeFromObjectiveC(obj, result: &retval)
                return retval
        })
    }
    
    public func registerBridge<T, O: NSObject>(type: T.Type, bridgeTo:((T) -> O?), bridgeFrom: ((O?) -> T)) {
        let typePtr = unsafeBitCast(type, UnsafePointer<Void>.self)
        
        bridgeToObjectiveCConverters[typePtr] = {(inputPointer: UnsafePointer<Void>) -> NSObject? in
            let x = bridgeTo(UnsafePointer<T>(inputPointer).memory) as! NSObject
            return x
        }
        
        bridgeFromObjectiveCConverters[typePtr] = {(input: AnyObject?, outputPointer: UnsafeMutablePointer<Void>) in
            let outPtr = UnsafeMutablePointer<T>(outputPointer)
            let x = bridgeFrom(input as? O)
            outPtr.memory = x
        }
    }
    
    
    public func registerType<T>(type: T.Type, includeRelated: Bool = true) {
        registerTypeInner(type)
        if !includeRelated {
            return
        }
        
        typealias arrayType = [T]
        registerTypeInner(arrayType)
        
        typealias arrayTypeq = [T]?
        registerTypeInner(arrayTypeq)
        
        typealias arrayTypeQ = [T]!
        registerTypeInner(arrayTypeQ)
        
        typealias dictType = [String: T]
        registerTypeInner(dictType)
        
        typealias dictTypeq = [String: T]?
        registerTypeInner(dictTypeq)
        
        typealias dictTypeQ = [String: T]!
        registerTypeInner(dictTypeQ)
        
        typealias qT = T?
        registerTypeInner(qT)
        
        typealias QT = T!
        registerTypeInner(QT)
        
        typealias pT = UnsafeMutablePointer<T>
        registerTypeInner(pT)
        
        typealias mt = T.Type
        registerTypeInner(mt)
    }
    
    public func registerType<T: Hashable>(type: T.Type, includeRelated: Bool = true) {
        registerTypeInner(type)
        if !includeRelated {
            return
        }
        
        typealias arrayType = [T]
        registerTypeInner(arrayType)
        
        typealias arrayTypeq = [T]?
        registerTypeInner(arrayTypeq)
        
        typealias arrayTypeQ = [T]!
        registerTypeInner(arrayTypeQ)
        
        typealias setType = Set<T>
        registerTypeInner(setType)
        
        typealias setTypeq = Set<T>?
        registerTypeInner(setTypeq)
        
        typealias setTypeQ = Set<T>!
        registerTypeInner(setTypeQ)
        
        typealias dictType = [String: T]
        registerTypeInner(dictType)
        
        typealias dictTypeq = [String: T]?
        registerTypeInner(dictTypeq)
        
        typealias dictTypeQ = [String: T]!
        registerTypeInner(dictTypeQ)
        
        typealias qT = T?
        registerTypeInner(qT)
        
        typealias QT = T!
        registerTypeInner(QT)
        
        typealias pT = UnsafeMutablePointer<T>
        registerTypeInner(pT)
        
        typealias mt = T.Type
        registerTypeInner(mt)
    }
    
    public func registerTypeOpaque(type: Any.Type) {
        registeredTypes[SwiftTypeRegistry.typeName(type)] = type
    }
    
    // uses obfuscated API, but should be OK.  If not, we can always reverse-lookup later.
    public func nameForType(type: Any.Type) -> String {
        return SwiftTypeRegistry.typeName(type, qualified: true)
    }
    
    
    //MARK: dicey hackery
    
    // we COULD use this directly... however, _stdlib is defined (hidden) in the library
    // eg @asmname("_TFSs9_typeNameFTPMP_9qualifiedSb_SS")
    // given that the name changed in beta, probably not a good idea
    private static func typeName(type: Any.Type, qualified: Bool = true) -> String {
        var retval = String()
        _stdlib_getDemangledMetatypeNameImpl(type, qualified: qualified, &retval)
        return retval
    }
    
    public func bridgeToObjectiveC(type: Any.Type, inputPointer: UnsafePointer<Void>) -> AnyObject? {
        let typePtr = unsafeBitCast(type, UnsafePointer<Void>.self)
        let converter = self.bridgeToObjectiveCConverters[typePtr]!
        let converted = converter(inputPointer: inputPointer)
        return converted
    }
    
    public func bridgeFromObjectiveC(type: Any.Type, input: AnyObject?, outputPointer: UnsafeMutablePointer<Void>) {
        let typePtr = unsafeBitCast(type, UnsafePointer<Void>.self)
        let converter = self.bridgeFromObjectiveCConverters[typePtr]!
        converter(input: input, outputPointer: outputPointer)
    }
}



public extension SwiftTypeRegistry {
    public func registerCGTypes() {
        registerType(CGPoint.self)
        registerType(CGPoint.self)
        registerType(CGPoint.self)
        registerType(CGSize.self)
        registerType(CGRect.self)
        registerType(CGAffineTransform.self)
    }
    
    public func registerUITypes() {
        registerType(UIEdgeInsets.self)
        registerType(UIOffset.self)
    }
    
    public func registerBasicTypes() {
        registerType(AnyObject.self)
        registerType(AnyClass.self)
        registerType(Selector.self)
        
        registerType(Int8.self)
        registerType(UInt8.self)
        registerType(Int16.self)
        registerType(UInt16.self)
        registerType(Int32.self)
        registerType(UInt32.self)
        registerType(Int64.self)
        registerType(UInt64.self)
        registerType(Int.self)
        registerType(UInt.self)
        registerType(Float.self)
        registerType(Double.self)
        registerType(NSDecimal.self)
        
#if arch(i386) || arch(x86_64)
        registerType(Float80.self)
#endif
        registerType(Bool.self)
        registerType(String.self)
        registerType(Void.self)
    }
}

