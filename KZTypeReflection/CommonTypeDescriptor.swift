//
//  CommonTypeDescriptor.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public class CommonTypeDescriptor {
    struct InstanceStructure {
        // function pointers?  looks like to swift std funcs
        var unknown00: COpaquePointer
        var unknown01: COpaquePointer
        var unknown02: COpaquePointer
        var unknown03: COpaquePointer
        var unknown04: COpaquePointer
        var unknown05: COpaquePointer
        var unknown06: COpaquePointer
        var unknown07: COpaquePointer
        var unknown08: COpaquePointer
        var unknown09: COpaquePointer
        var unknown10: COpaquePointer
        var unknown11: COpaquePointer
        var unknown12: COpaquePointer
        var unknown13: COpaquePointer
        var unknown14: COpaquePointer
        var unknown15: COpaquePointer
        var unknown16: COpaquePointer
        
        // data
        var sizeOf: Int
        var alignOf: Int
        var strideOf: Int
        
        //for-sure end
    }
    
    
    let pointer: UnsafePointer<InstanceStructure>
    
    init(typePointer: UnsafePointer<Void>) {
        self.pointer = UnsafePointer<UnsafePointer<InstanceStructure>>(typePointer - 8).memory
    }
    
    
    public var size: Int {
        return self.pointer.memory.sizeOf
    }
    
    public var alignment: Int {
        return self.pointer.memory.alignOf & 0xffff + 1
    }
    
    public var stride: Int {
        var strideOf = self.pointer.memory.strideOf
        
        if strideOf == 0 {
            strideOf = 1
        }
        
        return strideOf
    }
    
    
}