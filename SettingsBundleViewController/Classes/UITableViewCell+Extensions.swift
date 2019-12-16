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

	convenience init(text: String, data: SettingsCellData, reuseIdentifier: String?) {
		self.init(style: .value1, reuseIdentifier: reuseIdentifier)

		// AccessoryType
		accessoryType = data.isChildPane ? .disclosureIndicator : .none

		// Label
		textLabel?.text = text
		textLabel?.numberOfLines = 16

		// Switch
		if data.specifierType == "PSToggleSwitchSpecifier" {
			accessoryView = UISwitch()
		}

		// Slider
		if data.specifierType == "PSSliderSpecifier" {
			let slider = UISlider()
			addSubview(slider)

			// Add constraint to slider
			slider.translatesAutoresizingMaskIntoConstraints = false
			slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading: .leadingMargin, .trailing: .trailingMargin, .centerY: .centerY]
				as [NSLayoutConstraint.Attribute: NSLayoutConstraint.Attribute] {
				addConstraint(
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

		// TextField
		if data.specifierType == "PSTextFieldSpecifier" {
			var r = bounds
			r.size.width = r.width * 2 / 3
			let textField = UITextField(frame: r)
			textField.font = .preferredFont(forTextStyle: .body)
			accessoryView = textField
		}
	}

}
