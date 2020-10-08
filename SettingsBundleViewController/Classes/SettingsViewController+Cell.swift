//
//  SettingsViewController+Cell.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/19.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

public extension SettingsViewController {

	// ChildPane
	func updateCellChildPane(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)
		cell.accessoryType = .disclosureIndicator
		cell.didSelectHandler = { [weak self] tableView, indexPath in
			self?.showChild(tableView, indexPath)
		}
	}

	// ToggleSwitch
	func updateCellToggleSwitch(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.attributedText = localizedTitle(data)

		#if !os(tvOS)
		if cell.accessoryView == nil {
			let view = UISwitch()
			cell.accessoryView = view
		}

		let view = cell.accessoryView as! UISwitch

		UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
			.subscribe(onNext: { value in
				let b = data.bool(fromValue: value)
				if view.isOn != b {
					view.setOn(b, animated: true)
				}
			})
			.disposed(by: cell.disposeBag)

		view.rx.controlEvent(.valueChanged)
			.withLatestFrom(view.rx.value)
			.subscribe(onNext: {
				UserDefaults.standard.set(data.value(fromBool: $0), forKey: data.key!)
			})
			.disposed(by: cell.disposeBag)
		#endif
	}

	// Slider
	func updateCellSlider(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = nil

		#if !os(tvOS)
		if cell.contentView.subviews.compactMap({ $0 as? UISlider }).count == 0 {
			let dummyView = UILabel()
			dummyView.font = .preferredFont(forTextStyle: .body)
			dummyView.text = " "
			cell.contentView.addSubview(dummyView)

			// Add constraint to dummy view
			dummyView.translatesAutoresizingMaskIntoConstraints = false
			dummyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading: .leadingMargin, .trailing: .trailingMargin, .top: .topMargin, .bottom: .bottomMargin]
				as [NSLayoutConstraint.Attribute: NSLayoutConstraint.Attribute] {
				cell.contentView.addConstraint(
					NSLayoutConstraint(
						item: dummyView,
						attribute: attr.key,
						relatedBy: .equal,
						toItem: cell.contentView,
						attribute: attr.value,
						multiplier: 1,
						constant: 0))
			}

			let view = UISlider()
			view.backgroundColor = .clear
			view.minimumValue = data.plistData["MinimumValue"] as? Float ?? 0
			view.maximumValue = data.plistData["MaximumValue"] as? Float ?? 1
			cell.contentView.addSubview(view)

			// Add constraint to slider
			view.translatesAutoresizingMaskIntoConstraints = false
			view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading, .trailing, .centerY] as [NSLayoutConstraint.Attribute] {
				cell.contentView.addConstraint(
					NSLayoutConstraint(
						item: view,
						attribute: attr,
						relatedBy: .equal,
						toItem: dummyView,
						attribute: attr,
						multiplier: 1,
						constant: 0))
			}
		}

		let view = cell.contentView.subviews.compactMap({ $0 as? UISlider }).first!

		UserDefaults.standard.rx.observe(Float.self, data.key!)
			.subscribe(onNext: { f in
				view.setValue(f ?? view.minimumValue, animated: true)
			})
			.disposed(by: cell.disposeBag)

		view.rx.controlEvent(.valueChanged)
			.withLatestFrom(view.rx.value)
			.subscribe(onNext: {
				UserDefaults.standard.set($0, forKey: data.key!)
			})
			.disposed(by: cell.disposeBag)
		#endif
	}
	
	// TitleValue
	func updateCellTitleValue(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)

		UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
			.subscribe(onNext: { [weak self] value in
				cell.detailTextLabel?.text = self?.localized(data.title(fromValue: value))
			})
			.disposed(by: cell.disposeBag)
	}

	// TextField
	func updateCellTextField(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)

		if cell.accessoryView == nil {
			var r = cell.bounds
			r.size.width = r.width * 2 / 3
			let view = UITextField(frame: r)
			view.font = .preferredFont(forTextStyle: .body)
			view.returnKeyType = .done
			cell.accessoryView = view
		}

		let view = cell.accessoryView as! UITextField

		UserDefaults.standard.rx.observe(String.self, data.key!)
			.subscribe(onNext: { str in
				if view.text != str {
					view.text = str
				}
			})
			.disposed(by: cell.disposeBag)

		view.rx.controlEvent(.editingChanged)
			.withLatestFrom(view.rx.text)
			.subscribe(onNext: {
				UserDefaults.standard.set($0, forKey: data.key!)
			})
			.disposed(by: cell.disposeBag)
	}

	// MultiValue
	func updateCellMultiValue(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)
		cell.accessoryType = .disclosureIndicator
		cell.didSelectHandler = { [weak self] tableView, indexPath in
			self?.showChild(tableView, indexPath)
		}

		UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
			.subscribe(onNext: { [weak self] value in
				cell.detailTextLabel?.text = self?.localized(data.title(fromValue: value))
			})
			.disposed(by: cell.disposeBag)
	}

	// MultiValue selector
	func updateCellMultiValueSelector(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.attributedText = localizedTitle(data)

		cell.didSelectHandler = { tableView, indexPath in
			UserDefaults.standard.set(data.plistData["Value"], forKey: data.key!)
			tableView.deselectRow(at: indexPath, animated: true)
		}

		UserDefaults.standard.rx.observe(AnyHashable.self, data.key!)
			.subscribe(onNext: { value in
				cell.accessoryType = data.isEqualValue(value) ? .checkmark : .none
			})
			.disposed(by: cell.disposeBag)
	}

}
