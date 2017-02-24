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
            guard let xmlDictionary = XMLDictionary.dictionaryWithXMLFile(xmlFilePath: path) else {
                XCTAssert(false, "parsing error")
                return
            }
            NSLog("dictionary: %@", [xmlDictionary])
            
            let value = xmlDictionary.value(forKeyPath: "book.0._id")
            guard let v = value as? String else {
                XCTAssert(false, "book not found")
                return
            }
            XCTAssert(v == "bk101", "book not found")
            
            if let bookNode = xmlDictionary.value(forKeyPath: "book.1") as? [String : Any] {
                let idAttribute = attrs.attributeForKey(key: "id")
                XCTAssert(idAttribute == "bk102", "book id attribute not found")
            }
            
            let dict = xmlDictionary.dictionaryValue(forKeyPath: "book")
            XCTAssert((dict!["_id"] as! String) == "bk101", "book not found")
            
            let array = xmlDictionary.arrayValue(forKeyPath: "book")
            XCTAssert(((array![1] as! [String : Any])["_id"] as! String) == "bk102", "book 2 not found")
            
            let str = xmlDictionary.stringValue(forKeyPath: "book.1")
            XCTAssert(str! == "An extra text content of this book.", "book 2 additional text not found")
            
            let dict2 = xmlDictionary.dictionaryValue(forKeyPath: "book.1")
            XCTAssert((dict2!["_id"] as! String) == "bk102", "book not found")
            
            let valueList = [xmlDictionary].map({ (($0["book"] as! [Any])[0] as! [String:Any])["_id"] as! String })
            XCTAssert((valueList.first ?? "") == "bk101", "book id not found")
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
