//
//  CompileMessure.swift
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

@objcMembers class CompileMeasure: NSObject {
    
    dynamic var time: Double = 0
    var path: String = ""
    var code: String = ""
    var codeLine: Int = 0
    dynamic var filename: String = ""
    var references: Int = 0
    
    private var locationArray: [Int]
    
    public enum Order: String {
        case filename
        case time
    }
    
    var fileAndLine: String {
        return "\(filename):\(locationArray[0])"
    }
    
    var fileInfo: String {
        return "\(fileAndLine):\(locationArray[1])"
    }
    
    var location: Int {
        return locationArray[0]
    }
    
    var timeString: String {
        return String(format: "%.1fms", time)
    }
    
    init?(time: Double, rawPath: String, code: String, references: Int) {
        let untrimmedFilename = rawPath.split(separator: "/").map(String.init).last
        
        guard let filepath = rawPath.split(separator: ":").map(String.init).first,
            let filename = untrimmedFilename?.split(separator: ":").map(String.init).first else { return nil }
        
        let locationString = String(rawPath[filepath.endIndex...].dropFirst())
        let locations = locationString.split(separator: ":").compactMap{ Int(String.init($0)) }
        guard locations.count == 2 else { return nil }
        
        self.time = time
        self.code = CompileMeasure.removeRandNfromLineForString(code)
        self.codeLine = locations.first!
        self.path = filepath
        self.filename = filename
        self.locationArray = locations
        self.references = references
    }
    
    init?(rawPath: String, time: Double) {
        let untrimmedFilename = rawPath.split(separator: "/").map(String.init).last
        
        guard let filepath = rawPath.split(separator: ":").map(String.init).first,
            let filename = untrimmedFilename?.split(separator: ":").map(String.init).first else { return nil }
        
        self.time = time
        self.code = ""
        self.path = filepath
        self.filename = filename
        self.locationArray = [1,1]
        self.references = 1
    }
    
    subscript(column: Int) -> String {
        switch column {
        case 0:
            return timeString
        case 1:
            return fileInfo
        case 2:
            return "\(references)"
        default:
            return code
        }
    }
    
    public class func removeRandNfromLineForString(_ string: String?) -> String! {
        var result = ""
        guard string != nil else {
            return ""
        }
        var tmp = string?.replacingOccurrences(of: "\r", with: "")
        tmp = tmp?.replacingOccurrences(of: "\n", with: "")
        if let tmpString = tmp {
            result.append(tmpString)
        }
        return result
    }
    
    public func convertToLogCsvLine() -> String! {
        return "\(filename),\(code),\(codeLine),\(time)_ms \r\n"
    }
}
