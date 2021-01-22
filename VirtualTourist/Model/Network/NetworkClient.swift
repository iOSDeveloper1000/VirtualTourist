//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Arno Seidel on 15.01.21.
//

import Foundation


class NetworkClient {
    
    struct Constants {
        static let endpointSearch = "https://api.flickr.com/services/rest"
        static let staticPhotoUrl = "https://live.staticflickr.com"
        static let apiKey = ""
        static let apiMethod = "flickr.photos.search"
        static let photosPerPage = 18
        static let pageNumberMax = 13
        static let searchRangeInKM = 7
    }
    
    
    class func downloadListOfPhotoUrls(latitude: Double, longitude: Double, completion: @escaping ([String]?, HttpStatusResponse?, Error?) -> Void) {

        // Asserting kind of randomness for the received images
        let pageNumber = Int.random(in: 1...Constants.pageNumberMax)
        let flickrUrl = URL(string: "\(Constants.endpointSearch)?api_key=\(Constants.apiKey)&method=\(Constants.apiMethod)&format=json&per_page=\(Constants.photosPerPage)&page=\(pageNumber)&lat=\(latitude)&lon=\(longitude)&radius=\(Constants.searchRangeInKM)")
        
        let task = URLSession.shared.dataTask(with: flickrUrl!, completionHandler: { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, nil, error)
                }
                return
            }

            let decoder = JSONDecoder()
            let jsonData = data.subdata(in: 14..<data.count-1)

            do {
                let responseBody = try decoder.decode(PhotoResponseType.self, from: jsonData)
                
                // Synthesize the static photo urls
                var photoUrls = [String]()
                for img in responseBody.photos.photo {
                    let url = "\(Constants.staticPhotoUrl)/\(img.server)/\(img.id)_\(img.secret)_w.jpg"
                    photoUrls.append(url)
                }
                
                DispatchQueue.main.async {
                    completion(photoUrls, nil, nil)
                }
                
            } catch {
                do { // catch HTTP Error response
                    let responseBody = try decoder.decode(HttpStatusResponse.self, from: jsonData)
                    DispatchQueue.main.async {
                        completion(nil, responseBody, error)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, nil, error)
                    }
                }
            }
        })
        task.resume()
    }
    
    class func downloadPhotoData(url: URL, completion: @escaping (Data?) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url) {
                
                DispatchQueue.main.async {
                    completion(data)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
}
