//
//  XcodeDatabase.swift
//  XcodeBuildTimeAnalyzer
//
//  Created by SuXinDe on 2018/7/5.
//  Copyright © 2018年 su xinde. All rights reserved.
//

/*
 MIT License
 
 Copyright (c) 2018 `__承_影__`
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 ---
 
 MIT License
 
 Copyright (c) 2016-2018, Robert Gummesson
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

struct XcodeDatabase {
    var path: String
    var modificationDate: Date
    
    var key: String
    var schemeName: String
    var title: String
    var timeStartedRecording: Int
    var timeStoppedRecording: Int
    
    var isBuildType: Bool {
        return title.hasPrefix("Build ") ||  title.hasPrefix("Compile ")
    }
    
    var url: URL {
        return URL(fileURLWithPath: path)
    }
    
    var logUrl: URL {
        return folderPath.appendingPathComponent("\(key).xcactivitylog")
    }
    
    var folderPath: URL {
        return url.deletingLastPathComponent()
    }
    
    var buildTime: Int {
        return timeStoppedRecording - timeStartedRecording
    }
    
    init?(fromPath path: String) {
        guard let data = NSDictionary(contentsOfFile: path)?["logs"] as? [String: AnyObject],
            let key = XcodeDatabase.sortKeys(usingData: data).last?.key,
            let value = data[key] as? [String : AnyObject],
            let schemeName = value["schemeIdentifier-schemeName"] as? String,
            let title = value["title"] as? String,
            let timeStartedRecording = value["timeStartedRecording"] as? NSNumber,
            let timeStoppedRecording = value["timeStoppedRecording"] as? NSNumber,
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path),
            let modificationDate = fileAttributes[FileAttributeKey.modificationDate] as? Date
            else { return nil }
        
        self.modificationDate = modificationDate
        self.path = path
        self.key = key
        self.schemeName = schemeName
        self.title = title
        self.timeStartedRecording = timeStartedRecording.intValue
        self.timeStoppedRecording = timeStoppedRecording.intValue
    }
    
    func processLog() -> String? {
        if let rawData = try? Data(contentsOf: URL(fileURLWithPath: logUrl.path)),
            let data = (rawData as NSData).gunzipped() {
            return String(data: data, encoding: String.Encoding.utf8)
        }
        return nil
    }
    
    static private func sortKeys(usingData data: [String: AnyObject]) -> [(Int, key: String)] {
        var sortedKeys: [(Int, key: String)] = []
        for key in data.keys {
            if let value = data[key] as? [String: AnyObject],
                let timeStoppedRecording = value["timeStoppedRecording"] as? NSNumber {
                sortedKeys.append((timeStoppedRecording.intValue, key))
            }
        }
        return sortedKeys.sorted{ $0.0 < $1.0 }
    }
}

extension XcodeDatabase : Equatable {}

func ==(lhs: XcodeDatabase, rhs: XcodeDatabase) -> Bool {
    return lhs.path == rhs.path && lhs.modificationDate == rhs.modificationDate
}
