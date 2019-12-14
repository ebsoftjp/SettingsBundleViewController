//
//  UITableViewCell+Extensions.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

extension UITableViewCell {

	var tableView: UITableView? {
		var view: UIView? = self
		while view != nil {
			if let view = view as? UITableView {
				return view
			}
			view = view?.superview
		}
		return nil
	}

	convenience init(data: SettingsCellData, reuseIdentifier: String?) {
		self.init(style: .value1, reuseIdentifier: reuseIdentifier)

		if data.specifierType == "PSToggleSwitchSpecifier" {
			accessoryView = UISwitch()
		}
		if data.specifierType == "PSSliderSpecifier" {
			let slider = UISlider()
			addSubview(slider)

			// Add constraint to slider
			slider.translatesAutoresizingMaskIntoConstraints = false
			slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading: .leadingMargin, .trailing: .trailingMargin, .centerY: .centerY]
				as [NSLayoutConstraint.Attribute: NSLayoutConstraint.Attribute] {
				self.addConstraint(
					NSLayoutConstraint(
						item: slider,
						attribute: attr.key,
						relatedBy: .equal,
						toItem: self,
						attribute: attr.value,
						multiplier: 1,
						constant: 0))
			}
		}
	}

}
