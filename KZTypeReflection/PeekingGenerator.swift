//
//  PeekingGenerator.swift
//  KZObjCRuntime
//
//  Created by Mike Kasianowicz on 7/29/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

struct PeekingGenerator<T : GeneratorType> : GeneratorType {
    internal typealias Element = T.Element
    
    
    private var peekElement : Element?
    private var generator : T
    
    internal init(generator: T) {
        self.generator = generator
        self.peekElement = self.generator.next()
    }
    
    mutating internal func next() -> Element? {
        let retval = self.peekElement
        self.peekElement = self.generator.next()
        return retval
    }
    
    internal func peek() -> Element? {
        return peekElement
    }
}
