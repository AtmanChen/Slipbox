//
//  Status.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation

enum Status: String, Identifiable, CaseIterable {
	case draft = "Draft"
	case review = "Review"
	case archived = "Archived"
	var id: String {
		rawValue
	}
}
