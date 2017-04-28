//
//  ViewController.swift
//  Project08_PullToRefresh
//
//  Created by siwook on 2017. 4. 12..
//  Copyright © 2017년 siwook. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController {

  var sharedSession : URLSession {
    return URLSession.shared
  }
  
  override func viewDidLoad() {

    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    getImageListFromFlickr()
  }

  
  private func buildAPIRequestParameters()-> [String:AnyObject] {
    
    let methodParameters = [
      Constants.FlickrParameterKeys.Method   : Constants.FlickrParameterValues.PhotosSearchMethod,
      Constants.FlickrParameterKeys.APIKey   : Secret.APIKey,
      //Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
      Constants.FlickrParameterKeys.Extras   : Constants.FlickrParameterValues.MediumURL,
      Constants.FlickrParameterKeys.Format   : Constants.FlickrParameterValues.ResponseFormat,
      // Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
    ]
    
    return methodParameters as [String:AnyObject]
  }
  
  // MARK: Make Network Request
  
  private func getImageListFromFlickr() {
    
    let methodParameters = buildAPIRequestParameters()
    
    
    let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters)
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)
    
    
    let task = sharedSession.dataTask(with: request) { (data, response, error) in
      
      // if an error occurs, print it and re-enable the UI
      func displayError(_ error: String) {
        print(error)
        print("URL at time of error: \(url)")
      }
      
      guard (error == nil) else {
        displayError("There was an error with your request: \(error)")
        return
      }
      
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        displayError("Your request returned a status code other than 2xx!")
        return
      }
      
      /* GUARD: Was there any data returned? */
      guard let data = data else {
        displayError("No data was returned by the request!")
        return
      }
      
      // parse the data
      let parsedResult: [String:AnyObject]!
      do {
        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
        print("result : \(parsedResult)")
      } catch {
        displayError("Could not parse the data as JSON: '\(data)'")
        return
      }
      
      /* GUARD: Did Flickr return an error (stat != ok)? */
      guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
        displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
        return
      }
      
      /* GUARD: Are the "photos" and "photo" keys in our result? */
      guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
        displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
        return
      }
      
      // select a random photo
      let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
      let photoDictionary = photoArray[randomPhotoIndex] as [String:AnyObject]
      let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
      
      /* GUARD: Does our photo have a key for 'url_m'? */
      guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
        displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
        return
      }
      
      // if an image exists at the url, set the image and title
      let imageURL = URL(string: imageUrlString)
      if let imageData = try? Data(contentsOf: imageURL!) {
        DispatchQueue.main.async {
          //self.setUIEnabled(true)
          //self.photoImageView.image = UIImage(data: imageData)
          //self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
        }
      } else {
        displayError("Image does not exist at \(imageURL)")
      }
    }
    
    // start the task!
    task.resume()
  }
  
  // MARK: Helper for Escaping Parameters in URL
  
  private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
    
    if parameters.isEmpty {
      return ""
    } else {
      var keyValuePairs = [String]()
      
      for (key, value) in parameters {
        
        // make sure that it is a string value
        let stringValue = "\(value)"
        
        // escape it
        let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // append it
        keyValuePairs.append(key + "=" + "\(escapedValue!)")
        
      }
      
      return "?\(keyValuePairs.joined(separator: "&"))"
    }
  }
}

