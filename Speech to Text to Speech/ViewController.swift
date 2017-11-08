//
//  ViewController.swift
//  Speech to Text to Speech
//
//  Created by jochem toolenaar on 08/11/2017.
//  Copyright © 2017 jtms. All rights reserved.
//

import UIKit
import Speech
import AVFoundation


class ViewController: UIViewController {
    
    @IBOutlet weak var previewTextView: UITextView!
    @IBOutlet weak var recordingButton: UIButton!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    
    //tts
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //stt
    let speechSynthesizer = AVSpeechSynthesizer()
    @IBOutlet weak var speakButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        speak(text: "What can I help you with?")
    }
    
    func setup(){
        recordingButton.isEnabled = false
        speechRecognizer?.delegate = self
        requestSpeechAuthorization()
    }
    
    
}

//speech to text
extension ViewController{
    func requestSpeechAuthorization(){
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.recordingButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recordingButton.isEnabled = false
            recordingButton.setTitle("Start Recording", for: .normal)
            speakButton.isEnabled = true
            
            //reset audio for playback
            let audioSession = AVAudioSession.sharedInstance()
            do {
                
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                try audioSession.setMode(AVAudioSessionModeDefault)
                
            } catch {
                print("audioSession properties weren't set because of an error.")
            }
            
        } else {
            startRecording()
            recordingButton.setTitle("Stop Recording", for: .normal)
            speakButton.isEnabled = false
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.previewTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordingButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        previewTextView.text = "Say something, I'm listening!"
        
    }
}

extension ViewController: SFSpeechRecognizerDelegate{
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordingButton.isEnabled = true
        } else {
            recordingButton.isEnabled = false
        }
    }
    
}
//text to speech
extension ViewController{
    
    @IBAction func speakButtonTapped(_ sender: Any) {
        self.speak(text: previewTextView.text)
    }
    
    func speak(text:String){
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let lang = "en-US"
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        
        speechSynthesizer.speak(utterance)
    }
}

