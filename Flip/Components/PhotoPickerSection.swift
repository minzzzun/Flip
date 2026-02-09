//
//  PhotoPickerSection.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import PhotosUI

struct PhotoPickerSection: View {
    let selectedImage: UIImage?
    let isLoading: Bool
    @Binding var photosPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay { ProgressView() }
            }

            PhotosPicker(
                selection: $photosPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    selectedImage == nil ? "사진 선택" : "사진 변경",
                    systemImage: "photo.on.rectangle"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
        }
    }
}
