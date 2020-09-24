//
//  SettingsCellData.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

public class SettingsCellData {

	public let plistData: Dictionary<String, Any>
	public var childData = [SettingsCellData]()

	public var specifierType: String? { return plistData["Type"] as? String }
	public var title: String? { return plistData["Title"] as? String }
	public var key: String? { return plistData["Key"] as? String }
	public var defaultValue: Any? { return plistData["DefaultValue"] }
	public var file: String? { return plistData["File"] as? String }

	public var headerText: String? { return overwriteHeaderText ?? title }
	public var footerText: String? { return overwriteFooterText ?? plistData["FooterText"] as? String }
	public var overwriteHeaderText: String?
	public var overwriteFooterText: String?

	public var isGroup: Bool { return specifierType?.contains("GroupSpecifier") ?? false }
	public var isChildPane: Bool { return specifierType?.contains("ChildPaneSpecifier") ?? false }
	public var isMultiValue: Bool { return specifierType?.contains("MultiValueSpecifier") ?? false }
	public var isPush: Bool { return isChildPane || isMultiValue }

	// Initialization
	public init(plistData: Dictionary<String, Any>) {
		self.plistData = plistData
	}

	// Title from value
	public func title<T: Equatable>(fromValue value: T?) -> String? {
		if let value = value ?? (defaultValue as? T),
			let titles = plistData["Titles"] as? [String],
			let values = plistData["Values"] as? [T],
			let index = values.firstIndex(of: value) {
			return titles[index]
		}
		if let value = value as? Int {
			return "\(value)"
		}
		return value as? String
	}
	
	// Bool from value
	public func bool<T: Equatable>(fromValue value: T?) -> Bool {
		if let value = value ?? (defaultValue as? T) {
			if plistData.keys.contains("TrueValue"),
				value == (plistData["TrueValue"] as? T) {
				return true
			} else if plistData.keys.contains("FalseValue"),
				value == (plistData["FalseValue"] as? T) {
				return false
			}
			return value as? Bool ?? false
		}
		return false
	}

	// Value from bool
	public func value(fromBool b: Bool) -> Any {
		let key = b ? "TrueValue" : "FalseValue"
		return plistData.keys.contains(key) ? plistData[key]! : b
	}

	// Equal
	public func isEqualValue<T: Equatable>(_ newValue: T?) -> Bool {
		guard let v1 = newValue ?? (defaultValue as? T),
			let v2 = plistData["Value"] as? T else {
			return false
		}
		return v1 == v2
	}

	// String from key
	public func string(_ key: String) -> String? {
		return plistData[key] as? String
	}

	// Bool from key
	public func bool(_ key: String) -> Bool? {
		return plistData[key] as? Bool
	}

}
