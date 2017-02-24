//
//  XMLSimpleTest.swift
//  XMLDictionary
//
//  Created by Volker Bublitz on 23/02/2017.
//
//

import XCTest

class XMLSimpleTest: XCTestCase {

    var bundle:Bundle?
    
    override func setUp() {
        super.setUp()
        self.bundle = Bundle(for: XMLSimpleTest.self)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func parse(url: URL) {
        if let xmlString = try? String(contentsOf: url, encoding: .utf8) {
            NSLog("string: %@", [xmlString])
            let xmlDictionary = XMLDictionary.dictionaryWithXMLString(xmlString: xmlString)
            NSLog("dictionary: %@", [xmlDictionary])
        }
    }
    
    func testExample() {
        if let path = bundle?.path(forResource: "example", ofType: "xml") {
            let url =  URL(fileURLWithPath: path)
            self.parse(url: url)
        }

        if let url2 = URL(string: "http://www.ibiblio.org/xml/examples/shakespeare/all_well.xml") {
            self.parse(url: url2)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
