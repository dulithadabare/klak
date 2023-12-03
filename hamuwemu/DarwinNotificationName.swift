//
//  DarwinNotificationName.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-11.
//

@objc
public class DarwinNotificationName: NSObject, ExpressibleByStringLiteral {
    @objc public static let sdsCrossProcess: DarwinNotificationName = "org.hamuwemu.sdscrossprocess"
    @objc public static let nseDidReceiveNotification: DarwinNotificationName = "org.hamuwemu.nseDidReceiveNotification"
    @objc public static let mainAppHandledNotification: DarwinNotificationName = "org.hamuwemu.mainAppHandledNotification"
    @objc public static let mainAppLaunched: DarwinNotificationName = "org.hamuwemu.mainAppLaunched"

    public typealias StringLiteralType = String

    private let stringValue: String

    @objc
    public var cString: UnsafePointer<Int8> {
        return stringValue.withCString { $0 }
    }

    @objc
    public var isValid: Bool {
        return stringValue.isEmpty == false
    }

    public required init(stringLiteral value: String) {
        stringValue = value
    }

    @objc
    public init(_ name: String) {
        stringValue = name
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherName = object as? DarwinNotificationName else { return false }
        return otherName.stringValue == stringValue
    }

    public override var hash: Int {
        return stringValue.hashValue
    }
}

