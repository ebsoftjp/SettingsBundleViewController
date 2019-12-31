//
//  SettingsViewControllerCustom.swift
//  SettingsBundleViewController_Example
//
//  Created by Mamoru Sugihara on 12/21/2019.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import CoreData
import RxSwift
import RxCocoa
import SettingsBundleViewController

class SettingsViewControllerCustom: SettingsViewController {

	open override func createCoreData(withChildData data: SettingsCellData) {
		if #available(iOS 10.0, *),
			let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
			createFetchedResultsController(context: context, data: data)

			let barButtonItemAdd = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
			let barButtonItemClear = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
			let barButtonItemEdit = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
			navigationItem.rightBarButtonItems = [barButtonItemAdd, barButtonItemClear, barButtonItemEdit]

			barButtonItemAdd.rx.tap
				.subscribe(onNext: { [weak self] _ in
					switch self?.fetchedResultsController?.fetchRequest.entityName {
					case "TestEntity1":
						let newEvent = TestEntity1(context: context)
						let date = Date()
						newEvent.date = date
						newEvent.text = "Add button \(Int(date.timeIntervalSince1970 * 10000) % 10000)"
						try? context.save()
					case "TestEntity2":
						let newEvent = TestEntity2(context: context)
						newEvent.index = Int64(Int.random(in: 0..<1000))
						newEvent.text = "Add button \(newEvent.index)"
						try? context.save()
					default:
						break
					}
				})
				.disposed(by: disposeBag)

			barButtonItemClear.rx.tap
				.subscribe(onNext: { [weak self] _ in
					self?.removeAllItems()
				})
				.disposed(by: disposeBag)

			barButtonItemEdit.rx.tap
				.subscribe(onNext: { [weak self] _ in
					self?.tableView?.isEditing = !(self?.tableView?.isEditing ?? false)
				})
				.disposed(by: disposeBag)
		}
	}

	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		// Display header title including lowercase letters
		(view as? UITableViewHeaderFooterView)?.textLabel?.text = cellArray?[section].headerText
	}

	override func updateCellContent(_ cell: SettingsTableViewCell, data: SettingsCellData) {
		super.updateCellContent(cell, data: data)

		// Custom type
		switch data.specifierType {
		case "PSButtonSpecifier":
			cell.didSelectHandler = { [weak self] tableView, indexPath in
				let alert = UIAlertController(title: nil, message: data.title, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
					tableView.deselectRow(at: indexPath, animated: true)
				}))
				self?.present(alert, animated: true, completion: nil)
			}

		case "PSProductButtonSpecifier":
			cell.didSelectHandler = { [weak self] tableView, indexPath in
				self?.startIndicator()
				Observable.just(0)
					.delay(.milliseconds(1000), scheduler: MainScheduler.instance)
					.subscribe(onNext: { [weak self] _ in
						self?.stopIndicator()
						let alert = UIAlertController(title: nil, message: data.string("ProductIdentifier"), preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
							tableView.deselectRow(at: indexPath, animated: true)
						}))
						self?.present(alert, animated: true, completion: nil)
					})
					.disposed(by: cell.disposeBag)
			}

		default:
			break
		}
	}

	open override func updateCellContent(_ cell: SettingsTableViewCell, event: NSManagedObject) {
		switch event {
		case let event as TestEntity1:
			if let date = event.date,
				let text = event.text {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS"
				cell.textLabel?.text = "\(dateFormatter.string(from: date))\n\(text)"
				cell.didSelectHandler = { [weak self] tableView, indexPath in
					let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
						tableView.deselectRow(at: indexPath, animated: true)
					}))
					self?.present(alert, animated: true, completion: nil)
				}
			}

		case let event as TestEntity2:
			if let text = event.text {
				cell.textLabel?.text = "\(event.index): \(text)"
			}

		default:
			break
		}
	}

}
