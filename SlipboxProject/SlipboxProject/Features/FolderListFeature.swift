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
		@Shared(.inMemory("refreshLocation")) var refreshLocation: FolderLocation?
		var folders: IdentifiedArrayOf<RecursiveFolderLogic.State> = []
	}
	
	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case createNewFolderButtonTapped
		case fetchTopFolders
		case folders(IdentifiedActionOf<RecursiveFolderLogic>)
		case updateRefreshLocation(FolderLocation)
		case onAppear
		case updateFolders([Folder])
		case updateSelectedFolder(Folder?)
	}
	
	@Dependency(\.slipBoxClient) var slipBoxClient
	
	var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
				
			case .createNewFolderButtonTapped:
				return .run { [selectedFolder = state.selectedFolder] send in
					let folder = try slipBoxClient.addFolder("New Folder", selectedFolder)
					@Shared(.inMemory("refreshLocation")) var refreshLocation: FolderLocation?
					refreshLocation = selectedFolder == nil ? FolderLocation.root : FolderLocation.folder(folderId: selectedFolder!.uuid)
//					await send(.updateSelectedFolder(folder))
				}
				
			case .fetchTopFolders:
				return .run { send in
					let topFolders = try slipBoxClient.fetchTopFolders()
					await send(.updateFolders(topFolders))
				}
				
			case .folders:
				return .none
				
			case .onAppear:
				return .publisher {
					state.$refreshLocation.publisher
						.prepend(FolderLocation.root)
						.filter { $0 == FolderLocation.root }
						.receive(on: DispatchQueue.main)
						.map { _ in Action.fetchTopFolders }
				}
				
			case let .updateFolders(folders):
				if folders.isEmpty {
					state.folders.removeAll()
				} else {
					for folder in folders {
						if state.folders[id: folder.uuid] == nil {
							state.folders.append(RecursiveFolderLogic.State(folder: folder))
						}
					}
				}
				return .none
				
			case let .updateRefreshLocation(location):
				switch location {
				case .root:
					return .none
					
				case let .folder(id):
					return .none
				}
				
			case let .updateSelectedFolder(folder):
				state.selectedFolder = folder
				debugPrint("update selectedFolder \(folder)")
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
		.onReceive(folders.publisher) { param in
//			store.send(.onAppear)
		}
	}
}
