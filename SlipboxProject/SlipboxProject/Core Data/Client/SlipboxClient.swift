//
//  CoreDataClient.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation
import Dependencies

struct SlipboxClient {
	var fetchTopFolders: @Sendable () throws -> [Folder]
	var fetchFolder: @Sendable (NSPredicate) throws -> [Folder]
	var fetchNotes: @Sendable (NSPredicate) throws -> [Note]
	var fetchNotesInFolder: @Sendable (Folder, Status?) throws -> [Note]
	var addFolder: @Sendable (String, Folder?) throws -> Folder
	var addNote: @Sendable (String, Folder) throws -> Note
	var updateFolder: @Sendable (Folder, String) throws -> Folder
	var deleteFolder: @Sendable (Folder) throws -> Void
	var deleteNote: @Sendable (Note) throws -> Void
	var save: @Sendable () throws -> Void
}

extension SlipboxClient: DependencyKey {
	static let liveValue: SlipboxClient = Self(
		fetchTopFolders: {
			let context = PersistenceController.shared.container.viewContext
			let request = Folder.fetchTopFolder()
			return try context.fetch(request)
		},
		fetchFolder: { predicate in
			let context = PersistenceController.shared.container.viewContext
			let request = Folder.fetch(predicate)
			return try context.fetch(request)
		},
		fetchNotes: { predicate in
			let context = PersistenceController.shared.container.viewContext
			let request = Note.fetch(predicate)
			return try context.fetch(request)
		},
		fetchNotesInFolder: { folder, status in
			let context = PersistenceController.shared.container.viewContext
			let request = Note.fetch(for: folder, status: status)
			return try context.fetch(request)
		},
		addFolder: { folderName, parent in
			@Dependency(\.uuid) var uuid
			let context = PersistenceController.shared.container.viewContext
			let folder = Folder(id: uuid(), name: folderName, context: context)
			folder.parent = parent
			PersistenceController.shared.save()
			return folder
		},
		addNote: { noteTitle, folder in
			let context = PersistenceController.shared.container.viewContext
			@Dependency(\.uuid) var uuid
			let note = Note(id: uuid(), title: noteTitle, context: context)
			note.folder = folder
			PersistenceController.shared.save()
			return note
		},
		updateFolder: { folder, updateName in
			guard let context = folder.managedObjectContext else {
				return folder
			}
			folder.name = updateName
			PersistenceController.shared.save()
			return folder
		},
		deleteFolder: { folder in
			Folder.delete(folder: folder)
			PersistenceController.shared.save()
		},
		deleteNote: { note in
			Note.delete(note: note)
			PersistenceController.shared.save()
		},
		save: {
			PersistenceController.shared.save()
		}
	)
}

extension DependencyValues {
	var slipBoxClient: SlipboxClient {
		get { self[SlipboxClient.self] }
		set { self[SlipboxClient.self] = newValue }
	}
}
