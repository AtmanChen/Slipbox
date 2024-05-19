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
		var showSubFolder = false
		init(folder: Folder) {
			self.folder = folder
		}
		var id: String {
			folder.name
		}
	}
	
	indirect enum Action {
		case folder(FolderRowLogic.Action)
		case subFolders(IdentifiedActionOf<RecursiveFolderLogic>)
		case toggleSubFolder
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .folder:
				return .none
				
			case .toggleSubFolder:
				state.showSubFolder.toggle()
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
	var body: some View {
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
					store.send(.toggleSubFolder)
				} label: {
					Image(systemName: "chevron.right")
						.rotationEffect(Angle(degrees: store.showSubFolder ? 90 : 0))
				}
			} else {
				Color.clear
			}
		}
		
		if store.showSubFolder {
			ForEachStore(store.scope(state: \.subFolders, action: \.subFolders)) { subFolderStore in
				RecursiveFolderView(store: subFolderStore)
					.padding(.leading)
			}
			.onDelete { indexSet in
				
			}
		}
	}
}
