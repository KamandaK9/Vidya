//
//  VideoManager.swift
//  Vidya
//
//  Created by Daniel Senga on 2022/11/25.
//

import Foundation

enum Query: String, CaseIterable {
	case nature
	case animals
	case people
	case ocean
	case food
	
}

struct ResponseBody: Decodable {
	var page: Int
	var perPage: Int
	var totalResults: Int
	var url: String
	var videos: [Video]
	
}

struct Video: Identifiable, Decodable {
	var id: Int
	var image: String
	var duration: Int
	var user: User
	var videoFiles: [VideoFile]
	
	
	struct User: Identifiable, Decodable {
		var id: Int
		var name: String
		var url: String
		
	}
	
	struct VideoFile: Identifiable, Decodable {
		var id: Int
		var quality: String
		var fileType: String
		var link: String
	}
}

class VideoManager: ObservableObject {
	
	@Published private(set) var videos: [Video] = []
	@Published var selectedQuery: Query = Query.nature {
		didSet {
			Task.init {
				await findVideos(topic: selectedQuery)
			}
		}
	}
	
	
	init() {
		Task.init {
			await findVideos(topic: selectedQuery)
		}
	}
	
	func findVideos(topic: Query) async {
		do {
			guard let url = URL(string: "https://api.pexels.com/videos/search?query=\(topic)&per_page=10&orientation=portrait")
			else {
				fatalError("Missing URL")
			}
			
			var urlRequest = URLRequest(url: url)
			urlRequest.setValue("563492ad6f917000010000018ce76d25843543d2a5dfebf606e8e3e7", forHTTPHeaderField: "Authorization")
			
			let (data,response) = try await URLSession.shared.data(for: urlRequest)
			
			guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
			
			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			let decodedData = try decoder.decode(ResponseBody.self, from: data)
			
			DispatchQueue.main.async {
				self.videos = []
				self.videos = decodedData.videos
			}
		} catch {
			print("Error fetching data from Pexels: \(error)")
		}
	}
}
