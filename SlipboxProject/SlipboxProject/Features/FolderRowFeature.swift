//
//  FolderRowFeature.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct FolderRowLogic {
	
	@Reducer(state: .equatable)
	enum Destination {
		case deleteConfirmDialog(ConfirmationDialogState<Alert>)
		case editFolder(FolderEditorLogic)
		
		@CasePathable
		enum Alert {
			case confirmCancel
			case confirmDelete
		}
	}
	
	@ObservableState
	struct State: Equatable, Identifiable {
		var folder: Folder
		var focus: Field?
		var name: String
		init(folder: Folder) {
			self.folder = folder
			self.name = folder.name
		}
		@Presents var destination: Destination.State?
		enum Field: Hashable {
			case rename
		}
		var id: UUID {
			folder.uuid
		}
	}

	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case createNewSubFolderButtonTapped
		case deleteButtonTapped
		case destination(PresentationAction<Destination.Action>)
		case renameButtonTapped
		case updateFolderName
	}
	
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.slipBoxClient) var slipBoxClient
	
	var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
				
			case .binding(\.focus):
				if state.focus == nil && state.name != state.folder.name {
					return .send(.updateFolderName)
				}
				return .none
				
			case .binding:
				return .none

			case .createNewSubFolderButtonTapped:
				return .none

			case .deleteButtonTapped:
				state.destination = .deleteConfirmDialog(.deleteFolder)
				return .none
				
			case .destination(.presented(.deleteConfirmDialog(.confirmCancel))):
				state.destination = nil
				return .none
				
			case .destination(.presented(.deleteConfirmDialog(.confirmDelete))):
				state.destination = nil
				return .run { [folder = state.folder] _ in
					let parentId: UUID?
					if let parent = folder.parent {
						parentId = parent.uuid
					} else {
						parentId = nil
					}
					try slipBoxClient.deleteFolder(folder)
					@Shared(.inMemory("refreshLocation")) var refreshLocation: FolderLocation?
					refreshLocation = parentId == nil ? .root : .folder(folderId: parentId!)
				}

			case .destination:
				return .none

			case .renameButtonTapped:
				#if os(OSX)
				state.focus = .rename
				#else
				state.destination = .editFolder(FolderEditorLogic.State(folder: state.folder))
				#endif
				return .none
				
			case .updateFolderName:
				return .run { [folder = state.folder, updateName = state.name] send in
					_ = try slipBoxClient.updateFolder(folder, updateName)
				}
				
			}
		}
		.ifLet(\.$destination, action: \.destination)
	}
}

public struct FolderRow: View {
	@Bindable var store: StoreOf<FolderRowLogic>
	@FocusState var focus: FolderRowLogic.State.Field?
	public var body: some View {
		Group {
			#if os(iOS)
			Text(store.folder.name)
			#else
			TextField("Name", text: $store.name)
				.focused($focus, equals: .rename)
			#endif
		}
		.contextMenu {
			Button("Rename") {
				store.send(.renameButtonTapped)
			}
			Button {
				store.send(.createNewSubFolderButtonTapped)
			} label: {
				Text("Create New Subfolder")
			}
			Divider()
			Button("Delete") {
				store.send(.deleteButtonTapped)
			}
		}
		.confirmationDialog($store.scope(state: \.destination?.deleteConfirmDialog, action: \.destination.deleteConfirmDialog))
		.sheet(item: $store.scope(state: \.destination?.editFolder, action: \.destination.editFolder)) { editStore in
			NavigationStack {
				FolderEditorView(store: editStore)
			}
		}
		.bind($store.focus, to: $focus)
		.onReceive(focus.publisher) { focused in
			
		}
	}
}
				
extension ConfirmationDialogState where Action == FolderRowLogic.Destination.Alert {
	static let deleteFolder = ConfirmationDialogState {
		TextState("Delete Folder?")
	} actions: {
		ButtonState(role: .cancel, action: .confirmCancel) {
			TextState("Cancel")
		}
		ButtonState(role: .destructive, action: .confirmDelete) {
			TextState("Delete")
		}
	} message: {
		TextState("Are you sure to delete this folder?")
	}
}
