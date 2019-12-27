//
//  SettingsViewController+TextView.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/27.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public extension SettingsViewController {

	// TextView
	func updateCellTextView(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)

		if cell.contentView.subviews.compactMap({ $0 as? UITextView }).count == 0 {
			let view = UITextView()
			view.font = .preferredFont(forTextStyle: .body)
			view.backgroundColor = .clear
			view.isScrollEnabled = false
			cell.contentView.addSubview(view)

			// Add constraint to slider
			view.translatesAutoresizingMaskIntoConstraints = false
			view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading: .leadingMargin, .trailing: .trailingMargin, .top: .topMargin, .bottom: .bottomMargin]
 				as [NSLayoutConstraint.Attribute: NSLayoutConstraint.Attribute] {
				cell.contentView.addConstraint(
					NSLayoutConstraint(
						item: view,
						attribute: attr.key,
						relatedBy: .equal,
						toItem: cell.contentView,
						attribute: attr.value,
						multiplier: 1,
						constant: 0))
			}

			// Remove margin
			view.textContainerInset = .zero
			view.textContainer.lineFragmentPadding = 0
		}

		let view = cell.contentView.subviews.compactMap({ $0 as? UITextView }).first!

		guard let key = data.key else {
			return
		}

		UserDefaults.standard.rx.observe(String.self, key)
			.subscribe(onNext: { str in
				if view.text != str {
					view.text = str
				}
			})
			.disposed(by: cell.disposeBag)

		view.rx.didChange
			.subscribe(onNext: { [weak self] _ in
				self?.tableView?.beginUpdates()
				self?.tableView?.endUpdates()
				UserDefaults.standard.set(view.text, forKey: key)
			})
			.disposed(by: disposeBag)
	}

}
