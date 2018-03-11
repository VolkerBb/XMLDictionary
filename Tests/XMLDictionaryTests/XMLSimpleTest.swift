//
//  XMLSimpleTest.swift
//  XMLDictionary
//
//  Created by Volker Bublitz on 23/02/2017.
//
//

import XCTest
@testable import XMLDictionary

class XMLSimpleTest: XCTestCase {

    var bundle:Bundle?
    var parsedDictionary:XMLDictionary?
    
    override func setUp() {
        super.setUp()
        #if os(Linux)
            // copied from https://github.com/IBM-Swift/Bridging/blob/master/Sources/Bridging/FoundationAdapterLinux.swift
            //
            // Bundle(for:) is not yet implemented on Linux
            //TODO remove this ifdef once Bundle(for:) is implemented
            // issue https://bugs.swift.org/browse/SR-953
            // meanwhile return a Bundle whose resource path points to /Resources directory
            //     inside the resourcePath of Bundle.main (e.g. .build/debug/Resources)
            bundle = Bundle(path: (Bundle.main.resourcePath ?? ".") + "/Resources") ?? Bundle.main
        #else
            bundle = Bundle(for: Swift.type(of: self))
        #endif
        NSLog("bundle path: %@", bundle?.bundlePath ?? "none")
        parsedDictionary = parse(filePath: bundle?.path(forResource: "example", ofType: "xml"))
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func parse(url: URL) -> XMLDictionary? {
        if let xmlString = try? String(contentsOf: url, encoding: .utf8) {
            return XMLDictionary.dictionaryWithXMLString(xmlString: xmlString)
        }
        return nil
    }
    
    func parse(filePath: String?) -> XMLDictionary? {
        guard let p = filePath else {
            return nil
        }
        return XMLDictionary.dictionaryWithXMLFile(xmlFilePath: p)
    }
    
    func testBaseVars() {
        XCTAssertNotNil(bundle, "bundle is nil")
        XCTAssertNotNil(parsedDictionary, "parsed dictionary is nil")
    }
    
    func testExample() {
        guard let xmlDictionary = parsedDictionary else {
            XCTAssert(false, "parsing error")
            return
        }
        
        let value = xmlDictionary.value(forKeyPath: "book.0._id")
        guard let v = value as? String else {
            XCTAssert(false, "book not found")
            return
        }
        XCTAssert(v == "bk101", "book not found")
        
        if let bookNode = xmlDictionary.value(forKeyPath: "book.1") as? [String : Any] {
            let idAttribute = bookNode.attributeForKey(key: "id")
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
    
    func testURLParsing() {
        if let url2 = URL(string: "http://www.ibiblio.org/xml/examples/shakespeare/all_well.xml") {
            XCTAssertNotNil(self.parse(url: url2), "Parsing of http://www.ibiblio.org/xml/examples/shakespeare/all_well.xml failed")
        }
    }

    func testParsingPerformance() {
        NSLog("Measuring xml file to XMLDictionary")
        self.measure {
            if let path = self.bundle?.path(forResource: "example", ofType: "xml") {
                let _ = XMLDictionary.dictionaryWithXMLFile(xmlFilePath: path)
            }
        }
    }
    
    func testEncodingPerformance() {
        guard let xmlDictionary = parsedDictionary else {
            XCTAssert(false, "parsing error")
            return
        }
        NSLog("Measuring XMLDictionary to xmlString")
        self.measure {
            let _ = xmlDictionary.xmlString()
        }
    }

}
