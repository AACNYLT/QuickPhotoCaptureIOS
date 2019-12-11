//
//  Models.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 12/9/19.
//  Copyright © 2019 Atlanta Area Council NYLT. All rights reserved.
//

import Foundation
import UIKit

struct Scout: Codable {
    var ScoutID: Int
    var FirstName: String
    var LastName: String
    var Team: String?
    var CourseID: Int?
}

enum CaptureType {
    case Photo, Video
}

extension Scout {
    func fileName() -> String {
        return self.FirstName + self.LastName + "-" + String(self.ScoutID)
    }
}

enum SortField {
    case FirstName, LastName, Team, Course, Default
}


class ScoutService {
    func addScouts(scouts: [Scout]) -> Void {
    }
}
