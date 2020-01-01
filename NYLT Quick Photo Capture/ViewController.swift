//
//  ViewController.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 11/23/18.
//  Copyright © 2018 Atlanta Area Council NYLT. All rights reserved.
//

import UIKit
import SwiftUI
import MobileCoreServices
import Zip
import SwiftCSV

class ScoutTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    // MARK: Data Source
    var scouts: [Scout] = []
    var filteredScouts = [Scout]()
    func getScouts() {
        self.ShowProgressSpinner(message: "Downloading...")
        CampHubScouts().get(withCompletion: {(scoutResults: [Scout]?) -> Void in
            self.dismiss(animated: true, completion: nil)
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
        navigationController?.navigationBar.prefersLargeTitles = true
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
    
    // MARK: Sorting stuff
    func sortScouts(sortMethod: SortField) {
        switch sortMethod {
        case .Course:
            sortBothArrays { (a, b) -> Bool in
                return a.CourseID ?? 0 < b.CourseID ?? 0
            }
        case .FirstName:
            sortBothArrays { (a, b) -> Bool in
                return a.FirstName.lowercased() < b.FirstName.lowercased()
            }
        case .LastName:
            sortBothArrays { (a, b) -> Bool in
                return a.LastName.lowercased() < b.LastName.lowercased()
            }
        case .Team:
            sortBothArrays { (a, b) -> Bool in
                return a.Team?.lowercased() ?? "" < b.Team?.lowercased() ?? ""
            }
        default:
            break
        }
        tableView.reloadData()
    }
    
    func sortBothArrays(sortFunc: (Scout, Scout) -> Bool) {
        scouts.sort(by: sortFunc)
        filteredScouts.sort(by: sortFunc)
    }
    
    @IBAction func chooseSortMethod(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "First Name", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.sortScouts(sortMethod: .FirstName)
        }))
        alert.addAction(UIAlertAction(title: "Last Name", style: .default, handler:{(action: UIAlertAction) -> Void in
            self.sortScouts(sortMethod: .LastName)
        }))
        alert.addAction(UIAlertAction(title: "Team", style: .default, handler:{(action: UIAlertAction) -> Void in
            self.sortScouts(sortMethod: .Team)
        }))
        alert.addAction(UIAlertAction(title: "Course", style: .default, handler:{(action: UIAlertAction) -> Void in
            self.sortScouts(sortMethod: .Course)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    /// MARK: Course Filtering
    
    // MARK: Image stuff
    func createScoutMenu(scout: Scout) -> UIMenu {
        let library = UIAction(title: "Existing Photo", image: UIImage(systemName: "photo.on.rectangle")) {action in
            self.takePhotoOrVideo(scout: scout, source: .photoLibrary, type: .photo)
        }
        let video = UIAction(title: "Video", image: UIImage(systemName: "video")) {action in
            self.takePhotoOrVideo(scout: scout, source: .camera, type: .video)
        }
        
        return UIMenu(title: "Other Capture Options", children: [library, video])
    }
    
    func clearDocuments() {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Notify(message: "We encountered an issue deleting all photos.", title: "Error")
            return
        }
        let items = try? fileManager.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)
        items?.forEach {item in
            try? fileManager.removeItem(at: item)
        }
        Notify(message: "All photos deleted.", title: "Deletion Complete")
    }
    
    func prepareUploadImage() {
        var uploadScouts = [Scout]()
        let documentsURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        for scout in scouts {
            let path = documentsURL.appendingPathComponent(scout.fileName() + ".jpg")
            if (FileManager().fileExists(atPath: path.path)) {
                uploadScouts.append(scout)
            }
        }
        if (uploadScouts.count > 0) {
            self.ShowProgressSpinner(message: "Uploading...")
            uploadImageRecursive([Bool](), uploadScouts: uploadScouts)
        } else {
            self.Notify(message: "No scouts to upload.", title: "Upload Aborted")
            
        }
    }
    
    func uploadImageRecursive(_ uploadResults: [Bool], uploadScouts: [Scout]) {
        var uploadResults = uploadResults
        var uploadScouts = uploadScouts
        let scout = uploadScouts.popLast()!
        let documentsURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = documentsURL.appendingPathComponent(scout.fileName() + ".jpg")
        CampHubScouts().upload(ScoutID: scout.ScoutID, image: UIImage(contentsOfFile: path.path)!, withCompletion: {(results: Any?) -> Void in
            uploadResults.append(results != nil)
            if (uploadScouts.count > 0) {
                self.uploadImageRecursive(uploadResults, uploadScouts: uploadScouts)
            } else {
                self.uploadImageComplete(uploadResults: uploadResults)
            }
        })
    }
    
    func uploadImageComplete(uploadResults: [Bool]) {
        self.dismiss(animated: true, completion: {() -> Void in
            let failures = uploadResults.filter {$0 == false}.count
            let message = failures > 0 ? "There were \(failures) failures out of \(uploadResults.count) uploads." : "Total success!"
            self.Notify(message: message, title: "Upload Complete")
        })
    }
    
    // MARK: document stuff
    func openFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeJSON), String(kUTTypeCommaSeparatedText)], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true)
    }
    
    func saveZip(_ sender: UIBarButtonItem, zipType: CaptureType) {
        self.ShowProgressSpinner(message: "Creating ZIP file...")
        var scoutImagePaths = [URL]()
        let documentsURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        for scout in scouts {
            let path = zipType == .Video ? documentsURL.appendingPathComponent(scout.fileName() + ".mp4") : documentsURL.appendingPathComponent(scout.fileName() + ".jpg")
            if (FileManager().fileExists(atPath: path.path)) {
                scoutImagePaths.append(path)
            }
        }
        guard let zipFilePath = try? Zip.quickZipFiles(scoutImagePaths, fileName: "CampHub Images") else {
            Notify(message: "We encountered an issue created a file for export.", title: "Error")
            return
        }
        let shareSheet = UIActivityViewController(activityItems: [zipFilePath], applicationActivities: nil)
        shareSheet.popoverPresentationController?.barButtonItem = sender
        self.dismiss(animated: true, completion: {() -> Void in
            self.present(shareSheet, animated: true)
        })
    }
    
    // MARK: menus
    @IBAction func showExportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Export", message: "Export the photos you've taken online or locally in a file.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save Photos to File", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.saveZip(sender, zipType: .Photo)
        }))
        alert.addAction(UIAlertAction(title: "Save Videos to File", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.saveZip(sender, zipType: .Video)
        }))
        alert.addAction(UIAlertAction(title: "Upload to CampHub", style: .default, handler: {(action: UIAlertAction) -> Void in
            self.prepareUploadImage()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    @IBAction func showImportMenu(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Load Scouts", message: "Populate the app with scouts. NOTE: this will replace any scouts already in the app.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Open File", style: .default, handler: {action in
            self.openFile()
        }))
        alert.addAction(UIAlertAction(title: "Download from CampHub", style: .default, handler:{action in
            self.getScouts()
        }))
        alert.addAction(UIAlertAction(title: "Clear Existing Photos", style: .destructive, handler: {action in
            self.AskYesNo(message: "Are you sure you want to delete all existing photos? This will also clear any other documents stored in this app's folder, and cannot be undone.", title: "Warning", withCompletion: {(result: Bool) -> Void in
                if (result) {
                    self.clearDocuments()
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    @IBSegueAction func loadAddScoutModal(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: AddScout())
    }
    
    
}
