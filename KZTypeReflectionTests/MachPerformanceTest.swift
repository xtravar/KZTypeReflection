//
//  MachPerformanceTest.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/6/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import XCTest
@testable import KZTypeReflection

class MachPerformanceTest: XCTestCase {
    func testPerformance() {
        // This is an example of a performance test case.
        self.measureBlock {
            let scanner = SwiftMachoOSymbolScanner()
            scanner.scanAll()
        }
    }
}