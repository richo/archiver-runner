//
//  AppDelegate.swift
//  archiver-runner
//
//  Created by richö butts on 6/19/19.
//  Copyright © 2019 richö butts. All rights reserved.
//

import Cocoa

// TODO(richo) Make the user open their config manually so that we can use the files permission apple wants.


enum RunState {
    case Running
    case Stopped
}
// TODO(richo) something something resources something something build step
var executableURL = URL(fileURLWithPath: "/Users/richo/code/ext/archiver/target/debug/runner")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var child: Process?
    var state: RunState = RunState.Stopped
    var aggregatedOutput: NSMutableAttributedString?
    var configFile: URL?
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var buttan: NSButton!
    
    fileprivate func maybeSetConfig() {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Open archiver confiig";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["toml"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            self.configFile = dialog.url // Pathname of the file
        }
    }
    
    @IBAction func openConfig(_ sender: Any) {
        maybeSetConfig()
    }
    
    @IBAction func stopStartButton(_ sender: Any) {
        switch state {
        case .Stopped:
            clearOutput()
            if self.configFile == nil {
                maybeSetConfig()
            }
            // After one attempt we'll just bail.
            if self.configFile == nil {
                return
            }
            
            child = createProcess()

            let stdout = Pipe()
            let stderr = Pipe()

            child?.standardOutput = stdout
            child?.standardError = stderr

            child?.terminationHandler = { process in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                self.setRunState(state: .Stopped)

                // TODO(richo) Deal with resetting the ui.
            }
            

            
            do {
                try child?.run()
            } catch {
                print("Well that didn't work: \(error).")
            }
            stdout.fileHandleForReading.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                    self.appendOutput(output: line)
                } else {
                    print("Error decoding data: \(pipe.availableData)")
                }
            }
            stderr.fileHandleForReading.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                    self.appendOutput(output: line)
                } else {
                    print("Error decoding data: \(pipe.availableData)")
                }
            }
            
            setRunState(state: .Running)
        case .Running:
            setRunState(state: .Stopped)
        }
        
    }
    @IBOutlet var textOutput: NSTextView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("Started")
        self.aggregatedOutput = NSMutableAttributedString.init()
        appendOutput(output: "Started archiver ui!\n")
        // self.textOutput?.textStorage?.defaultParagraphStyle.default
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSLog("Bye")
    }
    
    fileprivate func createProcess() -> Process {
        let task = Process()
        task.executableURL = executableURL
        task.arguments = ["--config", self.configFile!.path]
        
        return task
    }
    
    fileprivate func appendOutput(output: String) {
        DispatchQueue.main.async {
            let attrs = [ NSAttributedString.Key.foregroundColor: NSColor.white ]
            let attrString = NSAttributedString(string: output, attributes: attrs)
            self.aggregatedOutput?.append(attrString)
            self.textOutput?.textStorage?.setAttributedString(self.aggregatedOutput!)
            // self.textOutput?.textStorage?.mutableString.append("\n")
        }
    }
    
    fileprivate func clearOutput() {
        DispatchQueue.main.async {
            self.aggregatedOutput = NSMutableAttributedString.init()
            self.textOutput?.textStorage?.setAttributedString(self.aggregatedOutput!)
        }
    }
    
    fileprivate func setRunState(state: RunState) {
        DispatchQueue.main.async {
        switch state {
            case .Stopped:
                self.buttan.title = "Start"
            case .Running:
                self.buttan.title = "Stop"
            }
        }
        self.state = state
    }
}


