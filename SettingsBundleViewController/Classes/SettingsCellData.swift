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
	var isRadio: Bool { return specifierType?.contains("RadioGroupSpecifier") ?? false }
	var isParent: Bool { return isGroup || isRadio }
	var isChildPane: Bool { return specifierType?.contains("ChildPaneSpecifier") ?? false }
	var isMultiValue: Bool { return specifierType == "PSMultiValueSpecifier" }
	var isPush: Bool { return isChildPane || isMultiValue }

	// Initialization
	init(plistData: Dictionary<String, Any>) {
		self.plistData = plistData
		if specifierType == "PSRadioGroupSpecifier" {
			appendChild(self)
		}
	}

	mutating func appendChild(_ parent: SettingsCellData) {
		if let key = parent.key,
			!key.isEmpty,
			let titles = parent.plistData["Titles"] as? Array<String>,
			let values = parent.plistData["Values"] as? Array<Any> {
			for i in 0..<titles.count {
				childData.append(SettingsCellData(plistData: [
					"Type": "PSRadioGroupSpecifierSelector",
					"Title": titles[i],
					"Value": parent.isDefaultValue(values[i]),
					"Key": key,
				]))
			}
		}
	}

	func isDefaultValue(_ value: Any) -> Bool {
		if let v1 = value as? String, let v2 = defaultValue as? String {
			return v1 == v2
		} else if let v1 = value as? Int, let v2 = defaultValue as? Int {
				return v1 == v2
		}
		return false
	}
}
