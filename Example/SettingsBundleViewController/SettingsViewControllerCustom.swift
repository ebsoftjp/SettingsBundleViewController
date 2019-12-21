//
//  SettingsViewControllerCustom.swift
//  SettingsBundleViewController_Example
//
//  Created by Mamoru Sugihara on 12/21/2019.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SettingsBundleViewController

class SettingsViewControllerCustom: SettingsViewController {

	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		// Display header title including lowercase letters
		(view as? UITableViewHeaderFooterView)?.textLabel?.text = cellArray?[section].headerText
	}

	override func updateCellContent(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		super.updateCellContent(cell, data)

		// Custom type
		switch data.specifierType {
		case "PSButtonSpecifier":
			cell.didSelectHandler = { tableView, indexPath in
				let alert = UIAlertController(title: nil, message: data.title, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
					tableView.deselectRow(at: indexPath, animated: true)
				}))
				self.present(alert, animated: true, completion: nil)
			}

		case "PSProductButtonSpecifier":
			cell.didSelectHandler = { tableView, indexPath in
				self.startIndicator()
				Observable.just(0)
					.delay(.milliseconds(1000), scheduler: MainScheduler.instance)
					.subscribe(onNext: { _ in
						self.stopIndicator()
						let alert = UIAlertController(title: nil, message: data.string("ProductIdentifier"), preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
							tableView.deselectRow(at: indexPath, animated: true)
						}))
						self.present(alert, animated: true, completion: nil)
					})
					.disposed(by: cell.disposeBag)
			}

		default:
			break
		}
	}

}
