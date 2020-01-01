//
//  ViewController+ImagePicker.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 1/1/20.
//  Copyright © 2020 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

extension ScoutTableViewController: UIImagePickerControllerDelegate {
    func takePhotoOrVideo(scout: Scout, source: UIImagePickerController.SourceType, type: UIImagePickerController.CameraCaptureMode) {
        selectedScout = scout
        imagePicker =  UIImagePickerController()
        if (type == .video) {
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.videoQuality = .typeLow
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        if (info[.mediaType] as! CFString == kUTTypeImage) {
            let imagePath = documentsPath?.appendingPathComponent(selectedScout.fileName() + ".jpg")
            if let takenImage = info[.editedImage] as? UIImage {
                if (UserDefaults.standard.bool(forKey: "photosinlibrary")) {
                    UIImageWriteToSavedPhotosAlbum(takenImage, self, nil, nil)
                }
                try? takenImage.jpegData(compressionQuality: 0.5)?.write(to: imagePath!)
                self.tableView.reloadData()
            } else {
                return
            }
        } else {
            let videoPath = documentsPath?.appendingPathComponent(selectedScout.fileName() + ".mp4")
            if let videoURL = info[.mediaURL] as? URL {
                if (UserDefaults.standard.bool(forKey: "videosinlibrary")) {
                    UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath, self, nil, nil)
                }
                let videoData = try? Data(contentsOf: videoURL)
                try? videoData?.write(to: videoPath!)
                self.tableView.reloadData()
            } else {
                return
            }
        }
    }
}
