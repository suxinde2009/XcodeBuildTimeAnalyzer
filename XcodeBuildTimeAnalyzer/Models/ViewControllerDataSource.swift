//
//  ViewControllerDataSource.swift
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
import Cocoa

class ViewControllerDataSource {
    
    var aggregateByFile = false {
        didSet {
            processData()
        }
    }
    
    var filter = "" {
        didSet {
            processData()
        }
    }
    
    var sortDescriptors = [NSSortDescriptor]() {
        didSet {
            processData()
        }
    }
    
    public func exportToCsvLogContent() -> String! {
        var csvContent: String = ""
        csvContent.append("FileName, Code, Line, Time\r\n")
        for item in processedData {
            csvContent.append(item.convertToLogCsvLine())
        }
        return csvContent
    }
    
    private var originalData = [CompileMeasure]()
    private var processedData = [CompileMeasure]()
    
    func resetSourceData(newSourceData: [CompileMeasure]) {
        originalData = newSourceData
        processData()
    }
    
    func isEmpty() -> Bool {
        return processedData.isEmpty
    }
    
    func count() -> Int {
        return processedData.count
    }
    
    func measure(index: Int) -> CompileMeasure? {
        guard index < processedData.count && index >= 0 else { return nil }
        return processedData[index]
    }

    
    private func processData() {
        var newProcessedData = aggregateIfNeeded(originalData)
        newProcessedData = applySortingIfNeeded(newProcessedData)
        newProcessedData = applyFilteringIfNeeded(newProcessedData)
        
        processedData = newProcessedData
    }
    
    private func aggregateIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        guard aggregateByFile else { return input }
        var fileTimes: [String: CompileMeasure] = [:]
        for measure in input {
            if let fileMeasure = fileTimes[measure.path] {
                fileMeasure.time += measure.time
                fileTimes[measure.path] = fileMeasure
            } else {
                let newFileMeasure = CompileMeasure(rawPath: measure.path, time: measure.time)
                fileTimes[measure.path] = newFileMeasure
            }
        }
        return Array(fileTimes.values)
    }
    
    private func applySortingIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        if sortDescriptors.isEmpty { return input }
        return (input as NSArray).sortedArray(using: sortDescriptors) as! Array
    }
    
    private func applyFilteringIfNeeded(_ input: [CompileMeasure]) -> [CompileMeasure] {
        guard !filter.isEmpty else { return input }
        return input.filter{ textContains($0.code, pattern: filter) || textContains($0.filename, pattern: filter) }
    }
    
    private func textContains(_ text: String, pattern: String) -> Bool {
        return text.lowercased().contains(pattern.lowercased())
    }
}
