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
    @IBAction func getScouts() {
        CampHubScouts().get(withCompletion: {(scoutResults: [Scout]?) -> Void in
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
    
    var images: [UIImage] = []
    
    var imagePicker: UIImagePickerController!
    
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
        guard let takenImage = info[.originalImage] as? UIImage else {
            print("Image not found!")
            return
        }
        images.append(takenImage)
    }
    
    // MARK: photo stuff
    func takePhoto(scout: Scout) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
}

struct Scout: Codable {
    var ScoutID: Int
    var FirstName: String
    var LastName: String
}

