//
//  KZTypeReflectionTests.swift
//  KZTypeReflectionTests
//
//  Created by Mike Kasianowicz on 7/31/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import XCTest
@testable import KZTypeReflection

class KZTypeReflectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEncodeCGPoint() {
        let string = ObjCTypeEncoder.sharedEncoder.encode(CGPoint.self)
        XCTAssert(string == "{CGPoint=dd}")
    }
    
    func testEncodingCGRect() {
        let string = ObjCTypeEncoder.sharedEncoder.encode(CGRect.self)
        XCTAssert(string == "{CGRect={CGPoint=dd}{CGSize=dd}}")
    }
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
