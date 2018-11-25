//
//  ViewController.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 11/23/18.
//  Copyright © 2018 Atlanta Area Council NYLT. All rights reserved.
//
 
import UIKit
import MobileCoreServices
import Zip

class ScoutTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    // MARK: Data Source
    var scouts: [Scout] = []
    var filteredScouts = [Scout]()
    func getScouts() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CampHubScouts().get(withCompletion: {(scoutResults: [Scout]?) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if (scoutResults == nil) {
                self.Notify(message: "We weren't able to load scouts - make sure you have an internet connection.", title: "Error")
            } else {
                self.scouts = scoutResults!
                self.tableView.reloadData()
            }
        })
    }
    
    var imagePicker: UIImagePickerController!
    var selectedScout: Scout!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter Scouts"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: Search stuff
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredScouts = scouts.filter({( scout : Scout) -> Bool in
            return scout.FirstName.lowercased().contains(searchText.lowercased()) || scout.LastName.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    // MARK: Image stuff
    func takePhoto(scout: Scout) {
        selectedScout = scout;
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: document stuff
    func openJson() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeJSON)], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true)
    }
    
    // MARK: menus
    @IBAction func showExportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Export", message: "Export the photos you've taken online or locally in a file.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save to File", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Upload to CampHub", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    @IBAction func showImportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Load Scouts", message: "Populate the app with scouts. NOTE: this will replace any scouts already in the app.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Open File", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.openJson()
        }))
        alert.addAction(UIAlertAction(title: "Download from CampHub", style: .default, handler:{(action: UIAlertAction) -> Void in
            self.getScouts()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    // MARK: general utils
    func Notify(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

// MARK: document stuff
extension ScoutTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileContents = try? String(contentsOf: urls.first!) else {
            self.Notify(message: "We couldn't read the file you selected.", title: "Error")
            return
        }
        let data = fileContents.data(using: .utf8)!
        let decoder = JSONDecoder()
        //        guard let scoutResults = try? decoder.decode([Scout].self, from: data) else {
        //            self.Notify(message: "We couldn't decode the file you selected.", title: "Error")
        //            return
        //        }
        var scoutResults: [Scout] = []
        do {
            try scoutResults = decoder.decode([Scout].self, from: data)
        } catch {
            self.Notify(message: "We couldn't decode the file you selected.", title: "Error")
            print(error)
            return
        }
        self.scouts = scoutResults
        self.tableView.reloadData()
    }
}

// MARK: image stuff
extension ScoutTableViewController: UIImagePickerControllerDelegate {
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
}

// MARK: table stuff
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
        let scoutUnit = scout.CourseID != nil ? scout.CourseID! % 2 == 0 ? "Blue" : "Red" : nil
        cell.textLabel?.text = scout.FirstName + " " + scout.LastName
        cell.detailTextLabel?.text = scout.Team != nil && scoutUnit != nil ? scoutUnit! + " - " + scout.Team! : nil
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scout = isFiltering() ? filteredScouts[indexPath.row] : scouts[indexPath.row];
        takePhoto(scout: scout)
    }
}

// MARK: search stuff
extension ScoutTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}


struct Scout: Codable {
    var ScoutID: Int
    var FirstName: String
    var LastName: String
    var Team: String?
    var CourseID: Int?
}

