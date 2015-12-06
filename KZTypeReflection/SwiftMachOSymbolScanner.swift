//
//  SwiftSymbolScanner.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/5/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import MachO

public class SwiftMachoOSymbolScanner {
    private var symbolTable = [String: UnsafePointer<Void>]()
    
    public init() {
    }
    
    public func scanAll() {
        for i in 0 ..< _dyld_image_count() {
            
            let nameptr = _dyld_get_image_name(i)
            let imagename = String.fromCString(nameptr)!
            
            // memory protection blah blah blah
            if imagename.hasPrefix("/System/") || imagename.hasPrefix("/usr/"){
                continue
            }

            let imageHeader = _dyld_get_image_header(i)
            let offset = _dyld_get_image_vmaddr_slide(i)
            let module = MachOSymbolTable(baseAddress: imageHeader, vmOffset: offset)
            module.forEachSymbol {
                if $0.hasPrefix("__T") {
                    self.symbolTable[$0] = $1 + offset
                }
            }
            
        }
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
    
    
}