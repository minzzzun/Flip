//
//  FolderChipBar.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct FolderChipBar: View {
    let folders: [FolderDTO]
    let selectedFolderId: UUID?
    let onSelectAll: () -> Void
    let onSelectFolder: (UUID) -> Void
    let onManageFolders: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FolderChip(
                    title: "전체",
                    isSelected: selectedFolderId == nil,
                    onTap: onSelectAll
                )

                ForEach(folders) { folder in
                    FolderChip(
                        title: folder.name,
                        isSelected: selectedFolderId == folder.id,
                        onTap: { onSelectFolder(folder.id) }
                    )
                }
//TODO: 나중에 삭제 
//                Button(action: onManageFolders) {
//                    Image(systemName: "gearshape")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 6)
//                        .background(
//                            Capsule()
//                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                        )
//                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}
