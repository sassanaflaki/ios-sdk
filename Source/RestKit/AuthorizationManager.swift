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
import RestKit

public class AuthorizationManager: Manager {
    
    // Rest token to be used to get token
    private var restToken: RestToken?

    // Properties to handle tokens.
    public typealias NetworkSuccessHandler = (AnyObject?) -> Void
    public typealias NetworkFailureHandler = (NSHTTPURLResponse?, AnyObject?, NSError) -> Void
    
    private typealias CachedRequest = (NSHTTPURLResponse?, AnyObject?, NSError?) -> Void
    
    private var cachedRequests = Array<CachedRequest>()
    private var isRefreshing = false
    
    // TODO - check this number? I'm assuming this is necessary.
    // Maximum number of authentication retries before returning failure.
    private let maxRetries = 2
    
    public func startRequest(
        method method: Alamofire.Method,
               URLString: URLStringConvertible,
               parameters: [String: AnyObject]?,
               encoding: ParameterEncoding,
               restToken: RestToken,
               success: NetworkSuccessHandler?,
               failure: NetworkFailureHandler?) -> Request?
    {
        let cachedRequest: CachedRequest = { [weak self] URLResponse, data, error in
            guard let strongSelf = self else {
                createError("Internal error. Unable to execute network operation.")
                return
            }
            
            if let error = error {
                failure?(URLResponse, data, error)
            } else {
                strongSelf.startRequest(
                    method: method,
                    URLString: URLString,
                    parameters: parameters,
                    encoding: encoding,
                    restToken: restToken,
                    success: success,
                    failure: failure
                )
            }
        }
        
        if self.isRefreshing {
            self.cachedRequests.append(cachedRequest)
            return
        }
        
        // Append your auth tokens here to your parameters
        guard let restToken.token != nil else {
            strongSelf.cachedRequests.append(cachedRequest)
            strongSelf.refreshTokens()
            restToken.isRefreshing = true
            restToken.retries += 1
        }
        URLString = URLString.URLString.stringByAppendingString("?watson-token=\(restToken.token)")
        let request = self.request(method, URLString, parameters: parameters, encoding: encoding)
        
        request.response { [weak self] request, response, data, error in
            guard let strongSelf = self else { return }
            
            if let response = response where response.statusCode == 401 {
                strongSelf.cachedRequests.append(cachedRequest)
                strongSelf.refreshTokens()
                return
            }
            
            if let error = error {
                failure?(response, data, error)
            } else {
                success?(data)
            }
        }
        
        return request
    }
    
    func refreshTokens() {
        self.isRefreshing = true
        
        // Make the refresh call and run the following in the success closure to restart the cached requests
        guard let token = restToken else {
            createError("No token found to refresh.")
        }
        
        if token.retries >= maxRetries {
            createError("Too many tries. Please log in again.")
        }

        token.refreshToken({ error in
            createError("Unable to refresh token")
            }, success: {
                let cachedRequestsCopy = self.cachedRequests
                self.cachedRequests.removeAll()
                cachedRequestsCopy.map { $0(nil, nil, nil) }
                
                self.isRefreshing = false
        })
    }
    
    private func createError(description: String) -> NSError {
        let code = -1
        let domain = "com.ibm.mil"
        let userInfo = [NSLocalizedDescriptionKey: description]
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        return error
    }
}