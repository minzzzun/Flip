//
//  FolderManageRowView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import Foundation
import UIKit

struct FolderManageRowView: View {
    let name: String
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
            Text(name)
                .font(.body)
            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label("이름 변경", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
            Button {
                onRename()
            } label: {
                Label("이름 변경", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }
}
