//
//  ViewController+Documents.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 1/1/20.
//  Copyright © 2020 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit
import SwiftCSV

extension ScoutTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileContents = try? String(contentsOf: urls.first!) else {
            self.Notify(message: "We couldn't read the file you selected.", title: "Error")
            return
        }
        let data = fileContents.data(using: .utf8)!
        var scoutResults: [Scout] = []
        if (urls.first?.pathExtension == "json") {
            let decoder = JSONDecoder()
            do {
                try scoutResults = decoder.decode([Scout].self, from: data)
            } catch {
                self.Notify(message: "We couldn't decode the file you selected.", title: "Error")
                print(error)
                return
            }
        } else if (urls.first?.pathExtension == "csv") {
            do {
                let csv = try CSV(string: fileContents.replacingOccurrences(of: "\r", with: ""))
                for row in csv.namedRows {
                    scoutResults.append(Scout(ScoutID: Int(row["Applicant ID"] ?? "0") ?? 0, FirstName: row["First Name"] ?? "", LastName: row["Last Name"] ?? "", Team: nil, CourseID: nil))
                }
            } catch {
                self.Notify(message: "We couldn't parse the file you selected.", title: "Error")
                print(error)
                return
            }
        }
        self.scouts = scoutResults
        self.tableView.reloadData()
    }
}
