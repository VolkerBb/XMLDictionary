//
//  XMLDictionaryParser.swift
//  XMLDictionary
//
//  Created by Volker Bublitz on 23/02/2017.
//
//

import Foundation

typealias XMLDictionary = Dictionary<String, Any>

enum XMLDictionaryAttributesMode {
    case xmlDictionaryAttributesModePrefixed, xmlDictionaryAttributesModeDictionary,
    xmlDictionaryAttributesModeUnprefixed, xmlDictionaryAttributesModeDiscard
}

enum XMLDictionaryNodeNameMode {
    case xmlDictionaryNodeNameModeRootOnly, xmlDictionaryNodeNameModeAlways, xmlDictionaryNodeNameModeNever
}

class XMLDictionaryParser : NSObject, XMLParserDelegate {
    
    var collapseTextNodes:Bool = true
    var stripEmptyNodes:Bool = true
    var trimWhiteSpace:Bool = true
    var alwaysUseArrays:Bool = false
    var preserveComments:Bool = false
    var wrapRootNode:Bool = false
    
    var attributesMode:XMLDictionaryAttributesMode = .xmlDictionaryAttributesModePrefixed
    var nodeNameMode:XMLDictionaryNodeNameMode = .xmlDictionaryNodeNameModeRootOnly
    
    private var nodeIdentifier:Int = 0
    private var root:[String:Any]?
    private var stack:[[String:Any]]?
    private var text:String?
    
