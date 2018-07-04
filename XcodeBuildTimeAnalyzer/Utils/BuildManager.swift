//
//  BuildManager.swift
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

protocol BuildManagerDelegate: class {
    func derivedDataDidChange()
    func buildManager(_ buildManager: BuildManager, shouldParseLogWithDatabase database: XcodeDatabase)
}

class BuildManager: NSObject {
    
    weak var delegate: BuildManagerDelegate?
    
    private let derivedDataDirectoryMonitor = DirectoryMonitor(isDerivedData: true)
    private let logFolderDirectoryMonitor = DirectoryMonitor(isDerivedData: false)
    
    private var currentDataBase: XcodeDatabase?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        derivedDataDirectoryMonitor.delegate = self
        logFolderDirectoryMonitor.delegate = self
        
        startMonitoring()
    }
    
    func startMonitoring() {
        stopMonitoring()
        derivedDataDirectoryMonitor.startMonitoring(path: UserPrefs.derivedDataLocation)
    }
    
    func stopMonitoring() {
        derivedDataDirectoryMonitor.stopMonitoring()
    }
    
    func database(forFolder URL: URL) -> XcodeDatabase? {
        let databaseURL = URL.appendingPathComponent("Cache.db")
        return XcodeDatabase(fromPath: databaseURL.path)
    }
    
    func processDerivedData() {
        guard let mostRecent = DerivedDataManager.derivedData().first else { return }
        
        let logFolder = mostRecent.url.appendingPathComponent("Logs/Build").path
        guard logFolderDirectoryMonitor.path != logFolder else { return }
        
        logFolderDirectoryMonitor.stopMonitoring()
        logFolderDirectoryMonitor.startMonitoring(path: logFolder)
    }
    
    func processLogFolder(with url: URL) {
        guard let activeDatabase = database(forFolder: url),
            activeDatabase.isBuildType,
            activeDatabase != currentDataBase else { return }
        
        currentDataBase = activeDatabase
        delegate?.buildManager(self, shouldParseLogWithDatabase: activeDatabase)
    }
}

extension BuildManager: DirectoryMonitorDelegate {
    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor, isDerivedData: Bool) {
        if isDerivedData {
            delegate?.derivedDataDidChange()
            processDerivedData()
        } else if let path = directoryMonitor.path {
            // TODO: If we don't dispatch, it seems it fires off too soon
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.processLogFolder(with: URL(fileURLWithPath: path))
            }
        }
    }
}
