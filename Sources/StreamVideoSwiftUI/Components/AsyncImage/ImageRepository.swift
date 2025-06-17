//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class ImagesRepository: ObservableObject, @unchecked Sendable {
    enum TaskState { case idle, loading, loaded(Data), failed(Error) }

    @Published private(set) var storage: [URL: TaskState] = [:]

    private let storageQueue = UnfairQueue()
    private let fileManager: FileManager
    private let filePathURL: URL?
    private let disposableBag = DisposableBag()

    private lazy var diskCacheDirectory: URL = {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    convenience init() {
        guard
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else {
            // Disable local storage
            self.init(fileManager: .default, filePathURL: nil)
            return
        }
        self.init(
            fileManager: .default,
            filePathURL: caches.appendingPathComponent("ImageCache", isDirectory: true)
        )
    }

    init(
        fileManager: FileManager,
        filePathURL: URL?
    ) {
        self.fileManager = fileManager
        self.filePathURL = filePathURL
    }

    func image(for url: URL) {
        let currentValue = storageQueue.sync { storage[url] }

        switch currentValue {
        case .none, .failed:
            storageQueue.sync { storage[url] = .idle }

            if let storedImage = loadFromStorage(url) {
                storageQueue.sync { storage[url] = .loaded(storedImage) }
            } else {
                loadFromNetwork(url)
            }
        default:
            break
        }
    }

    private func loadFromStorage(_ url: URL) -> Data? {
        guard
            let filename = url
            .absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else {
            return nil
        }

        let diskPath = diskCacheDirectory.appendingPathComponent(filename)

        return try? Data(contentsOf: diskPath)
    }

    private func loadFromNetwork(_ url: URL) {
        storageQueue.sync { storage[url] = .loading }
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                if let filename = url
                    .absoluteString
                    .addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                    let diskPath = diskCacheDirectory.appendingPathComponent(filename)
                    try? data.write(to: diskPath)
                }

                storageQueue.sync { self.storage[url] = .loaded(data) }
            } catch {
                storageQueue.sync { self.storage[url] = .failed(error) }
            }
        }
    }
}

extension ImagesRepository: InjectionKey {
    nonisolated(unsafe) static var currentValue: ImagesRepository = .init()
}

extension InjectedValues {
    var imagesRepository: ImagesRepository {
        get { Self[ImagesRepository.self] }
        set { Self[ImagesRepository.self] = newValue }
    }
}
