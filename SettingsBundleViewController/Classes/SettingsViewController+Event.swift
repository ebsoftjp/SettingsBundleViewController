//
//  SettingsViewController+Event.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/21.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

#if !os(tvOS)
import UIKit
import EventKit
import RxSwift
import RxCocoa

extension SettingsViewController {

	open func createEventMultiValue(_ data: SettingsCellData, entityType: EKEntityType) -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let key = data.key,
			!key.isEmpty,
			let eventStore = SettingsBundleViewController.eventStore,
			let defaultCalendar = calendar(fromEntityType: entityType) {
			eventStore.sources.sorted(by: { v1, v2 -> Bool in
				v1.title.lowercased() < v2.title.lowercased()
			}).forEach { source in
				let sourceData = SettingsCellData(plistData: [
					"Type": "PSGroupSpecifier",
					"Title": source.title,
				])
				source.calendars(for: entityType).sorted(by: { v1, v2 -> Bool in
					v1.title.lowercased() < v2.title.lowercased()
				}).forEach { calendar in
					let cellData = SettingsCellData(plistData: [
						"Type": "PSMultiValueSelectorSpecifier",
						"Title": calendar.title,
						"Key": key,
						"Value": calendar.calendarIdentifier,
						"DefaultValue": defaultCalendar.calendarIdentifier,
						"Color": UIColor(cgColor: calendar.cgColor),
					])
					sourceData.childData.append(cellData)
				}
				if sourceData.childData.count > 0 {
					res.append(sourceData)
				}
			}
		}
		return res
	}

	open func createEventToggleSwitch(_ data: SettingsCellData, entityType: EKEntityType) -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let key = data.key, !key.isEmpty {
			SettingsBundleViewController.eventStore?.sources.sorted(by: { v1, v2 -> Bool in
				v1.title.lowercased() < v2.title.lowercased()
			}).forEach { source in
				let sourceData = SettingsCellData(plistData: [
					"Type": "PSGroupSpecifier",
					"Title": source.title,
				])
				source.calendars(for: entityType).sorted(by: { v1, v2 -> Bool in
					v1.title.lowercased() < v2.title.lowercased()
				}).forEach { calendar in
					let cellData = SettingsCellData(plistData: [
						"Type": "PSToggleSwitchSpecifier",
						"Title": calendar.title,
						"Key": key + calendar.calendarIdentifier,
						"DefaultValue": data.defaultValue ?? false,
						"Color": UIColor(cgColor: calendar.cgColor),
					])
					sourceData.childData.append(cellData)
				}
				if sourceData.childData.count > 0 {
					res.append(sourceData)
				}
			}
		}
		return res
	}

	// EventMultiValue
	open func updateCellEventMultiValue(_ cell: SettingsTableViewCell, _ data: SettingsCellData, entityType: EKEntityType) {
		cell.textLabel?.text = localized(data.title)
		cell.accessoryType = .disclosureIndicator
		cell.didSelectHandler = { [weak self] tableView, indexPath in
			self?.showChild(tableView, indexPath)
		}

		UserDefaults.standard.rx.observe(String.self, data.key!)
			.subscribe(onNext: { [weak self] value in
				let value = value ?? self?.calendar(fromEntityType: entityType)?.calendarIdentifier
				cell.detailTextLabel?.text = SettingsBundleViewController.eventStore?
					.calendars(for: entityType).filter { $0.calendarIdentifier == value }.first?.title
			})
			.disposed(by: cell.disposeBag)
	}

	// EventToggleSwitch
	open func updateCellEventToggleSwitch(_ cell: SettingsTableViewCell, _ data: SettingsCellData, entityType: EKEntityType) {
		cell.textLabel?.text = localized(data.title)
		cell.accessoryType = .disclosureIndicator
		cell.didSelectHandler = { [weak self] tableView, indexPath in
			self?.showChild(tableView, indexPath)
		}

		var eventStore: EKEventStore?
		if EKEventStore.authorizationStatus(for: entityType) == .authorized {
			eventStore = EKEventStore()
		}

		eventStore?.calendars(for: entityType).forEach {
			UserDefaults.standard.rx.observe(Bool.self, data.key! + $0.calendarIdentifier)
				.subscribe(onNext: { _ in
					let n = SettingsBundleViewController.eventStore?.calendars(for: entityType).reduce(0) { acc, calendar in
						var res = acc ?? 0
						if UserDefaults.standard.object(forKey: data.key! + calendar.calendarIdentifier) as? Bool
							?? (data.defaultValue as? Bool ?? false) {
							res += 1
						}
						return res
					}
					if let n = n {
						cell.detailTextLabel?.text = "\(n)"
					} else {
						cell.detailTextLabel?.text = nil
					}
				})
				.disposed(by: cell.disposeBag)
		}
	}

	open func calendar(fromEntityType entityType: EKEntityType) -> EKCalendar? {
		switch entityType {
		case .event:
			return SettingsBundleViewController.eventStore?.defaultCalendarForNewEvents
		case .reminder:
			return SettingsBundleViewController.eventStore?.defaultCalendarForNewReminders()
		default:
			return nil
		}
	}
}
#endif
