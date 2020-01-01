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
    func takePhotoOrVideo(scout: Scout, source: UIImagePickerController.SourceType, type: UIImagePickerController.CameraCaptureMode) {
        selectedScout = scout
        imagePicker =  UIImagePickerController()
        if (type == .video) {
            imagePicker.mediaTypes = [kUTTypeMovie as String]
        } else {
            imagePicker.mediaTypes = [kUTTypeImage as String]
        }
        imagePicker.delegate = self
        imagePicker.sourceType = source
        imagePicker.allowsEditing = (type != .video)
        if (source != .photoLibrary) {
            imagePicker.cameraCaptureMode = type
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
    func createScoutMenu(scout: Scout) -> UIMenu {
        let library = UIAction(title: "Existing Photo", image: UIImage(systemName: "photo.on.rectangle")) {action in
            self.takePhotoOrVideo(scout: scout, source: .photoLibrary, type: .photo)
        }
        let video = UIAction(title: "Video", image: UIImage(systemName: "video")) {action in
            self.takePhotoOrVideo(scout: scout, source: .camera, type: .video)
        }
        
        return UIMenu(title: "Other Capture Options", children: [library, video])
    }
    
    //    func showScoutMenu(scout: Scout) -> Void {
    //        let alert = UIAlertController(title: scout.FirstName + " " + scout.LastName, message: "Choose an option below", preferredStyle: .actionSheet)
    //        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {action in
    //            self.takePhoto(scout: scout, source: .camera)
    //        }))
    //        alert.addAction(UIAlertAction(title: "Existing Photo", style: .default, handler:{action in
    //            self.takePhoto(scout: scout, source: .photoLibrary)
    //        }))
    //        alert.addAction(UIAlertAction(title: "Take Video", style: .default, handler: {action in
    //
    //        }))
    //        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    //        alert.popoverPresentationController?.barButtonItem = sender
    //        self.present(alert, animated: true)
    //    }
    
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
}

// MARK: document picker extension
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

// MARK: image picker extension
extension ScoutTableViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        if (info[.mediaType] as! CFString == kUTTypeImage) {
            let imagePath = documentsPath?.appendingPathComponent(selectedScout.fileName() + ".jpg")
            if let takenImage = info[.editedImage] as? UIImage {
                try? takenImage.jpegData(compressionQuality: 0.5)?.write(to: imagePath!)
                self.tableView.reloadData()
            } else {
                return
            }
        } else {
            let videoPath = documentsPath?.appendingPathComponent(selectedScout.fileName() + ".mp4")
            if let videoURL = info[.mediaURL] as? URL {
                UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath, self, nil, nil)
                let videoData = try? Data(contentsOf: videoURL)
                try? videoData?.write(to: videoPath!)
                self.tableView.reloadData()
            } else {
                return
            }
        }
    }
}

// MARK: table extension
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
        let scoutUnit = scout.CourseID != nil ? { () -> String? in
            switch (scout.CourseID! % 10) {
            case 1:
                return "Red"
            case 2:
                return "Blue"
            case 3:
                return "Silver"
            default:
                return nil
            }
            }() : nil
        cell.textLabel?.text = scout.FirstName + " " + scout.LastName
        cell.detailTextLabel?.text = scout.Team != nil && scoutUnit != nil ? scoutUnit! + " - " + scout.Team! : nil
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

// MARK: search stuff
extension ScoutTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
