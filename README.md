Purpose
--------------

This swift port is planned to be used with [IBM Kitura](https://github.com/IBM-Swift/Kitura)

NOTE: At the moment it's not working as expected on Linux. This seems related to this issue: [NSXMLParser not fully implemented](https://bugs.swift.org/browse/SR-2301)

XMLDictionary is a class designed to simplify parsing and generating of XML on iOS and Mac OS. XMLDictionary is built on top of the NSXMLParser classes, but behaves more like a DOM-style parser rather than SAX parser, in that it creates a tree of objects rather than generating events at the start and end of each node.

Unlike other DOM parsers, XMLDictionary does not attempt to replicate all of the nuances of the XML standard such as the ability to nest tags within text. If you need to represent something like an HTML document then XMLDictionary won't work for you. If you want to use XML as a data interchange format for passing nested data structures then XMLDictionary may well provide a simpler solution than other DOM-based parsers.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 10.2 / Mac OS 10.12 (Xcode 8.2, Apple LLVM compiler 8.0)
* Earliest supported deployment target - iOS 8.0 / Mac OS 10.10
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6
* ... to be tested on IBM's Docker swift-ubuntu Image

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


Thread Safety
--------------

XMLDictionary's methods should all be thread safe. It is safe to use multiple XMLDictionaryParsers concurrently on different threads, but it is not safe to call the same parser concurrently on multiple threads.

## Installation
To install this Swift version add the following line to Dependencies in `Package.swift`:

```swift
.Package(url: "https://github.com/VolkerBb/XMLDictionary.git", Version(2, 0, 0, prereleaseIdentifiers: ["rc.5"]))
```
NOTE: This is prerelease software and not fully tested yet. Specifically, only the default settings for the `XMLDictionaryParser` have been tested so far.

## Tests
To test parsing/decoding run `make test`. The tests are using a file resource, thus the added makefile. See [SwiftResourceHandlingExample](https://github.com/vadimeisenbergibm/SwiftResourceHandlingExample) for more info.

XMLDictionaryParser
---------------------

The XMLDictionaryParser class is responsible for parsing an XML file into a dictionary. You don't normally need to use this class explicitly as you can just use the utility methods added to NSDictionary, however it can be useful if you want to modify the default parser settings.

You can create new instances of XMLDictionaryParser if you need to use multiple different settings for different dictionaries. Once you have created an XMLDictionaryParser you can use the following methods to parse XML files using that specific parser instance:

```swift
    public static func dictionaryWithXMLParser(parser: XMLParser) -> [String : Any]?
    public static func dictionaryWithXMLData(xmlData: Data) -> [String : Any]?
    public static func dictionaryWithXMLString(xmlString: String) -> [String : Any]?
    public static func dictionaryWithXMLFile(xmlFilePath: String) -> [String : Any]?
```

Alternatively, you can simply modify the settings of `XMLDictionaryParser.sharedInstance` to affect the settings for all dictionaries parsed subsequently using the NSDictionary category extension methods.

Use the following properties to tweak the parsing behaviour:

```swift
    public var collapseTextNodes: Bool
```
    
If YES (the default value), tags that contain only text and have no children, attributes or comments will be collapsed into a single string object, simplifying traversal of the object tree.

```swift
    public var stripEmptyNodes: Bool
```
    
If YES (the default value), tags that are empty (have no children, attributes, text or comments) will be stripped.

```swift
    public var trimWhiteSpace: Bool
```

If YES (the default value), leading and trailing white space will be trimmed from text nodes, and text nodes containing only white space will be omitted from the dictionary.

```swift
    public var alwaysUseArrays: Bool
```

If `true`, the every child node will be represented as an array, even if there is only one of them. This simplifies the logic needed to cope with properties that may be duplicated because you don't need to use to check the for the singular case. Defaults to `false`.

```swift
    public var preserveComments: Bool
```

If `true`, XML comments will be grouped into an array under the key `__comments` and can be accessed via the `comments` method. Defaults to `false`.

```swift
    public var attributesMode: XMLDictionary.XMLDictionaryAttributesMode
```    

This property controls how XML attributes are handled. The default is `xmlDictionaryAttributesModePrefixed` meaning that attributes will be included in the dictionary, with an _ (underscore) prefix to avoid namespace collisions. Alternative values are `xmlDictionaryAttributesModeDictionary`, which will place all the attributes in a separate dictionary, `xmlDictionaryAttributesModeUnprefixed`, which includes the attributes without prefix (which may cause collisions with nodes) and `xmlDictionaryAttributesModeDiscard`, which will strip the attributes.

```swift
    public var nodeNameMode: XMLDictionary.XMLDictionaryNodeNameMode
```

This property controls how the node name is handled. The default value is `xmlDictionaryNodeNameModeRootOnly`, meaning that the node name will only be included in the root dictionary (the names for the children can be inferred from the dictionary keys, but the `nodeName` method won't work for anything except the root node). Alternative values are `xmlDictionaryNodeNameModeAlways`, meaning that the node name will be included in the dictionary with the key `__name` (and can be accessed using the `nodeName`) method, or `xmlDictionaryNodeNameModeNever` which will never include the `__name` key.


Dictionary extension 
-----------------

XMLDictionary as a typealias for [String : Any] extends Dictionary `where Key : ExpressibleByStringLiteral` with the following methods:

```swift
    public static func dictionaryWithXMLParser(parser: XMLParser) -> [String : Any]?
```
Create a new NSDictionary object from an existing NSXMLParser.  Useful if fetching data through AFNetworking.

```swift
    public static func dictionaryWithXMLData(xmlData: Data) -> [String : Any]?
```
Create a new NSDictionary object from XML-encoded data.

```swift
    public static func dictionaryWithXMLString(xmlString: String) -> [String : Any]?
```
Create a new NSDictionary object from XML-encoded string.

```swift
    public static func dictionaryWithXMLFile(xmlFilePath: String) -> [String : Any]?
```
Create a new NSDictionary object from and XML-encoded file.

```swift
    public func attributeForKey(key:String) -> String?
```
Get the XML attribute for a given key (key name should not include prefix).

```swift
    public func attributes() -> [String : String]?
```	
Get a dictionary of all XML attributes for a given node's dictionary. If the node has no attributes then this will return nil.

```swift
    public func childNodes() -> [String : Any]?
```		
Get a dictionary of all child nodes for a given node's dictionary. If multiple nodes have the same name they will be grouped into an array. If the node has no children then this will return nil.

```swift
    public func comments() -> [String]?
```		
Get an array of all comments for a given node. Note that the nesting relative to other nodes is not preserved. If the node has no comments then this will return nil.

```swift
    public func nodeName() -> String?
```		
Get the name of the node. If the name is not known this will return nil.

```swift
    public func innerText() -> Any?
```		
Get the text content of the node. If the node has no text content, this will return nil;

```swift
    public func innerXML() -> String
```		
Get the contents of the node as an XML-encoded string. This XML string will not include the container node itself.

```swift
    public func xmlString() -> String
```		
Get the node and its content as an XML-encoded string. If the node name is not known, the top level tag will be called `<root>`.

```swift
    public func value(forKeyPath keyPath: String) -> Any?
```		
In swift, the Objective-C like `valueForKeyPath:` doesn't exist. Instead, you can use a `map` call to filter your items. However, this method is here to help achieving something similar with `XMLDictionary` and can be used with the following syntax:

```swift
    xmlDictionary.value(forKeyPath: "book.0._id")
```		
NOTE: the path is simply separated with a `.` and an index n of an array must NOT be written as `[n]` but instead as `.n`. In case you are referencing a [String : Any] value in your path, the `.0` notation is referencing the key `["0"]` in that dictionary.

```swift
    public func arrayValue(forKeyPath keyPath: String) -> [Any]?
```		
Works just like `value(forKeyPath:)`, except that the value returned will always be an array. So if there is only a single value, it will be returned as `@[value]`.

```swift
    public func stringValue(forKeyPath keyPath: String) -> String?
```		
Works just like `value(forKeyPath:)`, except that the value returned will always be a string. So if the value is a dictionary, the text value of `innerText` will be returned, and if the value is an array, the first item will be returned.

```swift
    public func dictionaryValue(forKeyPath keyPath: String) -> [String : Any]?
```    
Works just like `value(forKeyPath:)`, except that the value returned will always be a dictionary. So if the collapseTextNodes option is enabled and the value is a string, this will convert it back to a dictionary before returning, and if the value is an array, the first item will be returned.


Usage
--------

The simplest way to load an XML file is as follows:

```swift
        if let path = bundle?.path(forResource: "example", ofType: "xml") {
            let xmlDictionary = XMLDictionary.dictionaryWithXMLFile(xmlFilePath: path)
	    // ...
        }
```    
You can then iterate over the dictionary as you would with any other object tree, e.g. one loaded from a Plist.

To access nested nodes and attributes, you can use the valueForKeyPath syntax. For example to get the string value of `<foo>` from the following XML:

	<root>
		<bar cliche="true">
			<foo>Hello World</foo>
		</bar>
		<banjo>Was his name-oh</banjo>
	</root>

You would write:

```swift
        xmlDictionary.value(forKeyPath: "bar.foo")
```   

The above examples assumes that you are using the default setting for `collapseTextNodes` and `alwaysUseArrays`. If `collapseTextNodes` is disabled then you would instead access `<foo>`'s value by writing:

```swift
        //TODO: test xmlDictionary.value(forKeyPath: "bar.foo").innerText()
```   

To get the cliche attribute of `bar`, you could write:

```swift
    if let barNode = xmlDictionary.value(forKeyPath: "bar") as? [String : Any] {
        let idAttribute = attrs.attributeForKey(key: "cliche")
	//...
    }
```    
    
If the `attributesMode` is set to the default value of `XMLDictionaryAttributesModePrefixed` then you can also do this:

```swift
    let barCliche = xmlDictionary.value(forKeyPath: "bar._cliche")
```    

Or if it is set to `XMLDictionaryAttributesModeUnprefixed` you would simply do this:

```swift
    let barCliche = xmlDictionary.value(forKeyPath: "bar.cliche")
```    
    
    
Release Notes
----------------

Version 2.0.0-rc.5

- Integrated test cases.

Version 2.0.0-rc.4

- Integrated Swift 4 changes and merged a bugfix related to attribute parsing.

Version 2.0.0-rc.2

- Swift Port Pre-Release Version (not fully tested)

Version 1.4.1

- Upgraded for Xcode 8.2
- Added tvOS and watchOS support to podspec

Version 1.4

- Added dictionaryWithXMLParser: constructor method
- Added wrapRootNode option as a nicer way to preserve root node name
- No longer crashes if non-string values are used as keys or attributes
- Now complies with the -Weverything warning level

Version 1.3

- added stripEmptyNodes property (defaults to YES)
- added arrayValueForKeyPath, stringValueForKeyPath and dictionaryValueForKeyPath methods to simplify working with data

Version 1.2.2

- sharedInstance method no longer returns a new instance each time

Version 1.2.1

- Removed isa reference, deprecated in iOS 7

Version 1.2

- Exposed XMLDictionaryParser object, which can be used to configure the parser
- Parsing options can now be changed without modifying the library
- Added option to always encode properties as arrays
- `__name` and `__coment` keys are no longer included by default
- Apostrophe is now encoded as `&apos;`
- removed `attributeForKey:` method

Version 1.1

- Updated to use ARC
- Added podspec

Version 1.0

- Initial release
