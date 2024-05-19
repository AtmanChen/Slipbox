//
//  PersistenceController.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation
import CoreData
import Dependencies

struct PersistenceController {
	static let shared = PersistenceController()
	let container: NSPersistentCloudKitContainer
	private init(inMemory: Bool = false) {
		container = NSPersistentCloudKitContainer(name: "Slipbox")
		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(filePath: "/dev/null")
		}
		container.loadPersistentStores { storeDescription, error in
			if let error = error as? NSError {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		}
		container.viewContext.automaticallyMergesChangesFromParent = true
	}
	func save() {
		let context = container.viewContext
		guard context.hasChanges else {
			return
		}
		do {
			try context.save()
		} catch {
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	// MARK: - Preview
	#if DEBUG
	static let preview: PersistenceController = {
		let controller = PersistenceController(inMemory: true)
		let context = controller.container.viewContext
		for index in 0 ..< 10 {
			@Dependency(\.uuid) var uuid
			let newNote = Note(id: uuid(), title: "note_\(index)", context: context)
			newNote.creationDate_ = Date() + TimeInterval(index)
			_ = Folder(name: "folder_\(index)", context: context)
		}
		return controller
	}()
	static func createEmpty() -> PersistenceController {
		PersistenceController(inMemory: true)
	}
	#endif
}
