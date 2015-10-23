//
//  ObjCMethod.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/19/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

public struct ObjCMethod {
    let selector: Selector
    let returnType: Any.Type
    let argumentTypes: [Any.Type]
    
    public init(pointer: Method) {
        self.selector = method_getName(pointer)
        self.returnType = {
            let value = method_copyReturnType(pointer)
            let encodeStr = String.fromCString(value)!
            let retval = ObjCTypeDecoder.sharedDecoder.typeFromString(encodeStr)!
            free(value)
            return retval
        }()
        
        self.argumentTypes = {
            var retval = [Any.Type]()
            
            for i in 0 ..< method_getNumberOfArguments(pointer) {
                let argTypeEncodingC = method_copyArgumentType(pointer, i)
                let encodeStr = String.fromCString(argTypeEncodingC)!
                let argType = ObjCTypeDecoder.sharedDecoder.typeFromString(encodeStr)!
                free(argTypeEncodingC)
                retval.append(argType)
            }
            if retval.count >= 2 {
                if retval[0] == AnyObject.self && retval[1] == Selector.self {
                    retval.removeFirst(2)
                }
            }
            
            return retval
        }()
    }
    
    /*
    private let pointer: Method
    
    public init(pointer: Method) {
        self.pointer = pointer
    }
    
    public var selector: Selector {
        return method_getName(self.pointer);
    }
    
    public var name: String {
        return NSStringFromSelector(self.selector)
    }
    
    public var returnType: Any.Type {
        let value = method_copyReturnType(self.pointer)
        let retval = ObjCTypeDecoder.sharedDecoder.typeFromCString(value)!
        free(value)
        return retval
    }
    
    public var argumentTypes: [Any.Type] {
        var retval = [Any.Type]()
        
        for i in 0 ..< method_getNumberOfArguments(self.pointer) {
            let argTypeEncodingC = method_copyArgumentType(self.pointer, i)
            let argType = ObjCTypeDecoder.sharedDecoder.typeFromCString(argTypeEncodingC)!
            free(argTypeEncodingC)
            retval.append(argType)
        }
        return retval
    }
*/
}


internal class ObjCMethodList : ObjCRuntimeAllocatedList<AnyClass!, Method> {
    internal init(type: AnyClass) {
        super.init(parent: type, allocator: class_copyMethodList)
    }
}