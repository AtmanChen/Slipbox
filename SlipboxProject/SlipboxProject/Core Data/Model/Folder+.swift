//
//  Folder+.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import CoreData
import Foundation

extension Folder: Comparable {
	public static func <(lhs: Folder, rhs: Folder) -> Bool {
		lhs.creationDate < rhs.creationDate
	}
	var name: String {
		get { name_ ?? "" }
		set { name_ = newValue }
	}

	var creationDate: Date {
		creationDate_ ?? Date()
	}

	var notes: Set<Note> {
		get { (notes_ as? Set<Note>) ?? [] }
		set { notes_ = newValue as NSSet }
	}

	var children: Set<Folder> {
		get { (children_ as? Set<Folder>) ?? [] }
		set { children_ = newValue as NSSet }
	}

	convenience init(name: String, context: NSManagedObjectContext) {
		self.init(context: context)
		self.name_ = name
	}

	override public func awakeFromInsert() {
		creationDate_ = Date()
	}

	static func fetch(_ predicate: NSPredicate) -> NSFetchRequest<Folder> {
		let request = Folder.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \Folder.creationDate_, ascending: true)
		]
		request.predicate = predicate
		return request
	}

	static func fetchTopFolder() -> NSFetchRequest<Folder> {
		let predicate = NSPredicate(format: "%K == nil", FolderProperties.parent)
		return fetch(predicate)
	}

	static func delete(folder: Folder) {
		guard let context = folder.managedObjectContext else {
			return
		}
		context.delete(folder)
	}

	// MARK: - Preview

	#if DEBUG
	static func nestedFolderExample(context: NSManagedObjectContext) -> Folder {
		let parent = Folder(name: "parent", context: context)
		let child1 = Folder(name: "child 1", context: context)
		let child2 = Folder(name: "child 2", context: context)
		let child3 = Folder(name: "child 3", context: context)

		parent.children.insert(child1)
		parent.children.insert(child2)
		child2.children.insert(child3)

		return parent
	}

	static func exampleWithNotes(context: NSManagedObjectContext) -> Folder {
		let folder = Folder(name: "my folder", context: context)

		let notes = Note.exampleArray(context: context)
		for note in notes {
			note.folder = folder
		}

		return folder
	}
	#endif
}

enum FolderProperties {
	static let parent = "parent"
	static let children = "children_"
	static let name = "name_"
}
