//
//  SwiftTypeRegistry_DefaultLookups.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/20/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

extension SwiftTypeRegistry : ObjCTypeDecoderDelegate {
    //MARK: default type resolution
    public func typeDecoder(decoder: ObjCTypeDecoder, typeForStructName structName: String) -> Any.Type? {
        // 9.1 +
        if let type = self.typeForName("__C." + structName) {
            return type
        }
        return self.typeForName("C." + structName)
    }
    
    public func typeDecoder(decoder: ObjCTypeDecoder, typeForAnonymousStructWithFields fields: [Any.Type]) -> Any.Type? {
        return nil
    }
    
    public func typeDecoder(decoder: ObjCTypeDecoder, compositeProtocolWithProtocols protocols: [Protocol]) -> Any.Type? {
        let protocolNames = protocols.map{ NSStringFromProtocol($0)}.joinWithSeparator(", ")
        return self.typeForName("protocol<\(protocolNames)>" )
    }
    
    public func typeDecoder(decoder: ObjCTypeDecoder, pointerToType type: Any.Type) -> Any.Type? {
        let name = SwiftTypeRegistry.nameForType(type)
        return self.typeForName("Swift.UnsafeMutablePointer<\(name)>")
    }
}

extension SwiftTypeRegistry : SwiftSymbolDecoderDelegate {
    public func symbolDecoder(decoder: SwiftSymbolDecoder, typeForName name: String) -> Any.Type {
        if let retval = self.typeForName(name) {
            return retval
        }
        
        //TODO: use dyld hackery
        // _dyld_get_image_count 
        preconditionFailure("must manually register type for name: \(name)")
    }
    
    public func symbolDecoder(decoder: SwiftSymbolDecoder, nameForType type: Any.Type) -> String {
        return self.nameForType(type)
    }
}