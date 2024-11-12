import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var documentPickerPresented = false
    @State private var selectedModelURL: URL?
    @State private var modelEntity: ModelEntity?

    var body: some View {
        VStack {
            Text("Hello, Augmented World!")
                .font(.largeTitle)
                .padding()
            Text("This is a test app I made to fiddle around with visionOS Development.")
                .font(.title)
            
            Button(action: {
                openFilePicker()
            }) {
                Text("Choose 3D Model")
                    .font(.title)
                    .padding()
            }
            .sheet(isPresented: $documentPickerPresented) {
                FilePickerView { url in
                    if let url = url {
                        print("Selected file URL: \(url)")
                        selectedModelURL = url
                        load3DModel()  // Load the model after selection
                    }
                }
            }
            
            if let modelEntity = modelEntity {
                // Display the 3D model in a RealityView when loaded
                RealityViewContainer(modelEntity: modelEntity)
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: 400)
            } else {
                Text("No 3D Model Loaded")
                    .foregroundColor(.gray)
            }
        }
    }

    func openFilePicker() {
        documentPickerPresented = true
    }

    func load3DModel() {
        // Load 3D model from the selected URL
        guard let url = selectedModelURL else { return }
        
        do {
            let modelEntity = try ModelEntity.loadModel(contentsOf: url)
            self.modelEntity = modelEntity
        } catch {
            print("Failed to load model: \(error)")
        }
    }
}

// Custom view to present the UIDocumentPickerViewController in SwiftUI
struct FilePickerView: View {
    var onFilePicked: (URL?) -> Void

    var body: some View {
        DocumentPickerView(onFilePicked: onFilePicked)
            .edgesIgnoringSafeArea(.all)
    }
}

// Wrapper for UIDocumentPickerViewController
struct DocumentPickerView: UIViewControllerRepresentable {
    var onFilePicked: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var contentTypes: [UTType] = [UTType.usdz]
        
        // Custom UTI for GLTF and OBJ file types
        if let gltfType = UTType("org.web3d.gltf") {
            contentTypes.append(gltfType)
        }
        if let objType = UTType("com.google.obj") {
            contentTypes.append(objType)
        }

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onFilePicked: onFilePicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onFilePicked: (URL?) -> Void

        init(onFilePicked: @escaping (URL?) -> Void) {
            self.onFilePicked = onFilePicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onFilePicked(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onFilePicked(nil)
        }
    }
}

// RealityView to display the loaded model in a new volume
struct RealityViewContainer: View {
    var modelEntity: ModelEntity

    var body: some View {
        RealityView { content in
            // Create a volume and place the modelEntity within it
            let volume = Entity()
            volume.addChild(modelEntity)
            content.add(volume)
        }
    }
}
