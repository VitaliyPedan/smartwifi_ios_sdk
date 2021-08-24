//
//  SWFNavigator.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import UIKit

protocol SWFNavigator {
    func presentSmartWiFiConnectionAlertViewController(connect: @escaping () -> Void, cancel: @escaping () -> Void)
    func presentSmartWiFiErrorAlertViewController(error: Error)
    func presentSmartWiFiSuccessAlertViewController()
}

extension SWFNavigator {
    
    private var rootViewController: UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }

    func presentSmartWiFiConnectionAlertViewController(
        connect: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        presentAlertViewController(
            message: "WiFi",
            cancelTitle: "Cancel",
            actionTitle: "Connect",
            action: connect,
            cancelAction: cancel
        )
    }
    
    func presentSmartWiFiErrorAlertViewController(error: Error) {
        presentAlertViewController(
            message: error.localizedDescription,
            cancelTitle: "Ok",
            actionTitle: nil,
            action: nil,
            cancelAction: nil
        )
    }
    
    func presentSmartWiFiSuccessAlertViewController() {
        presentAlertViewController(
            message: "Connected!",
            cancelTitle: "Ok",
            actionTitle: nil,
            action: nil,
            cancelAction: nil
        )
    }

    private func presentAlertViewController(
        message: String,
        cancelTitle: String,
        actionTitle: String?,
        action: (() -> Void)?,
        cancelAction: (() -> Void)?
    ) {
        guard let viewController = rootViewController else { return }
        
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: {
                cancelAction?()
            })
        }
        alertController.addAction(cancelAction)

        if let actionTitle = actionTitle {
            let connectAction = UIAlertAction(title: actionTitle, style: .default) { _ in
                action?()
            }
            alertController.addAction(connectAction)
        }
        
        viewController.present(alertController, animated: true)
    }
    
}
