/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import Alamofire
import Freddy

/**
 A `RestRequest` object represents a REST request to a remote server.
 
 The `RestRequest` object captures all common arguments required to construct
 an HTTP request message and can also represent itself as an `NSMutableURLRequest`
 for use with `NSURLSession` or `Alamofire`.
 */
public class RestRequest {
    
    private let request: Request
    private let mutableURLRequest: NSMutableURLRequest
    
    /// Properties to store additional requests if 401 is received
    // private typealias CachedTask = (NSURLResponse?, AnyObject?, NSError?) -> Void
//    private var cachedTasks: [CachedTask]

    /**
     Initialize a `RestRequest` that represents a REST request to a remote server.
 
     - parameter method: The HTTP method of the request.
     - parameter url: The url of the request.
     - parameter acceptType: The acceptable media type of the response's message body.
     - parameter contentType: The media type of the request's message body.
     - parameter userAgent: A custom user-agent string that should be used for the request.
     - parameter queryParameters: The parameters to encode in the url's query string.
     - parameter headerParameters: The parameters to encode in the request's HTTP header.
     - parameter messageBody: The data to be included in the message body.
 
     - returns: A `RestRequest` object that represent the REST request to a remote server.
     */
    public init(
        method: Alamofire.Method,
        url: String,
        acceptType: String? = nil,
        contentType: String? = nil,
        userAgent: String? = nil,
        queryParameters: [NSURLQueryItem]? = nil,
        headerParameters: [String: String]? = nil,
        messageBody: NSData? = nil,
        authToken: String? = nil)
    {
        // construct url with query parameters
        let urlComponents = NSURLComponents(string: url)!
        if let queryParameters = queryParameters where !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters
        }
        
        // construct basic mutable request
        let request = NSMutableURLRequest(URL: urlComponents.URL!)
        request.HTTPMethod = method.rawValue
        request.HTTPBody = messageBody
        
        // set the request's accept type
        if let acceptType = acceptType {
            request.setValue(acceptType, forHTTPHeaderField: "Accept")
        }
        
        // set the request's content type
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // set the request's user agent
        if let userAgent = userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // set the request's header parameters
        if let headerParameters = headerParameters {
            for (key, value) in headerParameters {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // create Alamofire request
        self.request = Alamofire.request(request)
        self.mutableURLRequest = request
    }

    public func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence = .ForSession) -> Self {
        request.authenticate(user: user, password: password, persistence: persistence)
        return self
    }
    
    public func responseArray<T: JSONDecodable>(
        queue queue: dispatch_queue_t? = nil,
              dataToError: (NSData -> NSError?)? = nil,
              path: [JSONPathType]? = nil,
              completionHandler: Response<[T], NSError> -> Void)
        -> Self
    {
        request.responseArray(queue: queue, dataToError: dataToError, path: path, completionHandler: completionHandler)
        return self
    }
    
    public func download(destination: Request.DownloadFileDestination) -> Request {
        return Alamofire.download(self.mutableURLRequest, destination: destination)
    }

    public func responseData(queue queue: dispatch_queue_t? = nil, completionHandler: Response<NSData, NSError> -> Void) -> Self {
        request.responseData(queue: queue, completionHandler: completionHandler)
        return self
    }
    
    public func responseObject<T: JSONDecodable>(
        queue queue: dispatch_queue_t? = nil,
              dataToError: (NSData -> NSError?)? = nil,
              path: [JSONPathType]? = nil,
              completionHandler: Response<T, NSError> -> Void)
        -> Self
    {
        request.responseObject(queue: queue, dataToError: dataToError, path: path, completionHandler: completionHandler)
        return self
    }
    
    public func upload(multipartFormData: MultipartFormData -> Void, encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold, encodingCompletion: (Manager.MultipartFormDataEncodingResult -> Void)?)
    {
        Alamofire.upload(self.mutableURLRequest, multipartFormData: multipartFormData, encodingMemoryThreshold: encodingMemoryThreshold, encodingCompletion: encodingCompletion)
    }
    
    public func upload(file: NSURL) -> Request {
        return Alamofire.upload(self.mutableURLRequest, file: file)
    }
    
    public func validate() -> Self {
        request.validate()
        return self
    }
    /** 
 
    - paramater data: data returned by server
    - paramater response: server's response to the URL's request
    - paramater error: failure message
    */
    
    // what response
//    public func responseObject (callback: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)) {
//        // construct url with query parameters
//        guard var urlComponents = NSURLComponents(string: self.url) else {
//            NSLog("Could not build URLComponents object from URL")
//            return
//        }
//        
//        let urlResponseComponents = NSURLComponents(string: self.url)!
//        if let queryParameters = queryParameters where !queryParameters.isEmpty {
//            urlResponseComponents.queryItems = queryParameters
//        }
//        
//        // construct headers
//        var headers = [String: String]()
//        
//        // set the request's accept type
//        if let acceptType = acceptType {
//            headers["Accept"] = acceptType
//        }
//        
//        // set the request's content type
//        if let contentType = contentType {
//            headers["Content-Type"] = contentType
//        }
//        
//        // set the auth token
//        if let authToken = authToken {
//            headers["authToken"] = authToken
//        }
//        
//        // set the request's header parameters
//        if let headerParameters = headerParameters {
//            for (key, value) in headerParameters {
//                headers[key] = value
//            }
//        }
//        
//        // verify URL is valid, include auth token, then create it
//        guard let _ = urlResponseComponents.scheme,
//            let _ = urlResponseComponents.percentEncodedHost,
//            let url = NSURL(string: self.url + (urlResponseComponents.percentEncodedQuery ?? "")) else {
//                NSLog("Could not create a valid URL object.")
//                return
//        }
//        
//        // build request and execute it
//        var request = NSMutableURLRequest.init(URL: url)
//        request.HTTPMethod = method.rawValue
//        request.allHTTPHeaderFields = headers
//        if let messageBody = messageBody {
//            request.HTTPBody = messageBody
//        }
//        
//        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
//        let task = session.dataTaskWithRequest(request) { (data, response, error) in
//            callback(data: data, response: response, error: error)
//        }
//        task.resume()
//    }
//    
//    func handleErrorResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> String? {
//        if let err = error {
//            return err.localizedDescription
//        }
//        
//        if let response = response as? NSHTTPURLResponse {
//            switch response.statusCode {
//            case 200:
//                return nil
//            case 401:
//                // If response is unauthorized, append request to see if we need to refresh token.
//                // Check if cached list is empty
//                return checkRefresh()
//            default:
//                return "Received status code: \((response as? NSHTTPURLResponse)?.statusCode)"
//            }
//        } else {
//            return "Failed to get valid response, received status code: \((response as? NSHTTPURLResponse)?.statusCode)"
//        }
//    }
//    
//    func checkRefresh() -> String? {
//        return nil
//    }
}
