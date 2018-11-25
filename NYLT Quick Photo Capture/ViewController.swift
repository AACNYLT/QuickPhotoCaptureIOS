//
//  ViewController.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 11/23/18.
//  Copyright © 2018 Atlanta Area Council NYLT. All rights reserved.
//

import UIKit

class ScoutTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // MARK: Data Source
    var scouts: [Scout] = []
    func getScouts() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CampHubScouts().get(withCompletion: {(scoutResults: [Scout]?) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if (scoutResults == nil) {
                let alert = UIAlertController(title: "Error", message: "We weren't able to load scouts - make sure you have an internet connection.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            } else {
                self.scouts = scoutResults!
                self.tableView.reloadData()
            }
        })
    }
    
    var imagePicker: UIImagePickerController!
    var selectedScout: Scout!
    
    // MARK: Overrides
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        tableView.tableFooterView = UIView()
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scouts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.textLabel?.text = scouts[indexPath.row].FirstName + " " + scouts[indexPath.row].LastName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scout = scouts[indexPath.row];
        takePhoto(scout: scout)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath?.appendingPathComponent(selectedScout.FirstName + selectedScout.LastName + "-" + String(selectedScout.ScoutID) + ".jpg")
        if let takenImage = info[.editedImage] as? UIImage {
            try? takenImage.jpegData(compressionQuality: 0.5)?.write(to: imagePath!)
        } else {
            return
        }
    }
    
    // MARK: photo stuff
    func takePhoto(scout: Scout) {
        selectedScout = scout;
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: menus
    
    @IBAction func showExportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Export", message: "Export the photos you've taken online or locally in a file.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Local File", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Upload to CampHub", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    @IBAction func showImportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Load Scouts", message: "Populate the app with scouts.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Local File", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Download from CampHub", style: .default, handler:{(action: UIAlertAction) -> Void in
            self.getScouts()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
}

struct Scout: Codable {
    var ScoutID: Int
    var FirstName: String
    var LastName: String
}

