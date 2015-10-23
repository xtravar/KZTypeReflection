//
//  NSScanner_Convenience.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 9/7/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation

extension NSScanner {
    convenience init(string: String, caseSensitive: Bool) {
        self.init(string: string)
        self.caseSensitive = caseSensitive
    }
    
    func peekCharacter() -> Character? {
        if(self.atEnd) {
            return nil
        }
        
        let index = self.string.startIndex.advancedBy(self.scanLocation)
        return self.string[index]
    }
    
    func nextCharacter() -> Character? {
        let retval = self.peekCharacter()
        self.scanLocation++
        return retval
    }
    
    func scanInteger() -> Int? {
        var result: Int = 0
        return self.scanInteger(&result) ? result : nil
    }
    
    func scanCharactersFromSet(charset: NSCharacterSet) -> String? {
        var result: NSString?
        return self.scanCharactersFromSet(charset, intoString: &result) ? (result as? String) : nil
    }
    
    func peekString(string: String) -> Bool {
        let location = self.scanLocation
        let retval = scanString(string)
        self.scanLocation = location
        return retval
    }
    
    func scanString(string: String) -> Bool {
        var result: NSString?
        return self.scanString(string, intoString: &result)
    }
    
    func scanStringOfLength(length: Int) -> String? {
        if self.string.startIndex.advancedBy(self.scanLocation + length) > self.string.endIndex {
            return nil
        }
        var str = ""
        for _ in 0 ..< length {
            guard let ch = nextCharacter() else {
                return str
            }
            str.append(ch)
        }
        return str
    }
    
    func remainderString() -> String {
        let index = self.string.startIndex.advancedBy(self.scanLocation)
        return self.string.substringFromIndex(index)
    }
}