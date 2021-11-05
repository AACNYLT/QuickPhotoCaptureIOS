//
//  ViewController+TableView.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 1/1/20.
//  Copyright © 2020 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit

extension ScoutTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? filteredScouts.count : scouts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        let scout = isFiltering() ? filteredScouts[indexPath.row] : scouts[indexPath.row]
        cell.textLabel?.text = "\(scout.firstName) \(scout.lastName)"
        cell.detailTextLabel?.text = scout.team != nil && scout.course?.unitName != nil ? "\(scout.course!.unitName) \(scout.team!)" : nil
        // instantiating file manager to pull image from documents library
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath!.appendingPathComponent(scout.fileName() + ".jpg")
        if let imageData = try? Data(contentsOf: imagePath) {
            let scoutImage = UIImage(data: imageData)
            cell.imageView?.image = scoutImage
            cell.imageView?.contentMode = .scaleAspectFill
        } else {
            cell.imageView?.image = nil
        }
        return cell
    }
    
    //    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    //        let libraryAction = UITableViewRowAction(style: .normal, title: "Existing Photo", handler: { (action, selectedIndexPath) in
    //            let scout = self.isFiltering() ? self.filteredScouts[selectedIndexPath.row] : self.scouts[selectedIndexPath.row]
    //            self.takePhoto(scout: scout, source: .photoLibrary)
    //        })
    //        return [libraryAction]
    //    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scout = isFiltering() ? filteredScouts[indexPath.row] : scouts[indexPath.row];
        
        takePhotoOrVideo(scout: scout, source: .camera, type: .photo)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let scout = isFiltering() ? filteredScouts[indexPath.row] : scouts[indexPath.row];
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {suggestedActions in
            
            return self.createScoutMenu(scout: scout)
        })
    }
}
