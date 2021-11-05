//
//  ServerOperations.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 11/24/18.
//  Copyright © 2018 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit

class CampHubScouts {
    let baseURL = "https://nyltcamphub.herokuapp.com/api/"
    
    func get(withCompletion completion: @escaping (Course?) -> Void) {
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)
        let task = session.dataTask(with: URL(string: "\(self.baseURL)/course/")!, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            guard var scouts = try? decoder.decode([Scout].self, from: data) else {
                completion(nil)
                return
            }
            let courseId = UserDefaults.standard.string(forKey: "mincourseid") ?? ""
            completion(scouts)
            return
        })
        task.resume()
    }
    
    func upload(ScoutID: Int, image: UIImage, withCompletion completion: @escaping (Any?) -> Void) {
        let imageURL = URL(string: baseURL + String(ScoutID) + "/image")!
        var request = URLRequest(url: imageURL)
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBody(boundary: boundary, data: image.jpegData(compressionQuality: 0.5)!, mimeType: "image/jpg", name: "scoutImage", filename: String(ScoutID))
        let task = session.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let httpres = response as? HTTPURLResponse else {
                completion(nil)
                return
            }
            print(httpres.statusCode)
            if (error != nil || httpres.statusCode != 200) {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            completion(data)
            return
        })
        task.resume()
    }
    
    func createBody(boundary: String, data: Data, mimeType: String,name: String, filename: String) -> Data {
        let body = NSMutableData()
        let boundaryPrefix = "--\(boundary)\r\n"
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        return body as Data
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
