//
//  SettingsViewController+Product.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/21.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import StoreKit
import RxSwift
import RxCocoa

extension SettingsViewController: SKProductsRequestDelegate {

	open func startRequestProducts() {
		SKPaymentQueue.default().transactions.forEach() { transaction in
			if transaction.transactionState == .failed {
				// Delete if failed
				SKPaymentQueue.default().finishTransaction(transaction)
			}
		}

		// Collect Product ID
		var productIdentifiers = [String]()
		cellArray?.forEach {
			if $0.specifierType?.contains("Product") ?? false, let title = $0.string("ProductIdentifier") {
				productIdentifiers += [title]
			}
			productIdentifiers += $0.childData.compactMap {
				($0.specifierType?.contains("Product") ?? false) ? $0.string("ProductIdentifier") : nil
			}
		}

		// Unique
		productIdentifiers = productIdentifiers.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }

		// Request
		if productIdentifiers.count > 0 {
			startIndicator()
			products.accept(nil)
			let request = SKProductsRequest(productIdentifiers: Set<String>(productIdentifiers))
			request.delegate = self
			request.start()

			products.asObservable()
				.observeOn(MainScheduler.instance)
				.subscribe(onNext: { [weak self] products in
					self?.tableView?.beginUpdates()
					self?.cellArray?.enumerated().forEach { i, data in
						if let productIdentifier = data.string("ProductIdentifier") {
							let product = products?.filter({ $0.productIdentifier == productIdentifier }).first
							self?.cellArray?[i].overwriteFooterText = product?.localizedDescription
						}
					}
					self?.tableView?.endUpdates()
				})
				.disposed(by: disposeBag)
		}
	}

	open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		stopIndicator()
		products.accept(response.products)
	}

	open func request(_ request: SKRequest, didFailWithError error: Error) {
		stopIndicator()
		products.accept([])
	}

	// ProductButton
	open func updateCellProductButton(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		products.asObservable()
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: { [weak self] products in
				if let products = products {
					if let product = products.filter({ $0.productIdentifier == data.string("ProductIdentifier") }).first {
						cell.textLabel?.text = product.localizedTitle
						let priceFormatter = NumberFormatter()
						priceFormatter.formatterBehavior = .behavior10_4
						priceFormatter.numberStyle = .currency
						priceFormatter.locale = product.priceLocale
						cell.detailTextLabel?.text = priceFormatter.string(from: product.price)
					} else {
						cell.textLabel?.text = self?.localized(data.string("NoItemText"))
						cell.detailTextLabel?.text = nil
					}
				} else {
					cell.textLabel?.text = self?.localized(data.string("RequestText"))
					cell.detailTextLabel?.text = nil
				}
			})
			.disposed(by: cell.disposeBag)
	}

}