    static let sharedInstance = XMLDictionaryParser()
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = XMLDictionaryParser()
        copy.collapseTextNodes = self.collapseTextNodes
        copy.stripEmptyNodes = self.stripEmptyNodes
        copy.trimWhiteSpace = self.trimWhiteSpace
        copy.alwaysUseArrays = self.alwaysUseArrays
        copy.preserveComments = self.preserveComments
        copy.wrapRootNode = self.wrapRootNode
        copy.attributesMode = self.attributesMode
        copy.nodeNameMode = self.nodeNameMode
        return copy
    }
    
    func dictionaryWithParser(parser:XMLParser) -> [String : Any]? {
        parser.delegate = self
        parser.parse()
        let result = root
        root = nil
        stack = nil
        text = nil
        return result
    }
    
    func dictionaryWithData(data:Data) -> [String : Any]? {
        return self.dictionaryWithParser(parser: XMLParser(data: data))
    }
    
    func dictionaryWithString(string:String) -> [String : Any]? {
        return self.dictionaryWithData(data: string.data(using: .utf8)!)
    }
    
    func dictionaryWithFile(path:String) -> [String : Any]? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return self.dictionaryWithData(data: data)
        }
        catch {
            return nil
        }
    }
    
    func endText() {
        if (trimWhiteSpace) {
            text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        if let processingText = text, processingText.characters.count > 0 {
            if var top = stack?.last {
                if let existing = top[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue] {
                    if var e = existing as? [Any] {
                        e.append(processingText)
                        top[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue] = e
                    }
                    else {
                        top[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue] = [existing, processingText]
                    }
                }
                else {
                    top[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue] = processingText
                }
            }
        }
        text = nil
    }
    
    func addText(appendingText: String) {
        text = (text ?? "") + appendingText
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        self.endText()
        var node:[String:Any] = [:]
        
        switch nodeNameMode {
        case .xmlDictionaryNodeNameModeRootOnly:
            if root == nil {
                node[XMLDictionaryKeys.xmlDictionaryNodeNameKey.rawValue] = elementName
            }
            break
        case .xmlDictionaryNodeNameModeAlways:
            node[XMLDictionaryKeys.xmlDictionaryNodeNameKey.rawValue] = elementName
            break
        case .xmlDictionaryNodeNameModeNever:
            break
        }
        
        if attributeDict.count > 0 {
            switch attributesMode {
            case .xmlDictionaryAttributesModePrefixed:
                attributeDict.forEach({ (key, value) in
                    node[XMLDictionaryKeys.xmlDictionaryAttributePrefix.rawValue + key] = value
                })
                break
            case .xmlDictionaryAttributesModeDictionary:
                node[XMLDictionaryKeys.xmlDictionaryAttributesKey.rawValue] = attributeDict
                break
            case .xmlDictionaryAttributesModeUnprefixed:
                attributeDict.forEach({ (key, value) in
                    node[key] = value
                })
                break
            case .xmlDictionaryAttributesModeDiscard:
                break
            }
        }
        
        guard let _ = root else {
            root = node
            stack = [node]
            if wrapRootNode {
                root = [elementName : node]
                
                root![XMLDictionaryKeys.xmlDictionaryIdentifier.rawValue] = nodeIdentifier
                nodeIdentifier = nodeIdentifier + 1
                stack?.insert(root!, at: 0)
            }
            return
        }
        
        if var top = stack?.last {
            if let existing = top[elementName] {
                if var e = existing as? [Any] {
                    e.append(node)
                    top[elementName] = e
                }
                else {
                    top[elementName] = [existing, node]
                }
            }
            else {
                if alwaysUseArrays {
                    top[elementName] = [node]
                }
                else {
                    top[elementName] = node
                }
            }
            stack?.append(node)
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        self.endText()
        if var top = stack?.popLast() {
            guard let _ = top.attributes(),
                let _ = top.childNodes(),
                let _ = top.comments() else {
                    var nextTop:[String:Any] = stack?.last ?? [:]
                    if let nodeName = self.nameForNode(node: top, inDictionary: nextTop) {
                        let parentNode = nextTop[nodeName]
                        if let innerText = top.innerText() {
                            if collapseTextNodes {
                                if var parentArray = parentNode as? [Any] {
                                    parentArray[parentArray.count - 1] = innerText
                                }
                                else {
                                    nextTop[nodeName] = innerText
                                }
                            }
                        }
                        else {
                            if stripEmptyNodes {
                                if var parentArray = parentNode as? [Any] {
                                    parentArray.removeLast()
                                    nextTop[nodeName] = parentArray
                                }
                                else {
                                    nextTop[nodeName] = nil
                                }
                            }
                            else if !collapseTextNodes {
//MARK: WARNING top!? oder nextTop?
                                top[XMLDictionaryKeys.xmlDictionaryTextKey.rawValue] = ""
                            }
                        }
                        
                    }
                    return
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.addText(appendingText: string)
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        self.addText(appendingText: String(data: CDATABlock, encoding: .utf8) ?? "")
    }
    
    func parser(_ parser: XMLParser, foundComment comment: String) {
        if preserveComments {
            if var top = stack?.last {
                if var comments = top[XMLDictionaryKeys.xmlDictionaryCommentsKey.rawValue] as? [String] {
                    comments.append(comment)
                    top[XMLDictionaryKeys.xmlDictionaryCommentsKey.rawValue] = comments
                }
                else {
                    top[XMLDictionaryKeys.xmlDictionaryCommentsKey.rawValue] = [comment]
                }
            }
        }
    }
    
    func nameForNode(node:[String:Any], inDictionary dict:[String:Any]) -> String? {
        if let result = node.nodeName() {
            return result
        }
        for (name, value) in dict {
            if let object = value as? [String:Any] {
                if XMLDictionaryParser.equalsIdentifier(dict: object, dict2: node) {
                    return name
                }
            }
            else if let array = value as? [[String: Any]] {
                for entry in array {
                    if XMLDictionaryParser.equalsIdentifier(dict: entry, dict2: node) {
                        return name
                    }
                }
            }
        }
        return nil
    }
    
    static func XMLStringForNode(node:Any, withNodeName nodeName:String) -> String {
        if let array = node as? [Any] {
            var nodes:[String] = []
            for individualNode in array {
                nodes.append(XMLDictionaryParser.XMLStringForNode(node: individualNode, withNodeName: nodeName))
            }
            return nodes.joined(separator: "\n")
        }
        else if let dict = node as? [String : Any] {
            let attributes = dict.attributes()
            var attributeString = ""
            attributes?.forEach({ (key, value) in
                attributeString = attributeString + " \(key.xmlEncodedString)=\"\(value.xmlEncodedString)\""
            })
            var innerXML = dict.innerXML()
            if innerXML.characters.count > 0 {
                return "<\(nodeName)\(attributeString)>\(innerXML)</\(nodeName)>"
            }
            else {
                return "<\(nodeName)\(attributeString)/>"
            }
        }
        else {
            return "<\(nodeName)>\((node as AnyObject).description.xmlEncodedString())</\(nodeName)>"
        }
    }
    
}
