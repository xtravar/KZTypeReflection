//
//  SwiftSymbolScanner.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/5/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import MachO

public class SwiftMachoOSymbolScanner {
    public static let sharedScanner = SwiftMachoOSymbolScanner()
    
    private var symbolTable = [String: UnsafePointer<Void>]()
    
    public init() {
        scanAll()
    }
    
    private func scanAll() {
        var modules = [MachOSymbolTable]()
        
        for i in 0 ..< _dyld_image_count() {
            
            let nameptr = _dyld_get_image_name(i)
            let imagename = String.fromCString(nameptr)!
            
            // memory protection blah blah blah
            if imagename.hasPrefix("/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk") {
                continue
            }
            if imagename.hasPrefix("/System/") || imagename.hasPrefix("/usr/"){
                continue
            }
            
            let handle = dlopen(imagename, RTLD_NOW)
            defer { dlclose(handle) }

            let imageHeader = _dyld_get_image_header(i)
            let offset = _dyld_get_image_vmaddr_slide(i)
            let module = MachOSymbolTable(baseAddress: imageHeader, offset: offset)
            module.onlySwiftSymbols = true
            module.onlySwiftMetadataSymbols = true
            //print(imagename)
            module.load()
            module.forEachSymbol {
                self.symbolTable[String($0.characters.dropFirst())] = $1
            }
            modules.append(module)
        }
        
        for module in modules {
            module.forEachIndirectSymbol {
                let name = String($0.characters.dropFirst())
                if let _ = self.symbolTable[name] {
                    return
                }
                
                self.symbolTable[name] = $1
            }
        }
    }
    
    public func nameForAddress(address: UnsafePointer<Void>) -> String? {
        for (k, v) in self.symbolTable {
            if v == address {
                return k
            }
        }
        return nil
    }
    
    public func addressOf(name: String) -> UnsafePointer<Void>? {
        return self.symbolTable[name]
    }
    
    public func addressOf<T>(name: String, type: T.Type) -> T? {
        if let address = addressOf(name) {
            return unsafeBitCast(address, T.self)
        }
        return nil
    }
    
    public func dynamicLookup(name: String) -> UnsafePointer<Void>? {
        for i in 0 ..< _dyld_image_count() {
            
            let nameptr = _dyld_get_image_name(i)
            let imagename = String.fromCString(nameptr)!
            
            let dlhandle = dlopen(imagename, RTLD_LAZY)
            let addr = dlsym(dlhandle, name)
            //print(imagename)
            if addr != nil {
                return UnsafePointer<Void>(addr)
            }
        }
        return nil
    }
    
    public func dynamicLookup<T>(name: String, type: T.Type) -> T? {
        if let address = dynamicLookup(name) {
            return unsafeBitCast(address, T.self)
        }
        return nil
    }
    
    var cachedMetadata = [String: UnsafePointer<Void>]()
    
    public func findTypeMetadata(mangledName: String) -> Any.Type? {
        if let metadata = cachedMetadata[mangledName] {
            return unsafeBitCast(metadata, Any.Type.self)
        }
        
        if let metadata = internalFindTypeMetadata(mangledName) {
            cachedMetadata[mangledName] = metadata
            return unsafeBitCast(metadata, Any.Type.self)
        }
        
        return nil
    }
    
    private func internalFindTypeMetadata(mangledName: String) -> UnsafePointer<Void>? {
        typealias MetadataFunc = (@convention(c) () -> UnsafePointer<Void>)
        
        if let mfunc = self.addressOf("_TMa\(mangledName)", type: MetadataFunc.self) {
            return mfunc()
        }
        
        if let direct = self.addressOf("_TMd\(mangledName)", type: UnsafePointer<Void>.self) {
            return direct
        }
        
        if let direct = self.dynamicLookup("_TMd\(mangledName)") {
            return direct
        }
        return nil
    }
    
}