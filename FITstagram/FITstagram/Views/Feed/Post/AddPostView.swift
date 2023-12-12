//
//  AddPostView.swift
//  FITstagram
//
//  Created by Guest User on 12/12/23.
//

import SwiftUI

struct AddPostView: View {
    @State var image: Image?
    @State var imageModel: PostViewModel?
    @State var description: String = ""
    @State var isImagePickerPresented = false
    @State var errorAlert = false
    @State var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        VStack (alignment: .leading) {
            Rectangle()
                .fill(Color(UIColor.white))
                .aspectRatio(contentMode: .fit)
                .overlay {
                    if let currentImage = image {
                        currentImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            TextField("Add description", text: $description)
                .autocorrectionDisabled()
                .padding(.top, 10)
                .padding(.leading, 10)
                .padding(.trailing, 10)
//            Spacer()
        }
        .toolbar {
            Button {
                Task {
                    await addPost()
                    sleep(1)
                    dismiss()
                }
            } label: {
                Image(systemName: "paperplane")
            }
            .alert("Failed to upload image: " + errorMessage, isPresented: $errorAlert) {
                Button("Cancel", role: .cancel) {
                    errorAlert = false
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
            .overlay(
                Button {
                    isImagePickerPresented = true
                } label: {
                    Image(systemName: (image == nil) ? "plus" : "pencil")
                        .padding()
                }
            )
            .fullScreenCover(isPresented: $isImagePickerPresented, content: {
                ImagePicker(
                    sourceType: UIImagePickerController.SourceType.photoLibrary,
                    image: $image,
                    isPresented: $isImagePickerPresented
                )
            })
        
    }
        
        // MARK: - Private Helpers
        @MainActor
        func addPost() async {
            let encodedImage = getCroppedImage()?.jpegData(compressionQuality: 1)?.base64EncodedString()
            guard let jsonData = try? JSONEncoder().encode(AddPostModel(encodedImage: encodedImage!, description: description)) else {
                print("Failed to encode")
                return
            }
            let url = URL(string: "https://fitstagram.ackee.cz/api/feed")!
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = ["Authorization": myUsername]
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = jsonData
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                errorMessage = (response as? HTTPURLResponse)?.description ?? ""
            } catch {
                errorAlert = true
            }
        }
        
        @MainActor
        func getCroppedImage() -> UIImage? {
            let croppedImage = image!.resizable()
                .scaledToFill()
                .frame(width: 2048/UIScreen.main.scale, height: 2048/UIScreen.main.scale)
                .clipped()
            return ImageRenderer(content: croppedImage).uiImage
        }
        
        class AddPostModel : Codable {
            var photos : [String]
            var text: String
            
            init(encodedImage : String, description: String) {
                self.photos = [encodedImage]
                self.text = description
            }
        }
    }


#Preview {
    AddPostView()
}
