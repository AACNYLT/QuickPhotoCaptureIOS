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
    var _id: Int
    var firstName: String
    var lastName: String
    var team: String?
    var course: Course?
}

struct Course: Codable {
    var _id: Int
    var unitName: String
    var staff: [Scout]
    var participants: [Scout]
}

enum CaptureType {
    case Photo, Video
}

extension Scout {
    func fileName() -> String {
        return String(self._id)
    }
}

enum SortField {
    case FirstName, LastName, Team, Course, Default
}


class ScoutService {
    func addScouts(scouts: [Scout]) -> Void {
    }
}
