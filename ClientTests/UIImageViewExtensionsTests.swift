/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import XCTest
import Storage
import WebImage
import GCDWebServers

@testable import Client


class UIImageViewExtensionsTests: XCTestCase {

    override func setUp() {
        SDWebImageDownloader.sharedDownloader().urlCredential = WebServer.sharedInstance.credentials
    }

    func testsetIcon() {
        let url = NSURL(string: "http://mozilla.com")
        let imageView = UIImageView()

        let goodIcon = FaviconFetcher.getDefaultFavicon(url!)
        let correctColor = FaviconFetcher.getDefaultColor(url!)
        imageView.setIcon(nil, forURL: url)
        XCTAssertEqual(imageView.image!, goodIcon, "The correct default favicon should be applied")
        XCTAssertEqual(imageView.backgroundColor, correctColor, "The correct default color should be applied")

        imageView.setIcon(nil, forURL: NSURL(string: "http://mozilla.com/blahblah"))
        XCTAssertEqual(imageView.image!, goodIcon, "The same icon should be applied to all urls with the same domain")

        imageView.setIcon(nil, forURL: NSURL(string: "b"))
        XCTAssertEqual(imageView.image, FaviconFetcher.defaultFavicon, "The default favicon should be applied when no information is given about the icon")
    }

    func testAsyncSetIcon() {
        let imageData = UIImagePNGRepresentation(UIImage(named: "fxLogo")!)
        WebServer.sharedInstance.registerHandlerForMethod("GET", module: "favicon", resource: "icon") { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(data: imageData, contentType: "image/png")
        }

        let favImageView = UIImageView()
        favImageView.setIcon(Favicon(url: "http://localhost:6571/favicon/icon", type: .Guess), forURL: NSURL(string: "http://localhost:6571"))

        let expect = expectationWithDescription("UIImageView async load")
        let time = Int64(2 * Double(NSEC_PER_SEC))
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue()) {
            let a = UIImagePNGRepresentation(favImageView.image!)
            XCTAssertEqual(imageData, a, "The correct favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testAsyncSetIconFail() {
        let favImageView = UIImageView()

        let gFavURL = NSURL(string: "https://www.google.com/noicon.ico")
        let gURL = NSURL(string: "http://google.com")
        let correctImage = FaviconFetcher.getDefaultFavicon(gURL!)

        favImageView.setIcon(Favicon(url: gFavURL!.absoluteString!, type: .Guess), forURL: gURL)

        let expect = expectationWithDescription("UIImageView async load")
        let time = Int64(2 * Double(NSEC_PER_SEC))
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue()) {
            let b = UIImagePNGRepresentation(correctImage) // we need to convert to png in order to compare
            let a = UIImagePNGRepresentation(favImageView.image!)
            XCTAssertEqual(b, a, "The correct default favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
