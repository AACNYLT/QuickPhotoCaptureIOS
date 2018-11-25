//
//  ServerOperations.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 11/24/18.
//  Copyright © 2018 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation

class CampHubScouts {
    let url = URL(string: "https://nyltcamphub.azurewebsites.net/scouts")
    
    func get(withCompletion completion: @escaping ([Scout]?) -> Void) {
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)
        let task = session.dataTask(with: self.url!, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            guard let scouts = try? decoder.decode([Scout].self, from: data) else {
                completion(nil)
                return
            }
            completion(scouts)
            return
        })
        task.resume()
    }
}
