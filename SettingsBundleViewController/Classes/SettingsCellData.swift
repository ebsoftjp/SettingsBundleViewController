//
//  SettingsCellData.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

struct SettingsCellData {

	let plistData: Dictionary<String, Any>
	var childData = [SettingsCellData]()

	var specifierType: String? { return plistData["Type"] as? String }
	var title: String? { return plistData["Title"] as? String }
	var key: String? { return plistData["Key"] as? String }
	var defaultValue: Any? { return plistData["DefaultValue"] }
	var file: String? { return plistData["File"] as? String }

	var headerTitle: String? { return title }
	var footerTitle: String? { return plistData["FooterText"] as? String }
	var isGroup: Bool { return specifierType?.contains("GroupSpecifier") ?? false }
	var isChildPane: Bool { return specifierType?.contains("ChildPaneSpecifier") ?? false }
	var isMultiValue: Bool { return specifierType == "PSMultiValueSpecifier" }
	var isPush: Bool { return isChildPane || isMultiValue }

	// Initialization
	init(plistData: Dictionary<String, Any>) {
		self.plistData = plistData
		if specifierType == "PSRadioGroupSpecifier" {
			// Use PSMultiValueSelectorSpecifier
			appendChild(self)
		}
	}

	// Add child for MultiValue and RadioGroup
	mutating func appendChild(_ parent: SettingsCellData) {
		if let key = parent.key,
			!key.isEmpty,
			let defaultValue = parent.defaultValue,
			let titles = parent.plistData["Titles"] as? [String],
			let values = parent.plistData["Values"] as? [Any] {
			for i in 0..<titles.count {
				childData.append(SettingsCellData(plistData: [
					"Type": "PSMultiValueSelectorSpecifier",
					"Title": titles[i],
					"Value": values[i],
					"Key": key,
					"DefaultValue": defaultValue,
				]))
			}
		}
	}

	// Title from value
	func title<T: Equatable>(fromValue value: T?) -> String? {
		if let value = value,
			let titles = plistData["Titles"] as? [String],
			let values = plistData["Values"] as? [T],
			let index = values.firstIndex(of: value) {
			return titles[index]
		}
		return value as? String
	}

	// Selected
	func selected() {
		if let key = key, !key.isEmpty, let value = plistData["Value"] {
			if specifierType == "PSMultiValueSelectorSpecifier" {
				UserDefaults.standard.set(value, forKey: key)
			}
		}
	}

	// Equal
	func isEqualValue<T: Equatable>(_ newValue: T?) -> Bool {
		guard let v1 = newValue, let v2 = plistData["Value"] as? T else {
			return false
		}
		return v1 == v2
	}

}
