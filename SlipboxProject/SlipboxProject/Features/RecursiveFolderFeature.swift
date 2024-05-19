//
//  RecursiveFolder.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct RecursiveFolderLogic {
	
	@ObservableState
	struct State: Equatable, Identifiable {
		var folder: Folder
		var subFolders: IdentifiedArrayOf<RecursiveFolderLogic.State> = []
		@Shared(.inMemory("refreshLocation")) var refreshLocation: FolderLocation?
		var showSubFolder: Bool
		init(folder: Folder, showSubFolder: Bool = false) {
			self.folder = folder
			self.showSubFolder = showSubFolder
		}
		var id: UUID? {
			folder.uuid_
		}
	}
	
	indirect enum Action {
		case fetchSubFolders
		case folder(FolderRowLogic.Action)
		case onAppear
		case subFolders(IdentifiedActionOf<RecursiveFolderLogic>)
		case toggleSubFolder
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .fetchSubFolders:
				guard state.showSubFolder else {
					return .run { send in
						await send(.toggleSubFolder)
					}
				}
				for subFolder in state.folder.children {
					if state.subFolders[id: subFolder.uuid]?.folder == nil {
						state.subFolders.append(RecursiveFolderLogic.State(folder: subFolder))
					}
				}
				return .none
				
			case .folder:
				return .none
				
			case .onAppear:
				let currentFolderId = state.folder.uuid
				return .publisher { [currentFolderId] in
					state.$refreshLocation.publisher
						.receive(on: DispatchQueue.main)
						.filter { location in
							switch location {
							case let .folder(folderId):
								return folderId == currentFolderId
							default: return false
							}
						}
						.removeDuplicates()
						.map { _ in Action.fetchSubFolders }
				}
				
			case .toggleSubFolder:
				state.showSubFolder.toggle()
				if state.showSubFolder {
					let subFolders = state.folder.children.sorted().map { RecursiveFolderLogic.State(folder: $0) }
					state.subFolders = IdentifiedArray(uniqueElements: subFolders)
				} else {
					state.subFolders = []
				}
				return .none
				
			case .subFolders:
				return .none
			}
		}
		.forEach(\.subFolders, action: \.subFolders) {
			RecursiveFolderLogic()
		}
	}
}

struct RecursiveFolderView: View {
	let store: StoreOf<RecursiveFolderLogic>
	init(store: StoreOf<RecursiveFolderLogic>) {
		self.store = store
		self._subFolders = FetchRequest(fetchRequest: Folder.fetch(NSPredicate(format: "%K == %@", FolderProperties.parent, store.folder as CVarArg)), animation: .bouncy)
	}
	@FetchRequest(fetchRequest: Folder.fetch(.all)) private var subFolders
	var body: some View {
		Group {
			HStack {
				Image(systemName: "folder")
				FolderRow(
					store: Store(
						initialState: FolderRowLogic.State(folder: store.folder),
						reducer: { FolderRowLogic() }
					)
				)
				Spacer()
				if !store.folder.children.isEmpty {
					Button {
						store.send(.toggleSubFolder, animation: .bouncy)
					} label: {
						Image(systemName: "chevron.right")
							.rotationEffect(Angle(degrees: store.showSubFolder ? 90 : 0))
					}
					.buttonStyle(.borderless)
				} else {
					Color.clear
				}
			}
			.tag(store.folder)
			
			if store.showSubFolder {
				ForEachStore(store.scope(state: \.subFolders, action: \.subFolders)) { subFolderStore in
					RecursiveFolderView(store: subFolderStore)
						.padding(.leading)
				}
				.onDelete { indexSet in
					
				}
			}
		}
		.onAppear {
			store.send(.onAppear)
		}
	}
}

#Preview {
	RecursiveFolderView(
		store: Store(
			initialState: RecursiveFolderLogic.State(folder: Folder.nestedFolderExample(context: PersistenceController.preview.container.viewContext)),
			reducer: { RecursiveFolderLogic() }
		)
	)
	.padding()
}
