//
//  WaterfallCollectionView.swift
//  Flip
//
//  Created by 김민준 on 2/9/26.
//

import SwiftUI
import UIKit
import Dependencies

struct WaterfallCollectionView: UIViewRepresentable {
    let entries: [EntryDTO]
    let numberOfColumns: Int
    let onTap: (EntryDTO) -> Void
    let onDelete: (EntryDTO) -> Void
    let onMoveToFolder: (EntryDTO) -> Void

    func makeUIView(context: Context) -> UICollectionView {
        let layout = WaterfallLayout()
        layout.configure(numberOfColumns: numberOfColumns, cellPadding: 6)
        layout.delegate = context.coordinator

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(EntryCardCell.self, forCellWithReuseIdentifier: EntryCardCell.reuseIdentifier)

        // 롱프레스 제스처 추가
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.entries = entries
        context.coordinator.parent = self

        // 레이아웃 업데이트
        if let layout = collectionView.collectionViewLayout as? WaterfallLayout {
            layout.configure(numberOfColumns: numberOfColumns, cellPadding: 6)
        }

        collectionView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, entries: entries)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, WaterfallLayoutDelegate {
        var parent: WaterfallCollectionView
        var entries: [EntryDTO]
        private var imageCache: [UUID: UIImage] = [:]

        init(_ parent: WaterfallCollectionView, entries: [EntryDTO]) {
            self.parent = parent
            self.entries = entries
        }

        // MARK: - UICollectionViewDataSource

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return entries.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EntryCardCell.reuseIdentifier,
                for: indexPath
            ) as? EntryCardCell else {
                return UICollectionViewCell()
            }

            let entry = entries[indexPath.item]

            // 캐시에서 이미지 확인
            if let cachedImage = imageCache[entry.id] {
                cell.configure(with: cachedImage)
            } else {
                // 비동기로 이미지 로드
                cell.configure(with: nil)
                Task { @MainActor in
                    @Dependency(\.imageStoreClient) var imageStoreClient
                    if let image = try? await imageStoreClient.loadImage(entry.thumbPath ?? entry.imagePath) {
                        self.imageCache[entry.id] = image
                        if let currentCell = collectionView.cellForItem(at: indexPath) as? EntryCardCell {
                            currentCell.configure(with: image)
                        }
                    }
                }
            }

            return cell
        }

        // MARK: - UICollectionViewDelegate

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let entry = entries[indexPath.item]
            parent.onTap(entry)
        }

        func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            let entry = entries[indexPath.item]

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let moveAction = UIAction(title: "폴더 이동", image: UIImage(systemName: "folder")) { [weak self] _ in
                    self?.parent.onMoveToFolder(entry)
                }

                let deleteAction = UIAction(title: "삭제", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    self?.parent.onDelete(entry)
                }

                return UIMenu(title: "", children: [moveAction, deleteAction])
            }
        }

        // MARK: - WaterfallLayoutDelegate

        func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, width: CGFloat) -> CGFloat {
            let entry = entries[indexPath.item]

            // 이미지 크기 정보가 있으면 비율 계산
            if let imageWidth = entry.imageWidth,
               let imageHeight = entry.imageHeight,
               imageWidth > 0 {
                let aspectRatio = imageHeight / imageWidth
                return width * aspectRatio
            }

            // 기본값: 정사각형
            return width
        }

        // MARK: - Long Press Gesture

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let collectionView = gesture.view as? UICollectionView else { return }

            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                let entry = entries[indexPath.item]
                // 햅틱 피드백
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}
