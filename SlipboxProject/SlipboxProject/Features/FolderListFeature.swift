//
//  FolderListFeature.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct FolderListLogic {
	
	@ObservableState
	struct State: Equatable {
		@Shared(.inMemory("selectedFolder")) var selectedFolder: Folder?
		var folders: IdentifiedArrayOf<RecursiveFolderLogic.State> = []
	}
	
	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case createNewFolderButtonTapped
		case folders(IdentifiedActionOf<RecursiveFolderLogic>)
		case onAppear
		case updateFolders([Folder])
		case updateSelectedFolder(Folder)
	}
	
	@Dependency(\.slipBoxClient) var slipBoxClient
	var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
				
			case .createNewFolderButtonTapped:
				return .run { send in
					let folder = try slipBoxClient.addFolder("New Folder")
					await send(.updateSelectedFolder(folder))
				}
				
			case .folders:
				return .none
				
			case .onAppear:
				return .run { send in
					let topFolders = try slipBoxClient.fetchTopFolders()
					await send(.updateFolders(topFolders))
				}
				
			case let .updateFolders(folders):
				state.folders = IdentifiedArray(uniqueElements: folders.map(RecursiveFolderLogic.State.init(folder:)))
				return .none
				
			case let .updateSelectedFolder(folder):
				state.selectedFolder = folder
				return .none
			}
		}
		.forEach(\.folders, action: \.folders) {
			RecursiveFolderLogic()
		}
	}
}

struct FolderListView: View {
	@Bindable var store: StoreOf<FolderListLogic>
	@FetchRequest(fetchRequest: Folder.fetchTopFolder()) private var folders: FetchedResults<Folder>
	var body: some View {
		List(selection: $store.selectedFolder) {
			ForEachStore(store.scope(state: \.folders, action: \.folders)) { folderStore in
				RecursiveFolderView(store: folderStore)
			}
			.onDelete { indexSet in
				
			}
		}
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Button{
					store.send(.createNewFolderButtonTapped)
				} label: {
					Label("Create new folder", systemImage: "folder.badge.plus")
				}
			}
		}
		.onAppear {
			store.send(.onAppear)
		}
		.onReceive(folders.publisher) { _ in
			store.send(.onAppear)
		}
	}
}
