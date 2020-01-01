//
//  ViewController+Utils.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 1/1/20.
//  Copyright © 2020 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit

extension ScoutTableViewController {
    func Notify(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func AskYesNo(message: String, title: String, withCompletion completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction) -> Void in
            completion(true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {(action: UIAlertAction) -> Void in
            completion(false)
        }))
        self.present(alert, animated: true)
    }
    
    func ShowProgressSpinner(message: String) {
        let progressPopup = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let progressSpinner = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        progressSpinner.hidesWhenStopped = true
        progressSpinner.style = UIActivityIndicatorView.Style.medium
        progressSpinner.startAnimating()
        
        progressPopup.view.addSubview(progressSpinner)
        present(progressPopup, animated: true)
    }
}
