//
//  TaskStatus.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-29.
//

import Foundation

public enum TaskStatus: Int16, Codable {
    case open
    case completed
    case blocked
}
