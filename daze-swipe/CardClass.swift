//
//  CardClass.swift
//  daze-swipe
//
//  Created by Andrew Lovett Barron on 2016-07-01.
//  Copyright © 2016 RelayStudio. All rights reserved.
//

//
//  Card.swift
//  daze-proto
//
//  Created by Andrew Lovett Barron on 2016-06-30.
//  Copyright © 2016 RelayStudio. All rights reserved.
//

import Foundation
import UIKit
import MapKit

enum Category: Int {
    case Music = 0
    case Food = 1
    case Event = 2
}

class Card {
    
    let category: Int!
    let name: String!
    let desc: String!
    let location: String!
    let time: String!
    let summary: String!
    let link: NSURL!
    var headlineImage:UIImage!
    var mapThumbnail:UIImage!
    
    var lat:Double! = 0
    var lon:Double! = 0
    
    init(dictionary:NSDictionary) {
        category = dictionary["category"]   as? Int
        name = dictionary["name"]           as? String
        location = dictionary["loc"]   as? String
        time = dictionary["time"]           as? String
        summary = dictionary["summary"] as? String
        link = NSURL(string:String(dictionary["link"]))
//        headlineImage = UIImage(named: "Music_pattern Copy.png") // placeholder
        // fixup the about text to add newlines
        let unescDesc = dictionary["desc"] as? String
        desc = unescDesc?.stringByReplacingOccurrencesOfString("\\n", withString:"\n", options:[], range:nil)
        
        mapThumbnail = UIImage(named: "Music_pattern Copy.png") // Placeholder
        headlineImage = getCategoryImage()
        getLatLon(location)
    }
    
    func getCategoryColor() -> UIColor {
        switch(category) {
        case 0 :
            return UIColor(red:0.90, green:0.97, blue:0.93, alpha:1.0)
        case 1:
            return UIColor(red:0.90, green:0.92, blue:0.97, alpha:1.0)
        case 2:
            return UIColor(red:0.97, green:0.90, blue:0.96, alpha:1.0)
        default:
            return UIColor.darkGrayColor()
        }
    }
    
    func getCategoryColorHex() -> String {
        switch(category) {
        case 0 :
            return "0xE5F7EE"
        case 1:
            return "0xE5EBF7"
        case 2:
            return "0xF7E5F6"
        default:
            return "0xblack"
        }
    }
    
    func getCategoryPattern() -> UIColor {
        return UIColor(patternImage: getCategoryImage())
    }
    
    func getCategoryImage() -> UIImage {
        switch(category) {
        case 0 :
            return UIImage(named: "Music_pattern Copy.png")!
        case 1:
            return UIImage(named: "Food_pattern Copy.png")!
        case 2:
            return UIImage(named: "Event_pattern Copy.png")!
        default:
            return UIImage(named: "Event_pattern.png")!
            
        }
    }
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func loadCardsFromFile(day:String) -> [Card]
    {
        var cards:[Card] = []
        let path = NSBundle.mainBundle().pathForResource("dummy", ofType: "json")
        let error:NSError? = nil
        if(error != nil) { print(error) }
        if let data = try? NSData(contentsOfFile: path!, options:[]),
            json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary,
            card = json![day] as? [NSDictionary] {
            for cardDictionary in card {
                let card = Card(dictionary: cardDictionary)
                cards.append(card)
            }
        }
        return cards
    }
    
    func getLatLon(address:String) {
        let location = address
        let geocoder:CLGeocoder = CLGeocoder();
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369), radius: 15000, identifier: "DCArea")
        geocoder.geocodeAddressString(location,inRegion: region) { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            if placemarks?.count > 0 {
//                print("Returned",placemarks?.count,"for address",address)
//                for place in placemarks! {
////                    print(place)
//                    place.locality
//                }
//                print("Return for",address,placemarks)
                let topResult:CLPlacemark = placemarks![0];
                let placemark: MKPlacemark = MKPlacemark(placemark: topResult);
                self.lat = placemark.coordinate.latitude
                self.lon = placemark.coordinate.longitude
                self.downloadImage()
//                print("GotLatLon",placemark.coordinate)
            }
        }
    }

    func getURL() -> NSURL {
        let centerLon = self.lon-0.01
        
        let url = String("https://maps.googleapis.com/maps/api/staticmap?center="+String(self.lat)+","+String(centerLon)+"&zoom=15&size=900x300&style=element:labels|visibility:off&style=element:geometry.stroke|visibility:off&style=feature:landscape|element:geometry|saturation:-100&style=feature:water|saturation:-100|invert_lightness:true&markers=size:normal|color:"+self.getCategoryColorHex()+"|"+String(self.lat)+","+String(self.lon)+"&key=AIzaSyDQzBhLQfyJ5aL6Uu-tAueEaXPpXz5OCSc")
        let path = NSURL(string: url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        return path!
    }
    
    func downloadImage() {
        var image: UIImage!
        let url = self.getURL()
        
        let request: NSURLRequest = NSURLRequest(URL: url)
        let mainQueue = NSOperationQueue.mainQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
            if error == nil {
                // Convert the downloaded data in to a UIImage object
                let image = UIImage(data: data!)
                // Store the image in to our cache
                self.mapThumbnail = image
                // Update the cell
                dispatch_async(dispatch_get_main_queue(), {
                     NSNotificationCenter.defaultCenter().postNotificationName("didUpdateImage", object: nil)
                    
                })
            }
            else {
                print("Error: \(error!.localizedDescription)")
            }
        })
//        let img = image as? UIImage
//        return img!
    }
    
}
