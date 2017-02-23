//
//  XMLSimpleTest.swift
//  XMLDictionary
//
//  Created by Volker Bublitz on 23/02/2017.
//
//

import XCTest

class XMLSimpleTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        if let url = URL(string: "http://www.ibiblio.org/xml/examples/shakespeare/all_well.xml"),
            let xmlString = try? String(contentsOf: url, encoding: .utf8) {
            
            NSLog("string: %@", [xmlString])
            let xmlDictionary = XMLDictionary.dictionaryWithXMLString(xmlString: xmlString)
            NSLog("dictionary: %@", [xmlDictionary])
            
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
