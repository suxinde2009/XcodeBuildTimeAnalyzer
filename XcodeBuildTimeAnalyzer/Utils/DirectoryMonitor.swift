//
//  DirectoryMonitor.swift
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

protocol DirectoryMonitorDelegate: class {
    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor, isDerivedData: Bool)
}

class DirectoryMonitor {
    var dispatchQueue: DispatchQueue
    
    weak var delegate: DirectoryMonitorDelegate?
    
    var fileDescriptor: Int32 = -1
    var dispatchSource: DispatchSourceFileSystemObject?
    var isDerivedData: Bool
    var path: String?
    var timer: Timer?
    var lastDerivedDataDate = Date()
    var isMonitoringDates = false
    
    init(isDerivedData: Bool) {
        self.isDerivedData = isDerivedData
        
        let suffix = isDerivedData ? "deriveddata" : "logfolder"
        dispatchQueue = DispatchQueue(label: "uk.co.canemedia.directorymonitor.\(suffix)", attributes: .concurrent)
    }
    
    func startMonitoring(path: String) {
        self.path = path
        
        guard dispatchSource == nil && fileDescriptor == -1 else { return }
        
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .all, queue: dispatchQueue)
        dispatchSource?.setEventHandler {
            DispatchQueue.main.async {
                self.delegate?.directoryMonitorDidObserveChange(self, isDerivedData: self.isDerivedData)
            }
        }
        dispatchSource?.setCancelHandler {
            close(self.fileDescriptor)
            
            self.fileDescriptor = -1
            self.dispatchSource = nil
            self.path = nil
        }
        dispatchSource?.resume()
        
        if isDerivedData && !isMonitoringDates {
            isMonitoringDates = true
            monitorModificationDates()
        }
    }
    
    func stopMonitoring() {
        dispatchSource?.cancel()
        path = nil
    }
    
    func monitorModificationDates() {
        if let date = DerivedDataManager.derivedData().first?.date, date > lastDerivedDataDate {
            lastDerivedDataDate = date
            self.delegate?.directoryMonitorDidObserveChange(self, isDerivedData: self.isDerivedData)
        }
        
        if path != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.monitorModificationDates()
            }
        } else {
            isMonitoringDates = false
        }
    }
}
