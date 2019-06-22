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
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var buttan: NSButton!
    
    @IBAction func stopStartButton(_ sender: Any) {
        switch state {
        case .Stopped:
            child = createProcess()
            

            let stdout = Pipe()
            let stderr = Pipe()

            child?.standardOutput = stdout
            child?.standardError = stderr

            child?.terminationHandler = { process in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil

                // TODO(richo) Deal with resetting the ui.
            }
            

            
            do {
                try child?.run()
            } catch {
                print("Well that didn't work: \(error).")
            }
            stdout.fileHandleForReading.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                    DispatchQueue.main.async {
                        self.textOutput?.textStorage?.mutableString.append(line)
                        print("output \(line)")
                    }
                } else {
                    print("Error decoding data: \(pipe.availableData)")
                }
            }
            stderr.fileHandleForReading.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                    DispatchQueue.main.async {
                        self.textOutput?.textStorage?.mutableString.append(line)
                        print("error \(line)")
                    }
                } else {
                    print("Error decoding data: \(pipe.availableData)")
                }
            }
            
            buttan.title = "Stop"
            state = .Running
        case .Running:
            buttan.title = "Start"
            state = .Stopped
        }
        
    }
    @IBOutlet var textOutput: NSTextView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("Started")
        self.textOutput?.insertText("butts")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        NSLog("Bye")
    }
    
    fileprivate func createProcess() -> Process {
        let task = Process()
        task.executableURL = executableURL
        task.arguments = []
        
        return task
    }
}

