//
//  ViewController.swift
//  PNG-to-JPEG
//
//  Created by Andrey Isaev on 14/08/2019.
//  Copyright © 2019 Andrey Isaev. All rights reserved.
//

import Cocoa
import AppKit

class ViewController: NSViewController {

    @IBOutlet weak var buttonSelect: NSButton!
    
    @IBAction func buttonSelect(_ sender: Any) {
        DataLoader.load { (success: Bool) in
            if success {
                let files = DataLoader.singleton.files
                let newFolder = "PNG-to-JPEG-Results"
                for file in files {
                    let png = NSImage(contentsOfFile: file)
                    if let imageRep = png?.representations.first as? NSBitmapImageRep, let imageData = imageRep.representation(using: .jpeg, properties: [:]), let name = file.components(separatedBy: "/").last?.replacingOccurrences(of: ".png", with: ".jpeg"), let newFile = FileManager.desktopFilePathWithName(name, folderName: newFolder) {
                        let newUrl = URL(fileURLWithPath: newFile)
                        do {
                            try imageData.write(to: newUrl)
                        } catch {
                            print(error)
                        }
                    }
                }
                NSWorkspace.shared.openFile(FileManager.desktopFilePathWithName(nil, folderName: newFolder)! as String)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

class DataLoader {
    
    var files = [String]()
    
    class var singleton : DataLoader {
        struct Static {
            static let sharedInstance : DataLoader = DataLoader()
        }
        return Static.sharedInstance
    }
    
    class func load(_ completion: @escaping ((Bool) -> ())) {
        let dl = DataLoader.singleton
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                var selected = [String]()
                let fm = Foundation.FileManager.default
                for URL in panel.urls {
                    let path = URL.path
                    var isDirectory : ObjCBool = false
                    if fm.fileExists(atPath: path, isDirectory:&isDirectory) && isDirectory.boolValue {
                        selected += recursiveGetFilesFromDirectory(path)
                    } else {
                        selected.append(path)
                    }
                }
                selected = selected.filter({ (s: String) -> Bool in
                    if let ext = (s as NSString).components(separatedBy: ".").last {
                        return ext.caseInsensitiveCompare("png") == .orderedSame
                    } else {
                        return false
                    }
                })
                dl.files = selected
                completion(selected.count > 0)
            }
        }
    }
    
    /**
     Recursive bypasses folders in 'directoryPath' and then return all files in these folders.
     */
    fileprivate class func recursiveGetFilesFromDirectory(_ directoryPath: String) -> [String] {
        var results = [String]()
        let fm = Foundation.FileManager.default
        do {
            let fileNames = try fm.contentsOfDirectory(atPath: directoryPath)
            for fileName in fileNames {
                let path = (directoryPath as NSString).appendingPathComponent(fileName)
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        results += recursiveGetFilesFromDirectory(path)
                    } else {
                        results.append(path)
                    }
                }
            }
        } catch {
            print(error)
        }
        return results
    }
    
}

class FileManager {
    
    fileprivate class func desktopFolder() -> NSString? {
        return NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first as NSString?
    }
    
    fileprivate class func createIfNeedsDirectoryAtPath(_ path: String?) {
        if let path = path {
            let fm = Foundation.FileManager.default
            if false == fm.fileExists(atPath: path) {
                do {
                    try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    fileprivate class func desktopFilePathWithName(_ fileName: String?, folderName: String?) -> String? {
        var path = self.desktopFolder()
        if let folderName = folderName {
            path = path?.appendingPathComponent(folderName) as NSString?
            createIfNeedsDirectoryAtPath(path as String?)
        }
        if let fileName = fileName {
            return path?.appendingPathComponent(fileName)
        } else {
            return path as String?
        }
    }
    
}
