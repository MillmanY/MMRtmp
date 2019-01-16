# MMRtmp

[![CI Status](https://img.shields.io/travis/MillmanY/MMRtmp.svg?style=flat)](https://travis-ci.org/MillmanY/MMRtmp)
[![Version](https://img.shields.io/cocoapods/v/MMRtmp.svg?style=flat)](https://cocoapods.org/pods/MMRtmp)
[![License](https://img.shields.io/cocoapods/l/MMRtmp.svg?style=flat)](https://cocoapods.org/pods/MMRtmp)
[![Platform](https://img.shields.io/cocoapods/p/MMRtmp.svg?style=flat)](https://cocoapods.org/pods/MMRtmp)

Implement rtmp protocol play/publish with h264/aac 
## Demo

### Play
Use RTMPPlayLayer class play rtmp video

  * Play Action 
		 
		displayLayer.play(host: "rtmp://184.72.239.149/vod", name: "BigBuckBunny_115k.mov")
  
  * Stop
     
		 displayLayer.stop()
 
  * Seek
  		
		displayLayer.seek(duration: 100)
		
  * Pause / UnPause
  
  		displayLayer.pause()
		displayLayer.unPause()
		
  * Status Check
       
		 displayLayer.playStatus { [unowned self] (status) in
            switch status {
            case .connect:
                self.pauseBtn.isHidden = false
                self.btnPlay.setTitle("Disconnected", for: .normal)
            case .failed(let err):
                print(err)
            case .unknown:
                self.pauseBtn.isHidden = true
            case .disconnected:
                self.btnPlay.setTitle("Play", for: .normal)
            case .pause:
                self.pauseBtn.setTitle("Resume", for: .normal)
            case .playStart:
                self.pauseBtn.setTitle("Pause", for: .normal)
                break
            }
        }

### Publish
Use RTMPPublishLayer class publish video on server

* Auth Layer
	
		publishLayer.authVideoAudio { (rc) in
			if !rc {
				let alert = UIAlertController.init(title: "Error", message: "you need auth your microphone and camera", preferredStyle: .alert)
				let action = UIAlertAction.init(title: "confirm", style: .default, handler: nil)
					alert.addAction(action)
			}
		}
  
 * Publish
   
   		publishLayer.publish(host: host, name: name)
    
 * Stop
         
  		publishLayer.publish(host: host, name: name)
   
 * Status Check
       
  		publishLayer.publishStatus { (status) in
            switch status {
            case .unknown, .disconnected:
                self.btnConnect.setTitle("Publish", for: .normal)
            case .connect:
                self.btnConnect.setTitle("Disconnect", for: .normal)
            case .failed(_):
                self.btnConnect.setTitle("Publish", for: .normal)
            case .publishStart:
                break
            }
   		 }
  

* VideoFPS

		publishLayer.videoFPS = 30
	
```ruby
pod 'MMRtmp'
```

## Author

MillmanY, millmanyang@gmail.com

## License

MMRtmp is available under the MIT license. See the LICENSE file for more info.
