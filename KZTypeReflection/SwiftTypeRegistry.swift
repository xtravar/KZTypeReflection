//
//  SwiftTypeRegistry.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/15/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation




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
    
    private init() {
        // no need to have more than one instance
    }
    
    public func typeForName(name: String) -> Any.Type? {
        if let retval = self.registeredTypes[name] {
            return retval
        }
        return NSClassFromString(name)
        //return self.registeredTypes[name]
    }

    public func registerType<T>(type: T.Type, includeRelated: Bool = true) {
        for bt in relatedTypesForType(T.self) {
            let name = SwiftTypeRegistry.typeName(bt)
            registeredTypes[name] = bt
        }
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
}



private func relatedTypesForType<T>(type: T.Type) -> [Any.Type] {
    typealias arrayType = [T]
    typealias arrayTypeq = [T]?
    typealias arrayTypeQ = [T]!
    
    typealias dictType = [String: T]
    typealias dictTypeq = [String: T]?
    typealias dictTypeQ = [String: T]!
    
    typealias qT = T?
    typealias QT = T!
    typealias pT = UnsafeMutablePointer<T>
    typealias mt = T.Type
    
    return [
        T.self,
        arrayType.self,
        arrayTypeq.self,
        arrayTypeQ.self,
        dictType.self,
        dictTypeq.self,
        dictTypeQ.self,
        qT.self,
        QT.self,
        pT.self,
        
        mt.self
    ]
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
        
#if arch(i386) || arch(x86_64)
        registerType(Float80.self)
#endif
        registerType(Bool.self)
        registerType(String.self)
        registerType(Void.self)
    }
}




