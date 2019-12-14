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
	var file: String? { return plistData["File"] as? String }

	var headerTitle: String? { return title }
	var footerTitle: String? { return plistData["FooterText"] as? String }
	var isGroup: Bool { return specifierType?.contains("GroupSpecifier") ?? false }
	var isChildPane: Bool { return specifierType?.contains("ChildPaneSpecifier") ?? false }

	// Initialization
	init(plistData: Dictionary<String, Any>) {
		self.plistData = plistData
	}

}
