//
//  FolderEditorFeature.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct FolderEditorLogic {
	
	@Reducer(state: .equatable)
	enum Destination {
		case discardAlert(AlertState<DiscardAlert>)
		case emptyAlert(AlertState<EmptyAlert>)
		
		enum DiscardAlert {
			case confirmDiscard
			case confirmSave
		}
		
		enum EmptyAlert {
			case confirm
		}
	}
	
	@ObservableState
	struct State: Equatable {
		var folder: Folder
		var name: String
		var focus: Field?
		init(folder: Folder) {
			self.folder = folder
			self.name = folder.name
		}
		@Presents var destination: Destination.State?
		
		enum Field: Hashable {
			case folderName
		}
	}

	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case destination(PresentationAction<Destination.Action>)
		case discardButtonTapped
		case onAppear
		case saveButtonTapped
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.slipBoxClient) var slipBoxClient

	var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .destination(.presented(.discardAlert(.confirmDiscard))):
				state.destination = nil
				return .run { _ in await dismiss() }
				
			case .destination(.presented(.discardAlert(.confirmSave))):
				state.destination = nil
				return .run { [folder = state.folder, updateName = state.name] _ in
					_ = try slipBoxClient.updateFolder(folder, updateName)
					await dismiss()
				}
				
			case .destination(.presented(.emptyAlert(.confirm))):
				state.destination = nil
				return .none
				
			case .destination:
				return .none
				
			case .binding:
				return .none

			case .discardButtonTapped:
				state.destination = .discardAlert(.discard(!state.name.isEmpty))
				return .none
				
			case .onAppear:
				state.focus = .folderName
				return .none

			case .saveButtonTapped:
				guard !state.name.isEmpty else {
					state.destination = .emptyAlert(.empty)
					return .none
				}
				return .run { [folder = state.folder, updateName = state.name] _ in
					_ = try slipBoxClient.updateFolder(folder, updateName)
					await dismiss()
				}
			}
		}
		.ifLet(\.$destination, action: \.destination)
	}
}

public struct FolderEditorView: View {
	@Bindable var store: StoreOf<FolderEditorLogic>
	@FocusState var focus: FolderEditorLogic.State.Field?
	public var body: some View {
		VStack(spacing: 30) {
			Text("Rename Folder")
				.font(.title)
			TextField("Name", text: $store.name)
				.textFieldStyle(.roundedBorder)
				.focused($focus, equals: .folderName)
			HStack(spacing: 30) {
				Button("Discard", role: .destructive) {
					store.send(.discardButtonTapped)
				}
				Button("Save") {
					store.send(.saveButtonTapped)
				}
			}
		}
		.onAppear {
			store.send(.onAppear)
		}
		.bind($store.focus, to: $focus)
	}
}

extension AlertState where Action == FolderEditorLogic.Destination.EmptyAlert {
	static let empty = Self {
		TextState("Folder name can not be empty")
	} actions: {
		ButtonState(role: .cancel, action: .confirm) {
			TextState("OK")
		}
	}
}

extension AlertState where Action == FolderEditorLogic.Destination.DiscardAlert {
	static func discard(_ showSave: Bool) -> Self {
		Self {
			TextState("Discard changes?")
		} actions: {
			ButtonState(role: .destructive, action: .confirmDiscard) {
				TextState("Discard")
			}
			if showSave {
				ButtonState(action: .confirmSave) {
					TextState("Save")
				}
			}
			ButtonState(role: .cancel) {
				TextState("Cancel")
			}
		} message: {
			TextState("Are you sure you want to discard changes for this folder?")
		}
	}
}
