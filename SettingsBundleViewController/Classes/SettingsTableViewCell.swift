//
//  SettingsTableViewCell.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsTableViewCell: UITableViewCell {

	private var disposeBag = DisposeBag()

	convenience init(reuseIdentifier: String?) {
		self.init(style: .value1, reuseIdentifier: reuseIdentifier)
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		// Unsubscribe when reusing
		disposeBag = DisposeBag()
	}

	func updateContext(text: String, data: SettingsCellData) {
		// AccessoryType
		accessoryType = data.isChildPane ? .disclosureIndicator : .none

		// Label
		textLabel?.text = text
		textLabel?.numberOfLines = 16

		// Switch
		if data.specifierType == "PSToggleSwitchSpecifier" {
			let view = UISwitch()
			view.isOn = UserDefaults.standard.bool(forKey: data.key!)
			accessoryView = view

			UserDefaults.standard.rx.observe(Bool.self, data.key!)
				.subscribe(onNext: { b in
					view.setOn(b ?? false, animated: true)
				})
				.disposed(by: disposeBag)

			view.rx.controlEvent(.valueChanged)
				.withLatestFrom(view.rx.value)
				.subscribe(onNext: {
					UserDefaults.standard.set($0, forKey: data.key!)
				})
				.disposed(by: disposeBag)
		}

		// Slider
		if data.specifierType == "PSSliderSpecifier" {
			textLabel?.text = " "

			let view = UISlider()
			view.backgroundColor = .clear
			view.minimumValue = data.plistData["MinimumValue"] as? Float ?? 0
			view.maximumValue = data.plistData["MaximumValue"] as? Float ?? 1
			addSubview(view)

			// Add constraint to slider
			view.translatesAutoresizingMaskIntoConstraints = false
			view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading: .leadingMargin, .trailing: .trailingMargin, .centerY: .centerY]
				as [NSLayoutConstraint.Attribute: NSLayoutConstraint.Attribute] {
				addConstraint(
					NSLayoutConstraint(
						item: view,
						attribute: attr.key,
						relatedBy: .equal,
						toItem: self,
						attribute: attr.value,
						multiplier: 1,
						constant: 0))
			}

			UserDefaults.standard.rx.observe(Float.self, data.key!)
				.subscribe(onNext: { f in
					view.setValue(f ?? view.minimumValue, animated: true)
				})
				.disposed(by: disposeBag)

			view.rx.controlEvent(.valueChanged)
				.withLatestFrom(view.rx.value)
				.subscribe(onNext: {
					UserDefaults.standard.set($0, forKey: data.key!)
				})
				.disposed(by: disposeBag)
		}

		// TextField
		if data.specifierType == "PSTextFieldSpecifier" {
			var r = bounds
			r.size.width = r.width * 2 / 3
			let view = UITextField(frame: r)
			view.font = .preferredFont(forTextStyle: .body)
			view.returnKeyType = .done
			accessoryView = view

			UserDefaults.standard.rx.observe(String.self, data.key!)
				.subscribe(onNext: { str in
					if view.text != str {
						view.text = str
					}
				})
				.disposed(by: disposeBag)

			view.rx.controlEvent(.editingChanged)
				.withLatestFrom(view.rx.text)
				.subscribe(onNext: {
					UserDefaults.standard.set($0, forKey: data.key!)
				})
				.disposed(by: disposeBag)
		}

		// TitleValue
		if data.specifierType == "PSTitleValueSpecifier" {
			UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
				.subscribe(onNext: { [weak self] value in
					self?.detailTextLabel?.text = data.title(fromValue: value)
				})
				.disposed(by: disposeBag)
		}

		// MultiValue
		if data.specifierType == "PSMultiValueSpecifier" {
			UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
				.subscribe(onNext: { [weak self] value in
					self?.detailTextLabel?.text = data.title(fromValue: value)
				})
				.disposed(by: disposeBag)
			accessoryType = .disclosureIndicator
		}

		// MultiValue selector
		if data.specifierType == "PSMultiValueSelectorSpecifier" {
			UserDefaults.standard.rx.observe(String.self, data.key!)
				.subscribe(onNext: { [weak self] str in
					self?.accessoryType = data.isEqualValue(str) ? .checkmark : .none
				})
				.disposed(by: disposeBag)
		}
	}

}
