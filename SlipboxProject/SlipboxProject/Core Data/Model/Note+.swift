//
//  Note+.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import CoreData
import Foundation
import Dependencies

extension Note {
	var title: String {
		get { title_ ?? "" }
		set { title_ = newValue }
	}

	var creationDate: Date {
		creationDate_ ?? Date()
	}

	var day: String {
		let components = Calendar.current.dateComponents([.year, .month, .day], from: creationDate)
		return "\(components.year!)-\(components.month!)-\(components.day!)"
	}

	var status: Status {
		get {
			if let rawValue = status_,
			   let status = Status(rawValue: rawValue)
			{
				return status
			} else {
				return .draft
			}
		}
		set {
			status_ = newValue.rawValue
		}
	}

	var sectionStatus: String {
		status_ ?? Status.review.rawValue
	}

	var formattedBodyText: NSAttributedString {
		get {
			formattedBodyText_?.toAttributedString() ?? NSAttributedString(string: "")
		}
		set {
			formattedBodyText_ = newValue.toData()
			bodyText_ = newValue.string.lowercased()
		}
	}

	var bodyText: String {
		bodyText_ ?? ""
	}

	convenience init(id: UUID, title: String, context: NSManagedObjectContext) {
		self.init(context: context)
		self.uuid_ = id
		self.title = title
	}

	override public func awakeFromInsert() {
		creationDate_ = Date()
		status = .draft
	}

	static func fetch(_ predicate: NSPredicate = .all) -> NSFetchRequest<Note> {
		let request = NSFetchRequest<Note>(entityName: "Note")
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \Note.creationDate_, ascending: true)
		]
		request.predicate = predicate
		return request
	}

	static func fetch(for folder: Folder, status: Status? = nil) -> NSFetchRequest<Note> {
		let folderPredicate = NSPredicate(format: "%K == %@", NoteProperties.folder, folder)
		if let status {
			let statusPredicate = NSPredicate(format: "%K == %@", NoteProperties.status, status.rawValue as CVarArg)
			let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [folderPredicate, statusPredicate])
			return Note.fetch(predicate)
		} else {
			return Note.fetch(folderPredicate)
		}
	}
	
	static func delete(note: Note) {
		guard let context = note.managedObjectContext else {
			return
		}
		context.delete(note)
	}
	
	// MARK: - Preview
	#if DEBUG
	static func exampleArray(context: NSManagedObjectContext) -> [Note] {
		let calendar = Calendar.current
		let date = Date()
		let notes: [Note] = (0 ..< 10).map { index in
			@Dependency(\.uuid) var uuid
			let newNote = Note(id: uuid(), title: "note_\(index)", context: context)
			newNote.creationDate_ = calendar.date(byAdding: .hour, value: -(index * 10), to: date)
			if index > 6 {
				newNote.status = .review
			} else if index > 3 {
				newNote.status = .archived
			}
			return newNote
		}
		return notes
	}
	static func example() -> Note {
		let context = PersistenceController.preview.container.viewContext
		@Dependency(\.uuid) var uuid
		let note = Note(id: uuid(), title: "my note", context: context)
		note.formattedBodyText = NSAttributedString(string: Note.defaultText)
		
		// TODO: insert keywords
		return note
	}
	
	static let defaultText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
	#endif
}

extension Note: Comparable {
	public static func <(lhs: Note, rhs: Note) -> Bool {
		lhs.creationDate < rhs.creationDate
	}
}

enum NoteProperties {
	static let title = "title_"
	static let bodyText = "bodyText_"
	static let status = "status_"
	static let creationDate = "creationDate_"

	static let folder = "folder"
	static let keywords = "keywords_"
	static let attachment = "attachment"
}
