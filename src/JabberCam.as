/**
 * VIDEOSOFTWARE.PRO
 * Copyright 2010 VideoSoftware.PRO
 * All Rights Reserved.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 *  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License along with this program.
 *  If not, see <http://www.gnu.org/licenses/>.
 * 
 *  Author: Our small team and fast growing online community at videosoftware.pro
 */

// ActionScript file

		import flash.events.StatusEvent;
		import flash.events.TextEvent;
		import flash.media.Camera;
		import flash.media.Sound;
		import flash.media.SoundTransform;
		import flash.system.Security;
		import flash.system.SecurityPanel;
		
		import jabbercam.comp.LangFilterFlagRenderer;
		import jabbercam.comp.StartupAlert;
		import jabbercam.lang.AgeIntervals;
		import jabbercam.lang.AutoDisconnect;
		import jabbercam.lang.CustomFilter;
		import jabbercam.lang.LanguageLoader;
		import jabbercam.manager.AbstractCCUserManager;
		import jabbercam.manager.HttpCCUserManager;
		import jabbercam.manager.Red5CCUserManager;
		import jabbercam.manager.events.IdManagerError;
		import jabbercam.manager.events.IdManagerEvent;
		import jabbercam.manager.events.Red5ManagerEvent;
		import jabbercam.utils.Excluder;
		
		import mx.collections.ArrayCollection;
		import mx.controls.listClasses.ListItemRenderer;
		import mx.events.SliderEvent;
		import mx.events.ValidationResultEvent;
		import mx.formatters.DateFormatter;
		import mx.managers.PopUpManager;
		import mx.rpc.events.FaultEvent;
		import mx.rpc.events.ResultEvent;
		import mx.rpc.http.mxml.HTTPService;
		
			
		[Bindable]
		public var connectUrl:String;

		private var DeveloperKey:String;
			
		public var WebServiceUrl:String;
		
		//
		private var mId:String;
		private var mSex:String = "m";
		private var mFilterSex:String ="b";
		private var mOtherId:String;
		private var mUsersOnline:String;
		private var mRejectedConnection:Boolean = false;
		private var mAutoFindActive:Boolean = false;
		private var mOtherSex:String;
		
		private var CONNECTION_TIMEOUT_SECONDS : int = 1;
		private var CONNECTION_TIMEOUT_START : int = 1;
		private var CONNECTION_TIMEOUT_MAX : int = 4;
		
		//
		private var mUsersOnlineTimer:Timer;
		private var mLookupTimeoutTimer:Timer;
		private var mConnectionTimeoutTimer:Timer;
		
		// User management serice
		private var userManager:AbstractCCUserManager;
	
		// this is the connection to stratus
		private var netConnection:NetConnection;	
			
		// after connection to stratus, publish listener stream to wait for incoming call 
		private var listenerStream:NetStream;
			
		// caller's incoming stream that is connected to callee's listener stream
		private var controlStream:NetStream;
			
		// outgoing media stream (audio, video, text and some control messages)
		private var outgoingStream:NetStream;
			
		// incoming media stream (audio, video, text and some control messages)
		private var incomingStream:NetStream;
			
		// ID management serice
		// private var idManager:AbstractIdManager;

		private var remoteVideo:Video;
			
		// login/registration state machine
		[Bindable] private var ccState:int;
			
		private const CCNotConnected:int = 0;
		private const CCConnecting:int = 1;
		private const CCConnected:int = 2
		private const CCRegistered:int = 3;
		private const CCDisconnecting:int = 4;
			
		// call state machine
		[Bindable] private var ccCallState:int;
			
		private const CCCallNotReady:int = 0;
		private const CCCallReady:int = 1;
		private const CCCallCalling:int = 2;
		private const CCCallRinging:int = 3;
		private const CCCallEstablished:int = 4;
		private const CCCallFailed:int = 5;
			
		// available microphone devices
		[Bindable] private var micNames:Array;
		private var micIndex:int = 0;
			
		// available camera deviced
		[Bindable] private var cameraNames:Array;
		private var cameraIndex:int = 0;
						
		// user name is saved in local shared object
		//private var localSO:SharedObject;
					
		//[Bindable] private var remoteName:String = "";
			
		// charts
		private var audioRate:Array = new Array(30);
		[Bindable] private var audioRateDisplay:ArrayCollection = new ArrayCollection();
		private var videoRate:Array = new Array(30);
		[Bindable] private var videoRateDisplay:ArrayCollection = new ArrayCollection();
		private var srtt:Array = new Array(30);
		[Bindable] private var srttDisplay:ArrayCollection = new ArrayCollection();
			
		private var defaultMacCamera:String = "USB Video Class Video";
		
		[Bindable]
		private var lang : LanguageLoader;
		private var appComplete : Boolean = false;
		private var appInitialized : Boolean = false;
		
		private var autoDisconnectTimer : Timer;
		private var autoDisconnectCountdownTimer : Timer;
		
		private var lookupExcludeIds : Array = [];
		
		[Bindable]
		public var serverIsRed5 : Boolean = false;
		
		private var mLookupDelayTimer : Timer;
		
		[Bindable]
		private var banned : Boolean = false;
		
		private var reconnectAttempt : int = 0;
		private var userStop : Boolean = false;
		
		private var gracefulDisconnect : Boolean;
		
		[Bindable]
		private var cameraAllowed : Boolean;
		private var curCamera : Camera;
		private var firstTimeCheckCamera : Boolean = true;
		
		private var partnerUsername : String = "Partner";
		
		private var useSounds : Boolean = true;
		
		[Bindable]
		private var serverName : String;
		
		private var minimumConnectedTime : int = 0;
		private var realMinimumConnectedTime : int = 0;
		private var speedChatConnectedTime : int = 0;
		private var speedChatMinimumConnectedTime : int = 0;
		private var speedDateConnectedTime : int = 0;
		private var speedDateMinimumConnectedTime : int = 0;
		private var enableButtonNextTimer : Timer;
		
		private var red5ConnectMainTimeout : int = 0;
		private var red5ConnectMainTimer : Timer;
		public var red5ConnectUrlB1 : String = "";
		public var red5ConnectUrlB2 : String = "";
		private var currentServerTried : String;
		private var red5TestConnection : NetConnection;
		private var closeForReconnect : Boolean = false;
		
		
		private var ads : Array;
		[Bindable]
		private var currentAd : Object;
		[Bindable]
		private var peerCameraAllowed : Boolean;
		
		
		[Bindable]
		private var languageFilters : Array;
		
		[Bindable]
		private var langFilterValues : Array;
		
		private var badWordsRegExp : RegExp;
		
		private var waitForUsername : Boolean = true;
		private var connectionStatusSet : Boolean = false;
		
		[Bindable]
		private var country : String;
		[Bindable]
		private var countryCode : String;
		[Bindable]
		private var partnerCCode : String;
		[Bindable]
		private var partnerCountry : String;
		
		private var firstStart : Boolean = true;

		[Bindable]
		private var cameraRequired : Boolean = false;

		[Bindable]
		private var loginScreenEnabled : Boolean = false;
		
		private function init() : void {
			settingsLoader.send();
			lang = new LanguageLoader();
			lang.addEventListener(Event.COMPLETE, this.initLanguage);
			this.language.selectedIndex = this.getUsersLanguage();
			lang.loadLanguage(this.language.selectedIndex);
			
			var badwordsLoader : HTTPService = new HTTPService();
			badwordsLoader.resultFormat = "e4x";
			badwordsLoader.url = "jabbercam/badwords.php";
			badwordsLoader.addEventListener(ResultEvent.RESULT, onBadWordsLoaded);
			badwordsLoader.addEventListener(FaultEvent.FAULT, onBadWordsFault);
			badwordsLoader.send();
		}
		
		private function onBadWordsFault(event : FaultEvent) : void {
			
		}
		
		private function onBadWordsLoaded(event : ResultEvent) : void {
			var result : XML = XML(event.target.lastResult);
			
			if(result) {
				var badWordsString : String = "";
				for each(var word : XML in result.word) {
					badWordsString += "("+word.toString().substring(0, 1)+")("+
						word.toString().slice(1, -1)+")("+word.toString().slice(-1)+")"+"|";
				}
				
				badWordsString = badWordsString.slice(0, -1);
				badWordsRegExp = new RegExp(badWordsString, "gim");
			}
		}
		
		private function getUsersLanguage() : int {
			var langId : int = this.language.selectedIndex;
			if(ExternalInterface.available) {
				ExternalInterface.marshallExceptions = true;
				try {
					var lang : String = ExternalInterface.call("function getLanguage() {" + 
							"if(navigator.userAgent.search(/MSIE/)>-1) {" + 
							"navigator.userLanguage.match(/^([a-z]{2})/);" + 
							"} else {" + 
							"navigator.language.match(/^([a-z]{2})/);" + 
							"}" + 
							"return RegExp.$1;" + 
							"}");
					langId = this.lang.codes.indexOf(lang);
					langId = langId==-1?this.language.selectedIndex:langId;
				} catch(e : Error) {
					langId = this.language.selectedIndex;
				}
			}
			
			return langId;
		}
					
		// called when application is loaded            		
		private function initApp():void
		{	
			if(!lang.ready || !settingsLoader.lastResult)
			return;
			
			Excluder.init(lookupExcludeIds);
			
			this.appInitialized = true;
			
			ccState = CCNotConnected;
			ccCallState = CCCallNotReady;
					
			var mics:Array = Microphone.names;
			if (mics)
			{
				micNames = mics;
			}
			else
			{
				status(this.lang.getSimpleProperty("noMicrophone")+"\n");
			}
			
			micVolumeSlider.value = 50;
			
			var mic:Microphone = Microphone.getMicrophone(micIndex);
			if (mic)
			{
				mic.gain = micVolumeSlider.value;
			}
			
			speakerVolumeSlider.value = 0.75;
				
			var cameras:Array = Camera.names;
			if (cameras.length)
			{
				cameraNames = cameras;
				cameraAllowed = true;
			}
			else
			{
				status(this.lang.getSimpleProperty("noCamera")+"\n");
				cameraAllowed = false;
			}
				
			micSelection.selectedIndex = micIndex;
				
			// set Mac default camera
			if (Capabilities.os.search("Mac") != -1)
			{
				for (cameraIndex = 0; cameraIndex < cameras.length; cameraIndex++)
				{
					if (cameras[cameraIndex] == defaultMacCamera)
					{
						break;
					}
				}	
			}
			
			
			
			status(this.lang.getCompoundProperty("welcomeMessage", 0)+"\n");
			status(this.lang.getCompoundProperty("welcomeMessage", 1)+"\n"); 
			status(this.lang.getCompoundProperty("welcomeMessage", 2)+"\n");
			status(this.lang.getCompoundProperty("welcomeMessage", 3)+"\n\n");
			
			onStart();
		}
		
		private function initLanguage(event : Event) : void {
			this.initLabels();
			
			this.defaultMacCamera = this.lang.getSimpleProperty("defaultMacCamera");
			
			if(!this.appInitialized && this.appComplete && this.settingsLoader.lastResult)
			this.initApp();
		}
		
		private function getSettings(event : ResultEvent) : void {
			if(event.result.serverType.toString() == "Red5") {
				this.serverIsRed5 = true;
				this.connectUrl = event.result.red5ConnectUrl;
			} else {
				this.DeveloperKey = event.result.developerKey;
				this.connectUrl = "rtmfp://stratus.adobe.com/"+this.DeveloperKey;
				this.WebServiceUrl = event.result.webServiceUrl;
			}
			
			this.serverName = event.result.serverType.toString();
			
			LanguageLoader.languages = [];
			lang.codes = [];
			for each(var chld : XML in event.result.languages.lang) {
				LanguageLoader.languages.push(chld.label.toString());
				lang.codes.push(chld.code.toString());
			}
			
			this.language.selectedIndex = getUsersLanguage();
			
			languageFilters = [];
			for each(chld in event.result.langFilters.filter) {
				
				languageFilters.push({label:chld.label.toString(), code:chld.code.toString()});
			}
			
			initLanguageSettFilter();
			
			AgeIntervals.intervals = new ArrayCollection();
			for each(var ageInterval : XML in event.result.ageFilterValues.filter) {
				AgeIntervals.intervals.addItem(ageInterval.toString());
			}
			
			AutoDisconnect.labels = [];
			AutoDisconnect.values = [];
			for each(var autoNext : XML in event.result.autoNextValues.autoNext) {
				AutoDisconnect.labels.push(autoNext.label.toString());
				AutoDisconnect.values.push(parseInt(autoNext.autoValue.toString()));
			}
			
			realMinimumConnectedTime = this.minimumConnectedTime = event.result.minimumConnectedTime;
			speedChatConnectedTime = event.result.speedChatConnectedTime;
			speedChatMinimumConnectedTime = event.result.speedChatMinimumConnectedTime;
			speedDateConnectedTime = event.result.speedDateConnectedTime;
			speedDateMinimumConnectedTime = event.result.speedDateMinimumConnectedTime;
			
			if(event.result.hasOwnProperty('red5ConnectUrlB1'))
			red5ConnectUrlB1 = event.result.red5ConnectUrlB1;
			
			if(event.result.hasOwnProperty('red5ConnectUrlB2'))
			red5ConnectUrlB2 = event.result.red5ConnectUrlB2;
			
			if(event.result.hasOwnProperty('red5ConnectMainTimeout'))
			red5ConnectMainTimeout = event.result.red5ConnectMainTimeout;
			
			if(event.result.hasOwnProperty("ads")) {
				this.ads = [];
				for each(var ad : XML in event.result.ads.ad)
				ads.push(ad.toString());
				
				this.ads.sort(function(param1 : Object, param2 : Object):int{return Math.round(Math.random()*2 - 1);});
			}
			
			if(event.result.hasOwnProperty("customFilter1")) {
				CustomFilter.customFilter1Label = event.result.customFilter1.@label.toString();
				var filter1Labels : Array = [];
				var filter1Values : Array = [];
				for each(var filter : XML in event.result.customFilter1.filter) {
					filter1Labels.push(filter.label.toString());
					filter1Values.push(filter.filterValue.toString());
				}
				
				CustomFilter.customFilter1Labels = filter1Labels;
				CustomFilter.customFilter1Values = filter1Values;
			}
			
			if(event.result.hasOwnProperty("customFilter2")) {
				CustomFilter.customFilter2Label = event.result.customFilter2.@label.toString();
				var filter2Labels : Array = [];
				var filter2Values : Array = [];
				for each(var filter2 : XML in event.result.customFilter2.filter) {
					filter2Labels.push(filter2.label.toString());
					filter2Values.push(filter2.filterValue.toString());
				}
				
				CustomFilter.customFilter2Labels = filter2Labels;
				CustomFilter.customFilter2Values = filter2Values;
			}
			
			loginScreenEnabled = event.result.loginScreenEnable.toString() == "true";
			cameraRequired = event.result.cameraRequired.toString() == "true";
			
			if(!this.appInitialized && this.appComplete && this.lang.ready)
			this.initApp();
		}
		
//		private var camera : Camera;
		private function onStart():void 
		{	
			CONFIG::DEBUGGING {
				connect();
			}
			
			if(firstStart) {
			CONFIG::RELEASE {
				var startup : StartupAlert;
				
				var func : Function = function(ev : ValidationResultEvent = null) : void {
					if(loginScreenEnabled) {
						startup.removeEventListener(ValidationResultEvent.VALID, arguments.callee);
						PopUpManager.removePopUp(startup);
						
						myUsername.text = startup.username.text;
					} else {
						myUsername.editable = true;
						ccLabel.visible = ccConnect.visible = ccUsername.visible = false;
						ccLabel.includeInLayout = ccConnect.includeInLayout = ccUsername.includeInLayout = false;
					}
					
					if(cameraRequired && Camera.getCamera().muted) {
						StartupAlert.showSettingsPanel();
						btnStart.enabled = true;
						
						status(lang.getSimpleProperty('waitingForCameraMessage')+"\n");
						status(lang.getSimpleProperty('openSettingsMessageLink')+"\n");
						taChat.addEventListener(TextEvent.LINK, function(ev : TextEvent) : void {
							Security.showSettings(SecurityPanel.PRIVACY);
						});
						
						curCamera = Camera.getCamera();
						curCamera.addEventListener(StatusEvent.STATUS, function(ev : StatusEvent) : void {
							if(!curCamera.muted) {
								curCamera.removeEventListener(StatusEvent.STATUS, arguments.callee);
								
								connect();
								btnStart.enabled = false;
								btnStart.visible = false;
							}
						});
					} else {
						connect();
					}
				};
				
				if(loginScreenEnabled) {
					startup = new StartupAlert();
					startup.addEventListener(ValidationResultEvent.VALID, func);
					
					PopUpManager.addPopUp(startup, this, true);
					PopUpManager.centerPopUp(startup);
				} else {
					func();
				}
			}
			
			var snd : Sound = new Sound(new URLRequest("jabbercam/sounds/welcome.mp3"));
			snd.play(0, 0, new SoundTransform(0.8));
			
			ccState = CCConnecting;
			btnStart.enabled = false;
			} else {
				if(Camera.getCamera().muted)
				Security.showSettings(SecurityPanel.PRIVACY);
				else {
					connect();
					btnStart.enabled = false;
					btnStart.visible = false;
				}
			}
			
			firstStart = false;
		}
		
//		private function onCameraStatus(event : StatusEvent) : void {
//			if(event.code == "Camera.Muted") {
//				requestDisconnect();
//				status(this.lang.getSimpleProperty("cameraRequiredMessage")+"\n");
//			}
//		}
		
		// connecting
		private function connect():void
		{
			clearTaChat();
				
			netConnection = new NetConnection();
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
			if(!serverIsRed5)
			netConnection.connect(connectUrl + "/" + DeveloperKey);
			else {
				
				this.userManager = new Red5CCUserManager();
				this.userManager.addEventListener(Red5ManagerEvent.PEER_CONNECT, this.onPeerConnect);
				
				this.userManager.service = netConnection;
				currentServerTried = connectUrl;
				netConnection.connect(connectUrl, "JabberCamApp");
			}
					
			status(this.lang.getCompoundProperty("enteringCarouselMessage", 0)+"\n");
			status(this.lang.getCompoundProperty("enteringCarouselMessage", 1).replace(/\[x\]/, 
				serverName));
		}
		
		private function netConnectionHandler(event:NetStatusEvent):void
		{
			trace("netConnectionHandler "+event.info.code);
            switch (event.info.code)
            {
                case "NetConnection.Connect.Success":
//                if(reconnectAttempt==0)
                connectSuccess();
                if(currentServerTried != connectUrl) {
                	if(red5ConnectMainTimeout) {
                		if(!red5ConnectMainTimer) {
                			red5ConnectMainTimer = new Timer(60 * 1000 * red5ConnectMainTimeout);
                			red5ConnectMainTimer.addEventListener(TimerEvent.TIMER, testMainRed5Server);
                		}
                		
                		red5ConnectMainTimer.reset();
                		red5ConnectMainTimer.start();
                	}
                } else if(red5ConnectMainTimer) {
                	red5ConnectMainTimer.stop();
                }
//                else
//                reconnectSuccess();
                break;
                    	
                case "NetStream.Connect.Success":
//                    btnSend.enabled = true;
                   if (mConnectionTimeoutTimer) {	
              			mConnectionTimeoutTimer.stop();
        				mConnectionTimeoutTimer = null;
                   }
                break;
                    
                 case "NetConnection.Connect.Closed":
                 
                 	if(closeForReconnect || banned || userStop || !serverIsRed5) {
                 		userStop = false;
						btnNext.enabled = false;
						btnStart.enabled = false;
						btnStop.enabled = false;
						
						if(!closeForReconnect) {
							status(this.lang.getCompoundProperty("errorConnectingToBackend", 0)+"\n");
							status("Disconnected from server"+"\n");
							status(this.lang.getCompoundProperty("errorConnectingToBackend", 1)+"\n");
						}
						closeForReconnect = false;
						break;
                 	}
                	
               
                case "NetConnection.Connect.Rejected":	
                case "NetConnection.Connect.Failed":
                	if(currentServerTried == connectUrl && red5ConnectUrlB1 != "") {
                		currentServerTried = red5ConnectUrlB1;
                	} else if(currentServerTried == red5ConnectUrlB1 && red5ConnectUrlB2 != "") {
                		currentServerTried = red5ConnectUrlB2;
                	} else {
                		currentServerTried = "";
                	}
                	
                	if(currentServerTried != "") {
                		callLater(netConnection.connect, [currentServerTried, "JabberCamApp"]);
            			btnNext.enabled = false;
            			btnStop.enabled = false;
            			ccState = CCConnecting;
            			break;
                	}
                	
                    status(this.lang.getSimpleProperty("unableToConnectMessage") + connectUrl + "\n");
                    break;
                    	
                case "NetStream.Connect.Closed":
               	 	Excluder.excludeFor(event.info.stream.farID);
                    if (event.info.stream.farID == mOtherId)
                    {
                    	partnerDisconnected();
                    }
                    break;
             	}
         	}
         	
        private function testMainRed5Server(event : TimerEvent) : void {
        	if(!red5TestConnection) {
        		red5TestConnection = new NetConnection();
        		red5TestConnection.addEventListener(NetStatusEvent.NET_STATUS, onRed5TestConnectionStatus);
        		red5TestConnection.client = new Red5CCUserManager();
        	}
        	
        	red5TestConnection.connect(connectUrl, "JabberCamApp");
        }
        
        private function onRed5TestConnectionStatus(event : NetStatusEvent) : void {
        	switch(event.info.code) {
        		case "NetConnection.Connect.Success":
        		
        			red5TestConnection.close();
        			red5TestConnection.removeEventListener(NetStatusEvent.NET_STATUS, 
        				onRed5TestConnectionStatus);
        			red5TestConnection = null;
        			
        			currentServerTried = connectUrl;
        			closeForReconnect = true;
        			netConnection.close();
        			callLater(netConnection.connect, [currentServerTried, "JabberCamApp"]);
        			btnNext.enabled = false;
        			btnStop.enabled = false;
        			ccState = CCConnecting;
        			
        			red5ConnectMainTimer.stop();
        			break;
        			
        		case "NetConnection.Connect.Rejected":
        		case "NetConnection.Connect.Failed":
        			
        	}
        }
         	
//        private function reconnectSuccess() : void {
//        	reconnectAttempt = 0;
//        	mId = (userManager as Red5CCUserManager).id;
//        	
//        	if(!mId || mId == "") {
//        		btnStart.enabled = btnStop.enabled = btnNext.enabled = false;
//        		return;
//        	}
//        	
//        	
//        	lblID.text = this.lang.getSimpleProperty("yourIdLabel")+mId;
//        	
//        	ccState = CCRegistered;
//        	
//        	userManager.register(mId, ["sex", mSex, "age", age.value, "cam", cameraAllowed.toString()],
//            	["sex", mFilterSex, "age", lookupAge.value, "cam",
//            		cbCameraOnOnly.selected?"true":"0"]); 
//        	
//        	completeRegistration();
//        	
//        	btnStart.enabled = false;
//        	if(cbAutoFindNext.selected){
//        		btnNext.enabled = false;
//        		findPartner();
//        	}
//        }
         	
        private function connectSuccess():void
        {
        	
        	if(!serverIsRed5)
        	mId = netConnection.nearID;
        	else
        	mId = (userManager as Red5CCUserManager).id;
        	
        	if(!mId || mId == "" || mId == "null") {
            	gotBanned((userManager as Red5CCUserManager).banTime);
            	banned = true;
            	return;
        	}
        	
        	if(!this.serverIsRed5)
        	userManager = new HttpCCUserManager();
        	
            userManager.addEventListener("registerSuccess", idManagerEvent);
            userManager.addEventListener("registerFailure", idManagerEvent);
            userManager.addEventListener("updateSexSuccess", idManagerEvent);
            userManager.addEventListener("updateAgeSuccess", idManagerEvent);
            userManager.addEventListener("usersOnlineSuccess", idManagerEvent);
            userManager.addEventListener("updateSexFailure", idManagerEvent);
            userManager.addEventListener("lookupFailure", idManagerEvent);
            userManager.addEventListener("lookupSuccess", idManagerEvent);
            userManager.addEventListener("idManagerError", idManagerEvent);
            userManager.addEventListener(IdManagerEvent.PEER_BANNED, idManagerEvent);
            userManager.addEventListener(IdManagerEvent.FILTER_SUCCESS, idManagerEvent);
            userManager.addEventListener(IdManagerEvent.REPORT_SUCCESS, idManagerEvent);
            
            ccState = CCConnected;
        	status(this.lang.getSimpleProperty("successMessage")+"\n\n");
        	
        	lblID.text = this.lang.getSimpleProperty("yourIdLabel")+mId;
             
            if(!this.serverIsRed5) 	
            userManager.service = WebServiceUrl;
            
            var settings : Array = ["sex", mSex=="b"?"0":mSex, "age", age.value, "cam",
            	cameraAllowed?"true":"0", "lang", langSetting.selectedItem.code == null?"0":
				langSetting.selectedItem.code, "uname", myUsername.text];
				
			var prefs : Array = ["sex", mFilterSex=="b"?"0":mFilterSex, "age", lookupAge.value, "cam",
            		cbCameraOnOnly.selected?"true":"0", "lang", langFilter.selectedItem.code == null?"0":
				langFilter.selectedItem.code];
				
			if(CustomFilter.customFilter1Values && CustomFilter.customFilter1Values.length > 0) {
				settings.push("cflt1");
				settings.push(CustomFilter.customFilter1Values[customFilter1Setting.selectedIndex]);
				prefs.push("cflt1");
				prefs.push(CustomFilter.customFilter1Values[customFilter1Pref.selectedIndex]);
			}
			
			if(CustomFilter.customFilter2Values && CustomFilter.customFilter2Values.length > 0) {
				settings.push("cflt2");
				settings.push(CustomFilter.customFilter2Values[customFilter2Setting.selectedIndex]);
				prefs.push("cflt2");
				prefs.push(CustomFilter.customFilter2Values[customFilter2Pref.selectedIndex]);
			}
            userManager.register(mId, settings, prefs);           
        }
        
        private function partnerDisconnected():void
		{
			if (ccCallState == CCCallEstablished)
			{
				if(!gracefulDisconnect) {
					userManager.markUser(mOtherId);
				}
				
				gracefulDisconnect = false;
				
				status(this.lang.getCompoundProperty("partnerDisconnectMessage", 0)+"\n");
            	status(this.lang.getCompoundProperty("partnerDisconnectMessage", 1)+"\n\n");
				requestDisconnect();
   			}
		}
        
        private function idManagerEvent(e:Event):void
		{			
			if (e.type == "registerSuccess")
			{
				if (ccState != CCRegistered) {
					status(this.lang.getSimpleProperty("registerSuccessMessage")+"\n");
					if (!cbAutoFindNext.selected) status(this.lang.getSimpleProperty("lookForPartnersMessage")+"\n\n");
					ccState = CCRegistered;
					countryCode = (e as IdManagerEvent).ccode;
					country = (e as IdManagerEvent).country;
					
					completeRegistration();
				} else {
					if (mAutoFindActive) {
						findPartner();
					}
				}
			}
			else if (e.type == "updateSexSuccess")
			{
				status(this.lang.getSimpleProperty("updateSexSuccess"));
			}
			else if (e.type == "updateAgeSuccess")
			{
				switch(age.value) {
					case 0:
						status(this.lang.getCompoundProperty("updateAgeSuccess", 0));
						break;
					case 1:
					case 2:
						status(this.lang.getCompoundProperty("updateAgeSuccess", 1) + age.labels[age.value]);
						break;
					case 3:
						status(this.lang.getCompoundProperty("updateAgeSuccess", 2) + "41");
						break;
				}
				
			} else if (e.type == "usersOnlineSuccess")
			{
				var u:IdManagerEvent = e as IdManagerEvent;
				mUsersOnline = u.id;
				lblUsersOnline.htmlText = "<font color='#ffffff'><b>"+mUsersOnline+"</b></font>"+this.lang.getSimpleProperty("usersOnlineLabel");
				if (mAutoFindActive) {
					findPartner();
				}
			}
			else if (e.type == "lookupSuccess")
			{
				// Lookup query response
				if (mLookupTimeoutTimer)
				{
					mLookupTimeoutTimer.stop();
					mLookupTimeoutTimer = null;
				}
				var i:IdManagerEvent = e as IdManagerEvent;
				mOtherId = i.id;
				if ((mOtherId == mId) || (mOtherId == "")) {
					if ((cbAutoFindNext.selected) && (ccCallState != CCCallEstablished)) {
						mAutoFindActive = true;
						findPartner();
					} else {
						btnNext.enabled = true;
						status(this.lang.getSimpleProperty("noUsersReadyMessage")+"\n");
						if (!cbAutoFindNext.selected) status(this.lang.getSimpleProperty("checkAutoFindMessage"));
					}
				} else {
					mAutoFindActive = false;
					status(this.lang.getSimpleProperty("connectingStatus")+"\n");
					ccCallState = CCCallCalling;
					lblOtherId.text = this.lang.getSimpleProperty("otherIdLabel")+mOtherId;
					connectToOther();
				}
			}
			else if(e.type == "peerBanned") {
				if(ccCallState == CCCallEstablished) {
					if(outgoingStream) {
						outgoingStream.send("gotBanned", (e as IdManagerEvent).value);
					}
				}
			}
			else if(e.type == IdManagerEvent.FILTER_SUCCESS) {
				var msg : String = lang.getSimpleProperty("filterSuccessMessage");
				msg = msg.replace(/\$x/g, (e as IdManagerEvent).value);
				status(msg+"\n");
			} 
			else if(e.type == IdManagerEvent.REPORT_SUCCESS) {
				var msg2 : String = lang.getSimpleProperty("reporterReportSuccessMessage");
				msg2 = msg2.replace(/\$x/g, (e as IdManagerEvent).value);
				msg2 = msg2.replace(/\$y/g, (e as IdManagerEvent).reportTotal);
				
				status(msg2+"\n");
				
				if(ccCallState == CCCallEstablished) {
					if(outgoingStream) {
						outgoingStream.send("gotReported", (e as IdManagerEvent).value, 
							(e as IdManagerEvent).reportTotal);
					}
				}
			}
			else
			{
				// all error messages ar IdManagerError type
				var error:IdManagerError = e as IdManagerError;
				
				if (error.description == "lookup has no result") {
					if (mLookupTimeoutTimer) 
					{
						mLookupTimeoutTimer.stop();
						mLookupTimeoutTimer = null;
					}
					status(this.lang.getSimpleProperty("nobodyFoundMessage")+"\n");
					ccConnect.enabled = btnNext.enabled = !cbAutoFindNext.selected;
					if (rbSexFemale.selected) {
						status(this.lang.getSimpleProperty("lookingForFemaleOnly")+"\n");
					} else if (rbSexMale.selected) {
						status(this.lang.getSimpleProperty("lookingForMaleOnly")+"\n");
					}
					if(lookupAge.value > 0) {
						status(this.lang.getSimpleProperty("lookingForSpecificAgeOnly")+"\n");
					}
//					if (cbAutoFindNext.selected) {
//						status (this.lang.getSimpleProperty("switchAutoFindOffMessage"));
//						cbAutoFindNext.selected = false;
//						mAutoFindActive = false;
//					}
					if(cbAutoFindNext.selected) {
						mAutoFindActive = true;
						if(mLookupDelayTimer) {
							mLookupDelayTimer.stop();
							mLookupDelayTimer.reset();
						} else {
							mLookupDelayTimer = new Timer(2000, 1);
							mLookupDelayTimer.addEventListener(TimerEvent.TIMER_COMPLETE, findPartnerDelay);
						}
						
						mLookupDelayTimer.start();
					} else
					status(this.lang.getSimpleProperty("spinRouletteMessage"));
				} else {
					
					if(error.description == "banned") {
						gotBanned(parseInt((error as IdManagerError).data.toString()));
					} else if(error.description == "blocked") {
						blocked();
					} else {
						status(this.lang.getCompoundProperty("errorConnectingToBackend", 0)+"\n");
						status(error.description+"\n");
						status(this.lang.getCompoundProperty("errorConnectingToBackend", 1)+"\n");
					}
				}
				//onDisconnect();
			}
		}
		
		private function findPartnerDelay(event : TimerEvent) : void {
			findPartner();
		}
		
		private function onUsersOnlineTimer(e:TimerEvent):void
		{
			userManager.usersOnline();
			switch (ccCallState)
			{
				case CCCallNotReady:
				lblCcCallState.text = this.lang.getSimpleProperty("callNotReadyStatus");
				break;
				
				case CCCallReady:
				lblCcCallState.text = this.lang.getSimpleProperty("callReadyStatus");
				break;
				
				case CCCallEstablished:
				lblCcCallState.text = this.lang.getSimpleProperty("callEstablishedStatus");
				break;
				
				case CCCallCalling:
				lblCcCallState.text = this.lang.getSimpleProperty("callingStatus");
			}
		}
		
		private function completeRegistration():void
		{
			if(curCamera) {
				curCamera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
			}
			curCamera = Camera.getCamera(cameraIndex.toString());
			curCamera.addEventListener(StatusEvent.STATUS, onCameraStatus);
			if(!curCamera.muted != cameraAllowed) {
				cameraAllowed = !curCamera.muted;
				cameraChangedStatus();
			}
			
			userManager.usersOnline();
			mUsersOnlineTimer = new Timer(1000 * 10);
			mUsersOnlineTimer.addEventListener(TimerEvent.TIMER, onUsersOnlineTimer);
            mUsersOnlineTimer.start();
            
            onPeerCameraAllowed(peerCameraAllowed);
            
			// start the control stream that will listen to incoming calls
			if(!serverIsRed5) {
				listenerStream = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
				listenerStream.addEventListener(NetStatusEvent.NET_STATUS, listenerHandler);
				listenerStream.publish("ChatRouletteClone");
							
				var c:Object = new Object();
				c.onPeerConnect = function(caller:Object):Boolean // called on the responder side
				{
					trace("onPeerConnect ccCallState: "+ccCallState);
					if ((ccCallState != CCCallEstablished) && (ccCallState != CCCallCalling)) // only accept incoming calls when no active call
					{
						gracefulDisconnect = false;										
						mAutoFindActive = false;
						btnNext.enabled = false;
						// Playing media from the requester
						incomingStream = new NetStream(netConnection, caller.farID);
						incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
						incomingStream.play("media-requester");
						mOtherId = incomingStream.farID;
						lblOtherId.text = mOtherId;
						
						
						// set volume for incoming stream
						var st:SoundTransform = new SoundTransform(speakerVolumeSlider.value); // TODO: Volume controls
						incomingStream.soundTransform = st;
									
						incomingStream.receiveAudio(true);
						incomingStream.receiveVideo(true);
						
						remoteVideo = new Video();
						remoteVideo.width = 320;
						remoteVideo.height = 240;
						remoteVideo.attachNetStream(incomingStream);
						vidOther.addChild(remoteVideo);
						
						var i:Object = new Object;					
						i.onIm = onMessageReceived;
						
						i.sendSex = function(sex:String):void
						{
							mOtherSex = sex;
							if ((mOtherSex == "m") && (mFilterSex != "m") && (mFilterSex != "b"))
							{
								status(lang.getSimpleProperty("partnerNotFemaleError")+"\n");
								requestDisconnect();
								return;
							}
							if ((mOtherSex == "f") && (mFilterSex != "f") && (mFilterSex != "b"))
							{
								status(lang.getSimpleProperty("partnerNotMaleError")+"\n");
								requestDisconnect();
								return;	
							}
						}
						i.sendAge = function(age : int) : void {
							if(lookupAge.value > 0 && age != lookupAge.value) {
								status(lang.getSimpleProperty("partnerNotRequestedAge")+"\n");
								requestDisconnect();
								return;
							}
						};
						i.gotBanned = gotBanned;
						i.gracefullyDisconnect = function(id : String) : void {
							gracefulDisconnect = true;
						};
						i.sendUsername = partnerUsernameReceived;
						i.gotReported = gotReported;
						i.onPeerCameraAllowed = onPeerCameraAllowed;
						
						incomingStream.client = i;
						
						if(outgoingStream) {
							outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
							try {
								outgoingStream.close();
							} catch(e : Error) {
								
							}
						}
						// Publishing my own media
						outgoingStream = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
						outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
						outgoingStream.publish("media-responder");
	
						startVideo();
						startAudio();
						
						clearTaChat();
						setConnectionSuccess();
											
						setCallEstablished();
						return true;
					}
					trace("Rejected incomming connection in completeRegistration()");
					return false;
				}
							
				listenerStream.client = c;
			} else {
//				outgoingStream = new NetStream(netConnection);
//				outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
//				outgoingStream.publish(mId);
//
//				startVideo();
//				startAudio();
			}
			
			btnStop.enabled = true;		
			btnNext.enabled = true;
			ccCallState = CCCallReady;
			
			
			if(useSounds) {
				var snd : Sound = new Sound(new URLRequest("jabbercam/sounds/instruction.mp3"));
				snd.addEventListener(IOErrorEvent.IO_ERROR, ioError);
				snd.play();
			}
		}
		
		private function setConnectionSuccess() : void {
			if(!waitForUsername && !connectionStatusSet) {
				var msg : String =  lang.getCompoundProperty("connectionSuccess", 0).replace(/\[x\]/,
					partnerUsername).replace(/\[y\]/, partnerCountry)+"\n";
				status(msg);
				status(lang.getCompoundProperty("connectionSuccess", 1)+"\n\n");
				
				connectionStatusSet = true;
			}
		}
		
		private function partnerUsernameReceived(username : String, ccode : String = "", country : String = "") : void {
			partnerUsername = username;
			partnerCCode = ccode;
			partnerCountry = country;
			waitForUsername = false;
			
			setConnectionSuccess();
		}
		
		// Peer connect handler: only red5
		private function onPeerConnect(event : Red5ManagerEvent) : void {
			if ((ccCallState != CCCallEstablished) && (ccCallState != CCCallCalling)) // only accept incoming calls when no active call
			{													
				mAutoFindActive = false;
				btnNext.enabled = false;
				// Playing media from the requester
				incomingStream = new NetStream(netConnection);
				incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
				incomingStream.play(event.peerId);
				mOtherId = event.peerId;
				lblOtherId.text = mOtherId;
				
				
				// set volume for incoming stream
				var st:SoundTransform = new SoundTransform(speakerVolumeSlider.value); // TODO: Volume controls
				incomingStream.soundTransform = st;
							
				incomingStream.receiveAudio(true);
				incomingStream.receiveVideo(true);
				
				if(!remoteVideo) {
					remoteVideo = new Video();
					remoteVideo.width = 320;
					remoteVideo.height = 240;
					vidOther.addChild(remoteVideo);
				}
				
				remoteVideo.attachNetStream(incomingStream);
				
				var i:Object = new Object;					
				i.onIm = onMessageReceived;
				
				i.sendSex = function(sex:String):void
				{
					mOtherSex = sex;
					if ((mOtherSex == "m") && (mFilterSex != "m") && (mFilterSex != "b"))
					{
						status(lang.getSimpleProperty("partnerNotFemaleError")+"\n");
						requestDisconnect();
						return;
					}
					if ((mOtherSex == "f") && (mFilterSex != "f") && (mFilterSex != "b"))
					{
						status(lang.getSimpleProperty("partnerNotMaleError")+"\n");
						requestDisconnect();
						return;	
					}
				};
				i.sendAge = function(age : int) : void {
					if(lookupAge.value > 0 && age != lookupAge.value) {
						status(lang.getSimpleProperty("partnerNotRequestedAge")+"\n");
						requestDisconnect();
					}
				};
				i.sendUsername = partnerUsernameReceived;
				i.gotReported = gotReported;
				i.onPeerCameraAllowed = onPeerCameraAllowed;
				
				incomingStream.client = i;
				
				if(outgoingStream) {
					outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
					try {
						outgoingStream.close();
					} catch(e : Error) {
						
					}
				}
				outgoingStream = new NetStream(netConnection);
				outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
				outgoingStream.publish(mId);

				startVideo();
				startAudio();
				
				clearTaChat();
				setConnectionSuccess();
									
				setCallEstablished();
			}
		}
		
		private function setCallEstablished():void
		{
			ccCallState = CCCallEstablished;
			mAutoFindActive = false;
			
			if(!serverIsRed5)
			userManager.connectToPeer(mOtherId);
			
			if(autoDisconnectTimer) {
				autoDisconnectTimer.reset();
				autoDisconnectTimer.start();
			}
			
			if(autoDisconnectCountdownTimer) {
				autoDisconnectCountdownTimer.reset();
				autoDisconnectCountdownTimer.start();
				
				setCountdown(null);
			}
			
			if(minimumConnectedTime) {
				btnNext.enabled = false;
				
				if(!enableButtonNextTimer) {
					enableButtonNextTimer = new Timer(minimumConnectedTime * 1000, 1);
					enableButtonNextTimer.addEventListener(TimerEvent.TIMER_COMPLETE, enableButtonNext);
				}
				
				enableButtonNextTimer.reset();
				enableButtonNextTimer.start();
				
			} else
			btnNext.enabled = true;
			
			if (mLookupTimeoutTimer) {
				mLookupTimeoutTimer.stop();
				mLookupTimeoutTimer = null;
			}
			if (mConnectionTimeoutTimer) {
				mConnectionTimeoutTimer.stop();
				mConnectionTimeoutTimer = null;
			}
			
			if(mLookupDelayTimer) {
				mLookupDelayTimer.stop();
				mLookupDelayTimer.reset();
			}
			
			Excluder.reinclude(mOtherId);
			
			if(useSounds) {
				var snd : Sound = new Sound(new URLRequest("jabbercam/sounds/connected.mp3"));
				snd.addEventListener(IOErrorEvent.IO_ERROR, ioError);
				snd.play();
			}
		}
		
		private function listenerHandler(event:NetStatusEvent):void
		{
			switch(event.info.code) {
				
			}
		}
		
		private function controlHandler(event:NetStatusEvent):void
		{
			trace("controlHandler ==> "+event.info.code);
			switch (event.info.code)
			{
				case "NetStream.Play.Failed":
				Excluder.excludeFor(mOtherId);
				
				if(mConnectionTimeoutTimer) {
					mConnectionTimeoutTimer.stop();
					mConnectionTimeoutTimer = null;
				}
				
				if ((cbAutoFindNext.selected) && (ccCallState != CCCallEstablished))
				{
					findPartner();
				} else
				{ 
					status(this.lang.getSimpleProperty("allPartnersBusyMessage"));
					btnNext.enabled = true;
				}  
				break;
			}
		}
		
		private function incomingStreamHandler(event:NetStatusEvent):void
		{
			trace("incomingStreamHandler ==> "+event.info.code);
        	switch (event.info.code)
        	{
        		case "NetStream.Play.UnpublishNotify":
					partnerDisconnected();
					break;
				case "NetStream.Play.Start":
//					if(serverIsRed5)
//						btnSend.enabled = true;
        			break;
         	}
		}
		
		private function outgoingStreamHandler(event:NetStatusEvent):void
		{
			trace("outgoingStreamHandler ==> "+event.info.code);
			   switch (event.info.code)
            	{
            		case "NetStream.Play.Start":
            			outgoingStream.send("sendSex", mSex);
            			outgoingStream.send("sendAge", age.value);
            			if(myUsername.text != this.lang.getSimpleProperty("youText"))
            			outgoingStream.send("sendUsername", myUsername.text, countryCode, country);
            			
            			outgoingStream.send("onPeerCameraAllowed", cameraAllowed);
            			break;
            		case "NetStream.Publish.Start":
            			if(serverIsRed5) {
	            			outgoingStream.send("sendSex", mSex);
	            			outgoingStream.send("sendAge", age.value);
	            			if(myUsername.text != this.lang.getSimpleProperty("youText"))
	            			outgoingStream.send("sendUsername", myUsername.text, countryCode, country);	
	            			
	            			outgoingStream.send("onPeerCameraAllowed", cameraAllowed);
            			}
            			break;
            		case "NetStream.Publish.BadName":
            			break;
            	}
		}
			
        private function findPartner():void
        {
        	if (ccCallState == CCCallEstablished) {
        		clearTaChat();
        		requestDisconnect();
//        		if(!cbAutoFindNext.selected)
//        		status(this.lang.getSimpleProperty("youDisconnectedPartnerMessage")+"\n");
        		
        		callLater(findPartner);
        	} else {
        		clearTaChat();
        		if (cbAutoFindNext.selected) {
        			status(this.lang.getSimpleProperty("autoFindNextActive"));
        		}
        		status(this.lang.getSimpleProperty("tryingToFindSomeoneMessage"));
        		if (rbSexFemale.selected && rbSexMale.selected || !rbSexFemale.selected && !rbSexMale.selected) {
        			mFilterSex = "b";
        		} else if (rbSexFemale.selected) {
        			mFilterSex = "f";
        		} else if (rbSexMale.selected) {
        			mFilterSex = "m"
        		}
        		if (ccCallState != CCCallEstablished) {
        			if(mLookupDelayTimer) {
        				mLookupDelayTimer.stop();
        				mLookupDelayTimer.reset();
        			}
        			
        			if (!mLookupTimeoutTimer)
        			{
        				mLookupTimeoutTimer = new Timer(1000 * 17, 1);
						mLookupTimeoutTimer.addEventListener(TimerEvent.TIMER, onLookupTimeoutTimer);
            			mLookupTimeoutTimer.start();
           			}
           			lblOtherId.text = "";
        			userManager.lookup(mFilterSex, lookupAge.value, lookupExcludeIds);
        		}
        	}
        }
        
        private function findPartnerByName():void
        {
        	if (ccCallState == CCCallEstablished) {
        		clearTaChat();
        		requestDisconnect();
//        		if(!cbAutoFindNext.selected)
//        		status(this.lang.getSimpleProperty("youDisconnectedPartnerMessage")+"\n");
        		
        		callLater(findPartnerByName);
        	} else {
        		clearTaChat();
        		if (cbAutoFindNext.selected) {
        			status(this.lang.getSimpleProperty("autoFindNextActive"));
        		}
        		status(this.lang.getSimpleProperty("tryingToFindSomeoneMessage"));
        		
        		if (ccCallState != CCCallEstablished) {
        			if(mLookupDelayTimer) {
        				mLookupDelayTimer.stop();
        				mLookupDelayTimer.reset();
        			}
        			
        			if (!mLookupTimeoutTimer)
        			{
        				mLookupTimeoutTimer = new Timer(1000 * 17, 1);
						mLookupTimeoutTimer.addEventListener(TimerEvent.TIMER, onLookupTimeoutTimer);
            			mLookupTimeoutTimer.start();
           			}
           			lblOtherId.text = "";
        			userManager.lookupByName(ccUsername.text);
        			ccUsername.text = "";
        		}
        	}
        }
        
        private function onLookupTimeoutTimer(e:TimerEvent):void
        {
        	if (ccCallState == CCCallEstablished) return;
 			if (mLookupTimeoutTimer) {
 				mLookupTimeoutTimer.stop();
				mLookupTimeoutTimer = null;
 			}
 			if(mLookupDelayTimer) {
 				mLookupDelayTimer.stop();
 				mLookupDelayTimer.reset();
 			}
			if ((cbAutoFindNext.selected) && (ccCallState != CCCallEstablished)) {
				mAutoFindActive = true;
				findPartner();
			} else {
				btnNext.enabled = true;
				ccConnect.enabled = true;
				if (ccCallState != CCCallEstablished) {
					status(this.lang.getSimpleProperty("nobodyFoundInTimeMessage")+"\n");
					if (!cbAutoFindNext.selected) status(this.lang.getSimpleProperty("checkAutoFindMessage")+"\n");
				} else
				{
					if (mLookupTimeoutTimer) {
						mLookupTimeoutTimer.stop();
						mLookupTimeoutTimer = null;
					}
				}
			}       	
        }
        
        private function onConnectionTimeoutTimer(e:TimerEvent):void {
        	if (ccCallState == CCCallEstablished) {
        		CONNECTION_TIMEOUT_SECONDS = CONNECTION_TIMEOUT_START;
        		return;
        	}
        	
			if (mConnectionTimeoutTimer)
        	{
        		mConnectionTimeoutTimer.stop();
        		mConnectionTimeoutTimer = null;
        	}
        	
        	if ((cbAutoFindNext.selected) && (ccCallState != CCCallEstablished)) {
        		if(CONNECTION_TIMEOUT_SECONDS >= CONNECTION_TIMEOUT_MAX) {
	        		CONNECTION_TIMEOUT_SECONDS = CONNECTION_TIMEOUT_START;
	        	} else {
	        		mAutoFindActive = true;
	        		CONNECTION_TIMEOUT_SECONDS *= 2;
	        		connectToOther();
	        		return;
	        	}
				mAutoFindActive = true;
				
				Excluder.excludeFor(mOtherId);
				
				markUserAndFindNewPartner();
			} else {
				if(CONNECTION_TIMEOUT_SECONDS >= CONNECTION_TIMEOUT_MAX) {
					CONNECTION_TIMEOUT_SECONDS = CONNECTION_TIMEOUT_START;
					btnNext.enabled = true;
					ccConnect.enabled = true;
					status(this.lang.getSimpleProperty("connectionTimeoutMessage")+"\n");
					lblOtherId.text = "";
					if (!cbAutoFindNext.selected)
					{
						status(this.lang.getSimpleProperty("checkAutoFindMessage")+"\n");
					}
					
					ccCallState = CCCallReady;
					Excluder.excludeFor(mOtherId);
					
					userManager.markUser(mOtherId);
				} else {
					CONNECTION_TIMEOUT_SECONDS *= 2;
					connectToOther();
				}
			}
        }
        
        private function markUserAndFindNewPartner() : void {
        	if(userManager is HttpCCUserManager) {
        		userManager.addEventListener(IdManagerEvent.USER_MARK_RESPONSE,
        			function(ev : IdManagerEvent) : void {
        				ev.currentTarget.removeEventListener(IdManagerEvent.USER_MARK_RESPONSE,
        					arguments.callee);
        					
        				findPartner();
        			});
        		
        		userManager.markUser(mOtherId);
        	} else {
        		findPartner();
        	}
        }
        
        private function connectToOther():void
        {				
			if (mOtherId == null || mOtherId.length != 64)
			{	
				ccCallState = CCCallReady;
				return;
			}
			
			ccCallState = CCCallCalling;
			mAutoFindActive = false;
			
			trace("connectToOther() line 624");	
			// caller subsrcibes to callee's listener stream 
			if(!serverIsRed5) {
				gracefulDisconnect = false;
				controlStream = new NetStream(netConnection, mOtherId);
				controlStream.addEventListener(NetStatusEvent.NET_STATUS, controlHandler);
				controlStream.play("ChatRouletteClone");
							
				// caller publishes media stream
				if(outgoingStream) {
					outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
					try {
						outgoingStream.close();
					} catch(e : Error) {
						
					}
				}
				outgoingStream = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
				outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
				outgoingStream.publish("media-requester");
							
				var o:Object = new Object
				o.onPeerConnect = function(caller:NetStream):Boolean // called on the requester side
				{
																		
					// caller subscribes to callee's media stream
					incomingStream = new NetStream(netConnection, caller.farID);
					incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
					incomingStream.play("media-responder");
					
					// set volume for incoming stream
					var st:SoundTransform = new SoundTransform(speakerVolumeSlider.value); // TODO: volume settings
					incomingStream.soundTransform = st;
					
					incomingStream.receiveAudio(true);
					incomingStream.receiveVideo(true);
					
					var i:Object = new Object;
					i.onIm = onMessageReceived;
					i.sendSex = function(sex:String):void
					{
						mOtherSex = sex;
					}
					i.sendAge = function(age:int): void {
//						lookupAge.value = age;
					}
					i.gotBanned = gotBanned;
					i.gracefullyDisconnect = function(id : String) : void {
						trace('gracefullyDisconnect: '+id);
						gracefulDisconnect = true;
					};
					i.sendUsername = partnerUsernameReceived;
					i.gotReported = gotReported;
					i.onPeerCameraAllowed = onPeerCameraAllowed;
					
					incomingStream.client = i;
					
					if(!remoteVideo) {
						remoteVideo = new Video();
						remoteVideo.width = 320;
						remoteVideo.height = 240;
						vidOther.addChild(remoteVideo);
					}
					
					remoteVideo.attachNetStream(incomingStream);
					
					clearTaChat();
					setConnectionSuccess();
					setCallEstablished();
					return true;
				}
				outgoingStream.client = o;
				
				mConnectionTimeoutTimer = new Timer(1000 * CONNECTION_TIMEOUT_SECONDS, 1);
				mConnectionTimeoutTimer.addEventListener(TimerEvent.TIMER, onConnectionTimeoutTimer);
	            mConnectionTimeoutTimer.start();
			} else {
				if(outgoingStream) {
					outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
					try {
						outgoingStream.close();
					} catch(e : Error) {
						
					}
				}
				outgoingStream = new NetStream(netConnection);
				outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
				outgoingStream.publish(mId);
				
				(userManager as Red5CCUserManager).connectToPeer(mOtherId);
				
				incomingStream = new NetStream(netConnection);
				incomingStream.addEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
				incomingStream.play(mOtherId);
				
				// set volume for incoming stream
				var st:SoundTransform = new SoundTransform(speakerVolumeSlider.value); // TODO: volume settings
				incomingStream.soundTransform = st;
				
				incomingStream.receiveAudio(true);
				incomingStream.receiveVideo(true);
				
				var i:Object = new Object;
				i.onIm = onMessageReceived;
				i.sendSex = function(sex:String):void
				{
					mOtherSex = sex;
				}
				i.sendAge = function(age:int): void {
//					lookupAge.value = age;
				};
				i.sendUsername = partnerUsernameReceived;
				i.gotReported = gotReported;
				i.onPeerCameraAllowed = onPeerCameraAllowed;
				
				incomingStream.client = i;
				
				if(!remoteVideo) {
					remoteVideo = new Video();
					remoteVideo.width = 320;
					remoteVideo.height = 240;
					vidOther.addChild(remoteVideo);
				}
				
				remoteVideo.attachNetStream(incomingStream);
				
				clearTaChat();
				setConnectionSuccess();
				setCallEstablished();
			}

			startAudio();					
			startVideo();
        }
        
        private function gotBanned(banTime : int) : void {
        	var msg : String = lang.getSimpleProperty("bannedMessage");
        	msg = msg.replace(/\$x/g, banTime);
        	status(msg + "\n");
        	
			requestDisconnect2();
			userManager.close();
			btnStop.enabled = btnStart.enabled = false;
			btnNext.enabled = false;
			this.banned = true;
			if (mUsersOnlineTimer)
			{
				mUsersOnlineTimer.stop();
				mUsersOnlineTimer = null;
			}
			
			if (mLookupTimeoutTimer) 
			{
				mLookupTimeoutTimer.stop();
				mLookupTimeoutTimer = null;
			}
			
			if (mConnectionTimeoutTimer) 
			{
				mConnectionTimeoutTimer.stop();
				mConnectionTimeoutTimer = null;
			}
			if(mLookupDelayTimer) {
				mLookupDelayTimer.stop();
				mLookupDelayTimer.reset();
			}
			ccCallState = CCCallNotReady;
			ccState = CCNotConnected;
        }
        
        private function blocked() : void {
        	var msg : String = lang.getSimpleProperty("blockedMessage");
        	status(msg + "\n");
        	
        	userStop = true;
			requestDisconnect2();
			userManager.close();
			btnStop.enabled = btnStart.enabled = false;
			btnNext.enabled = false;
			this.banned = true;
			if (mUsersOnlineTimer)
			{
				mUsersOnlineTimer.stop();
				mUsersOnlineTimer = null;
			}
			
			if (mLookupTimeoutTimer) 
			{
				mLookupTimeoutTimer.stop();
				mLookupTimeoutTimer = null;
			}
			
			if (mConnectionTimeoutTimer) 
			{
				mConnectionTimeoutTimer.stop();
				mConnectionTimeoutTimer = null;
			}
			if(mLookupDelayTimer) {
				mLookupDelayTimer.stop();
				mLookupDelayTimer.reset();
			}
			ccCallState = CCCallNotReady;
			ccState = CCNotConnected;
        }
        
        private function gotReported(reportCount : int, reportTotal : int) : void {
        	if(reportCount == reportTotal)
        	return;
        	
        	var msg : String = lang.getSimpleProperty("reportedReportSuccessMessage");
        	msg = msg.replace(/\$x/g, reportCount);
        	msg = msg.replace(/\$y/g, reportTotal);
        	
        	status(msg + "\n");
        }
        
    	private function startAudio():void
		{
			if (true) // TODO: Recognize mute
			{
				var mic:Microphone = Microphone.getMicrophone(micIndex);
				if (mic && outgoingStream)
				{
					outgoingStream.attachAudio(mic);
				}
			}
			else
			{
				if (outgoingStream)
				{
					outgoingStream.attachAudio(null);
				}
			}
		}
		
		
		private function startVideo():void
		{
			if (true) // TODO: Recognize no video settings
			{
				if(curCamera) {
					curCamera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
				}
				
				curCamera = Camera.getCamera(cameraIndex.toString());
				
				if (curCamera)
				{
					if(!curCamera.muted != cameraAllowed) {
						cameraAllowed = !curCamera.muted;
						
						cameraChangedStatus();
					}
					
					curCamera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
					curCamera.addEventListener(StatusEvent.STATUS, onCameraStatus);
					
					vidMe.attachCamera(curCamera);
					if (outgoingStream)
					{
						outgoingStream.attachCamera(curCamera);
					}
				}
			}
			else
			{
				vidMe.attachCamera(null);
				if (outgoingStream)
				{
					outgoingStream.attachCamera(null);
				}
			}
		}
		
		private function requestDisconnect() : void {
			ccCallState = CCCallReady;
			
			if(enableButtonNextTimer)
			enableButtonNextTimer.stop();
			
			try {
				if(!serverIsRed5)
				outgoingStream.send("gracefullyDisconnect", mId);
			} catch(e : Error) {
				
			} finally {
				if(!serverIsRed5)
				callLater(requestDisconnect2);
				else
				requestDisconnect2();
			}
		}
		
		private function requestDisconnect2():void
		{
//			btnSend.enabled = false;
			btnNext.enabled = true;
			
			partnerUsername = this.lang.getSimpleProperty("yourPartnerLabel");
			partnerCCode = "";
			partnerCountry = "";
			
			waitForUsername = true;
			connectionStatusSet = false;
			
			lblOtherId.text = "";
			
			userManager.disconnect();
			
			if (incomingStream)
			{
				incomingStream.close();
				incomingStream.removeEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
			}
			
			if (outgoingStream)
			{
				outgoingStream.attachCamera(null);
				outgoingStream.attachAudio(null);
				outgoingStream.close();
				outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
			}
			
			if (controlStream)
			{
				controlStream.close();
				controlStream.removeEventListener(NetStatusEvent.NET_STATUS, controlHandler);
			}
			
			vidOther.attachCamera(null);
			try {
				remoteVideo.attachNetStream(null);
				remoteVideo.clear();
			} catch(e : Error) {
				
			}
			
			if(mLookupDelayTimer) {
				mLookupDelayTimer.stop();
				mLookupDelayTimer.reset();
			}
			
			if(!userStop && cbAutoFindNext.selected) {
				btnNext.enabled = false;
				findPartner();
			}
		}
        
		private function onStop():void
		{
			userStop = true;
			requestDisconnect();
			clearTaChat();
			tiChat.htmlText = "";
			ccState = CCNotConnected;
			ccCallState = CCCallNotReady;
			lblOtherId.text = "";
			
			if (mUsersOnlineTimer)
			{
				mUsersOnlineTimer.stop();
				mUsersOnlineTimer = null;
			}
			
			if (mLookupTimeoutTimer) 
			{
				mLookupTimeoutTimer.stop();
				mLookupTimeoutTimer = null;
			}
			
			if (mConnectionTimeoutTimer) 
			{
				mConnectionTimeoutTimer.stop();
				mConnectionTimeoutTimer = null;
			}
			
			if(mLookupDelayTimer) {
				mLookupDelayTimer.stop();
				mLookupDelayTimer.reset();
			}
			
			userManager.unregister();
			
			if (incomingStream)
			{
				incomingStream.removeEventListener(NetStatusEvent.NET_STATUS, incomingStreamHandler);
				incomingStream.close();
			}
			
			if (outgoingStream)
			{
				outgoingStream.attachAudio(null);
				outgoingStream.attachCamera(null);
				outgoingStream.removeEventListener(NetStatusEvent.NET_STATUS, outgoingStreamHandler);
				outgoingStream.close();
			}
			
			if (controlStream)
			{
				controlStream.removeEventListener(NetStatusEvent.NET_STATUS, controlHandler);
				controlStream.close();
			}
			
			incomingStream = null;
			outgoingStream = null;
			controlStream = null;

			vidOther.attachCamera(null);
			try {
				remoteVideo.attachNetStream(null);
				remoteVideo.clear();
			} catch(e : Error) {
				
			}
			
			
			btnStop.enabled = false;
			btnStart.enabled = true;
			btnNext.enabled = false;
			lblUsersOnline.htmlText = "";
			lblID.text = "";
			
			status(this.lang.getCompoundProperty("leaveChatMessage", 0)+"\n");
            status(this.lang.getCompoundProperty("leaveChatMessage", 1)+"\n\n");	
            
            if(autoDisconnectTimer)
            autoDisconnectTimer.reset();
            
            if(autoDisconnectCountdownTimer)
            autoDisconnectCountdownTimer.reset();	
            
            if(useSounds) {
            	var snd : Sound = new Sound(new URLRequest("jabbercam/sounds/goodbye.mp3"));
            	snd.addEventListener(IOErrorEvent.IO_ERROR, ioError);
            	snd.play();
            }
		}
		
		private function micChanged(event:Event):void
		{

		}
						
		private function cameraChanged(event:Event):void
		{
			var oldCameraIndex:int = cameraIndex;
			cameraIndex = cameraSelection.selectedIndex;
			
			var camera:Camera = Camera.getCamera(cameraIndex.toString());
			var oldCamera:Camera = Camera.getCamera(oldCameraIndex.toString());
			
			oldCamera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
			camera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
			camera.addEventListener(StatusEvent.STATUS, onCameraStatus);
			if(!camera.muted != cameraAllowed) {
				cameraAllowed = !camera.muted;
				cameraChangedStatus();
			}
			curCamera = camera;
			
			camera.setMode(320, 240, 15);
			camera.setQuality(0, oldCamera.quality);
			
			try {
				vidMe.attachCamera(camera);
			} catch(e : Error) {
				
			}
		}
		
		private function onCameraStatus(event : StatusEvent) : void {
			var cameraAllowed : Boolean = event.code == "Camera.Unmuted";
			
			if(this.cameraAllowed != cameraAllowed) {
				this.cameraAllowed = cameraAllowed;
				cameraChangedStatus();
			}
			
			firstTimeCheckCamera = false;
		}
		
		private function cameraChangedStatus() : void {
			if(ccState == CCRegistered) {
				userManager.updateSetting(mId, "cam", cameraAllowed?"true":"0");
				
				if(outgoingStream) {
					try {
						outgoingStream.send("onPeerCameraAllowed", cameraAllowed);
					} catch(e : Error) {
						
					}
				}
			}
		}
		
		private function onPeerCameraAllowed(cameraAllowed : Boolean) : void {
			this.peerCameraAllowed = cameraAllowed;
			
			if(cameraAllowed) {
				try {
					ad.loaderInfo.loader.close();
				} catch(e : Error) {
					
				}
			} else {
				if(this.ads && ads.length) {
					currentAd = "jabbercam"+
						this.ads[Math.round(Math.random() * (ads.length-1))].replace(/^\./,"");
					
				}
			}
		}
		
		private function enableButtonNext(event : TimerEvent) : void {
			this.btnNext.enabled = true;
		}
		
		private function micVolumeChanged(e:SliderEvent):void
		{
			var mic:Microphone = Microphone.getMicrophone(micIndex);
			if (mic)
			{
				mic.gain = e.value;
			}			
		}

		private function speakerVolumeChanged(e:SliderEvent):void
		{
			if (incomingStream)
			{
				var st:SoundTransform = new SoundTransform(e.value);
				incomingStream.soundTransform = st;
			}			
		}
		
		private function onPreview():void
		{
			previewVideo();
		}
		
		private function onNext():void
		{
			btnNext.enabled = false;
			ccConnect.enabled = false;
			
			if(autoDisconnectTimer)
			autoDisconnectTimer.reset();
			
			if(autoDisconnectCountdownTimer)
			autoDisconnectCountdownTimer.reset();
			
			findPartner();
		}
		
		private function findUserByName():void
		{
			if(ccUsername.text == "")
			return;
			
			btnNext.enabled = false;
			ccConnect.enabled = false;
			
			if(autoDisconnectTimer)
			autoDisconnectTimer.reset();
			
			if(autoDisconnectCountdownTimer)
			autoDisconnectCountdownTimer.reset();
			
			findPartnerByName();
		}
		
		private function onSexFemale():void
		{
			status(this.lang.getSimpleProperty("femaleSexChange")+"\n");
			mSex = "f";
			if (ccState == CCRegistered) {
				userManager.updateSex(mId, mSex);
			}
		}
		
		private function onSexMale():void
		{
			status(this.lang.getSimpleProperty("maleSexChange")+"\n");
			mSex = "m";
			if (ccState == CCRegistered) {
				userManager.updateSex(mId, mSex);
			}
		}
		
		private function onAgeChange() : void {
			if(ccState == CCRegistered) {
				userManager.updateAge(mId, age.value);
			}
		}
		
		private function lookupAgeChange() : void {
			switch(lookupAge.value) {
				case 0:
					status(lang.getCompoundProperty("updateAgeLookupFilter", 0));
					break;
				default:
					status(lang.getCompoundProperty("updateAgeLookupFilter", 1) + lookupAge.labels[lookupAge.value]);
			}
			
			if(ccState == CCRegistered)
			userManager.updatePreference(mId, "age", lookupAge.value);
		}
		
		private function onConnectToBoth():void
		{
			mFilterSex = "b";
			if(ccState == CCRegistered)
			userManager.updatePreference(mId, "sex", "0");
		}
		
		private function onConnectToGirls():void
		{
			mFilterSex = "f";
			if(ccState == CCRegistered)
			userManager.updatePreference(mId, "sex", "f");
		}
		
		private function onConnectToBoys():void
		{
			mFilterSex = "m";
			if(ccState == CCRegistered)
			userManager.updatePreference(mId, "sex", "m");
		}
		
		private function checkSexFilter() : void {
			if(rbSexFemale.selected && rbSexMale.selected || !rbSexFemale.selected && !rbSexMale.selected) {
				onConnectToBoth();
			} else if(rbSexFemale.selected) {
				onConnectToGirls();
			} else if(rbSexMale.selected) {
				onConnectToBoys();
			}
		}
		
		private function onClearChat():void
		{
			taChat.text = "";
			taChat.htmlText = "";
		}
		
		private function previewVideo():void
		{
			var camera:Camera = Camera.getCamera(cameraIndex.toString());
			if(curCamera) {
				curCamera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
			}
			
			curCamera = camera;
		
			if(curCamera) {
				curCamera.addEventListener(StatusEvent.STATUS, onCameraStatus);
			}
		
			if(btnPreview.selected && camera) {
				
				camera.setQuality(0,100);
				camera.setMode(320, 240, 15);
				vidMe.attachCamera(camera);
				
				if(!firstTimeCheckCamera && !cameraAllowed) {
					Security.showSettings(SecurityPanel.PRIVACY);
				}
				
			} else if(camera) {
				
				camera.setQuality(16384, 0);
				camera.setMode(160, 120, 15);
				
				if(ccCallState == CCCallEstablished)
				vidMe.attachCamera(camera);
				
			}
		}
		
		private function onAutoFindNext():void
		{
			if (!cbAutoFindNext.selected) {
				mAutoFindActive = false;
			}
		}
		
		private function onCameraOnOnly() : void {
			if(ccState == CCRegistered) {
				userManager.updatePreference(mId, "cam", cbCameraOnOnly.selected?"true":"0");
			}
		}
		
		private function onMessageReceived(text:String):void
		{
			taChat.htmlText += (partnerUsername==lang.getSimpleProperty("yourPartnerLabel")?
				partnerUsername:partnerUsername+": ") + filterMessage(text) + "\n";
			taChat.validateNow();
			taChat.verticalScrollPosition = taChat.textHeight;
			
			if(useSounds) {
				
				var snd : Sound;
				if(text.search(/^\(buzz\)/) > -1) {
					snd = new Sound(new URLRequest("jabbercam/sounds/buzz.mp3"));
				} else {
					snd = new Sound(new URLRequest("jabbercam/sounds/connected.mp3"));
				}
				snd.addEventListener(IOErrorEvent.IO_ERROR, ioError);
				
				snd.play();
			}
		}
		
		private function onBuzz() : void {
			if (ccCallState != CCCallEstablished || !outgoingStream)
			{
				return;
			}
			
			tiChat.text = "(buzz)";
			onSend();
		}
		
		private function ioError(event : IOErrorEvent) : void {
			trace(event);
		}
		
		private function onSend():void
		{
			if (ccCallState != CCCallEstablished)
			{
				return;
			}
			var msg:String = tiChat.text; 
			if ((msg.length != 0 && outgoingStream))
			{
				tiChat.text = "";
				tiChat.htmlText = "";
				taChat.htmlText += (myUsername.text==lang.getSimpleProperty('youText')?'<b>'+lang.getSimpleProperty("youText")+'</b>':
					"<b>"+myUsername.text+"</b>")+": "+filterMessage(msg)+"\n";
				taChat.validateNow();	
				taChat.verticalScrollPosition = taChat.textHeight;
				outgoingStream.send("onIm", msg);
				userManager.saveChat(mId, mOtherId, msg);
				tiChat.setFocus();
				
				if(useSounds && msg.search(/^\(buzz\)/) > -1) {
				
					var snd : Sound;
					snd = new Sound(new URLRequest("jabbercam/sounds/buzz.mp3"));
					
					snd.addEventListener(IOErrorEvent.IO_ERROR, ioError);
					
					snd.play();
				}
			}			
		}
		
		private function filterMessage(message : String) : String {
			if(!badWordsRegExp || badWordsRegExp.source == "")
			return message;
			
			return message.replace(badWordsRegExp, function(...args) : String {
				var starsString : String = "";
				
				var matchIndex : int = 0;
				while(!args[++matchIndex]);
				
				if(args.length > matchIndex+1)
				for(var i : int = 0; i < args[matchIndex+1].length; i++)
				starsString += "*";
				
				return args[matchIndex]+starsString+args[matchIndex+2];
			});
		}
		
		private function onSocialButtonClick(url : String) : void {
			try {
				navigateToURL(new URLRequest(url), "_blank");
			} catch(e : Error) {
				
			}
		}
		
		private function onGetYourOwn():void
		{
			onSocialButtonClick(lang.getSourceCodeLink);
		}
		
		private function clearTaChat():void
		{
			taChat.text = "";
			taChat.htmlText = "";
		}
		
		private function status(msg:String):void
		{
			var curTime:String;
			var format:DateFormatter = new DateFormatter();
			format.formatString = "JJ:NN:SS";
			curTime = format.format(new Date()).toString();

			var chatTimeStyle : CSSStyleDeclaration = StyleManager.getStyleDeclaration(".ChatTime");
			taChat.htmlText += "<font size=\""+chatTimeStyle.getStyle('fontSize')+"\" color=\"#"+
				StyleManager.getColorName(chatTimeStyle.getStyle('color')).toString(16)+"\">"+curTime
				+"</font>&nbsp; "+msg;
				
			taChat.validateNow();
			taChat.verticalScrollPosition = taChat.textHeight;
		}
		
		private function initLabels() : void {
			partnerUsername = this.lang.getSimpleProperty("yourPartnerLabel");
			
			this.partnerLabel.text = this.lang.getSimpleProperty('partnerLabel');
			this.youLabel.text = this.lang.getSimpleProperty('youLabel');
//			this.meLabel.text = this.lang.getSimpleProperty('meLabel');
			this.myUsername.text = this.lang.getSimpleProperty('youText');
			this.rbFemale.label = this.lang.getSimpleProperty('femaleLabel');
			this.rbMale.label = this.lang.getSimpleProperty("maleLabel");
			this.seekingLabel.text =  this.lang.getSimpleProperty('seekingLabel');
//			this.rbSexBoth.label = this.lang.getSimpleProperty('bothLabel');
			this.rbSexFemale.label = this.lang.getSimpleProperty('ladiesLabel');
			this.rbSexMale.label =  this.lang.getSimpleProperty('gentsLabel');
			this.cbAutoFindNext.label =  this.lang.getSimpleProperty('autoFindNextLabel');
			this.microphoneLabel.text =  this.lang.getSimpleProperty('microphoneLabel');
			this.volumeLabel.text = this.lang.getSimpleProperty('volumeLabel');
			this.btnPreview.label= this.lang.getSimpleProperty('previewVideoLabel');
			this.btnNext.label=this.lang.getSimpleProperty('findNextLabel');
			this.btnNext.toolTip=this.lang.getSimpleProperty('nextButtonTooltip');
			this.btnStart.label=this.lang.getSimpleProperty('startLabel');
			this.btnStart.toolTip=this.lang.getSimpleProperty('startButtonTooltip');
			this.btnClear.label=this.lang.getSimpleProperty('clearLabel');
			this.myLanguageLabel.text = this.lang.getSimpleProperty('myLanguageLabel');
			this.partnerLanguageLabel.text = this.lang.getSimpleProperty('partnerLanguageLabel');
			this.ccLabel.text = this.lang.getSimpleProperty('connectMeDirectlyToLabel');
			this.ccConnect.label = this.lang.getSimpleProperty('connectMeDirectlyToButtonLabel');
//			this.btnSend.label=this.lang.getSimpleProperty('sendLabel');
//			this.btnGetTheSource.label=this.lang.getSimpleProperty('getTheSourceLabel');
			this.betaLabel.text=this.lang.getSimpleProperty('betaLabel');
			this.btnStop.label=this.lang.getSimpleProperty('stopLabel');
			this.btnFilter.label=this.lang.getSimpleProperty("filterLabel");
			this.btnFilter.toolTip=this.lang.getSimpleProperty("filterButtonTooltip");
			this.btnReport.label=this.lang.getSimpleProperty("reportLabel");
			this.btnReport.toolTip=this.lang.getSimpleProperty("reportButtonTooltip");
			this.autoNextIntervalLabel.text = this.lang.getSimpleProperty('autoNextIntervalLabel');
			this.cbCameraOnOnly.label = this.lang.getSimpleProperty("cameraOnLabel");
//			this.usernameLabel.text = this.lang.getSimpleProperty("usernameTextInputLabel");
			
			this.btnStopAutoNextTimer.label = lang.getSimpleProperty("btnStopAutoNextLabel");
			this.backgroundButtons.toolTip = lang.getSimpleProperty("changeBackgroundButtonTooltip");
			this.iamLabel.text = lang.getSimpleProperty('iamLabel');
			this.fromLabel.text = lang.getSimpleProperty('fromLabel');
			
			initLanguageSettFilter();
		}
		
		private function initLanguageSettFilter() : void {
			if(!languageFilters)
			return;
			
			var langFilterIdx : int = langFilter.selectedIndex;
			var langSettingIdx : int = langSetting.selectedIndex;
			var dp : Array = [{label:lang.getSimpleProperty("langFilterAllLabel"), flag:null, code:null}];
			var i : int;
			var itemFactory : ClassFactory;
			if(this.lang.getSetting("languageFilter").replace(/^\s+|\s+$/, "") == "flag") {
				
				itemFactory = new ClassFactory(LangFilterFlagRenderer);
				
				for (i = 0; i < languageFilters.length; i++)
				dp.push({flag:"jabbercam/flags/"+languageFilters[i].code+".png", code:languageFilters[i].code,
					label:languageFilters[i].label});
				
			} else {
				
				itemFactory = new ClassFactory(ListItemRenderer);
				
				for (i = 0; i < languageFilters.length; i++)
				dp.push({label:languageFilters[i].label, code:languageFilters[i].code});
				
			}
			
			langFilter.itemRenderer = itemFactory;
			langSetting.itemRenderer = itemFactory;
			
			this.langFilterValues = dp;
			
			langFilter.selectedIndex = langFilterIdx;
			langSetting.selectedIndex = langSettingIdx;
		}
		
		private function changeLanguage(ev : Event) : void {
			this.lang.loadLanguage(this.language.selectedIndex);
		}
		
		/* private function taChatVScrollBarAdded(scrollBar : VScrollBar) : void {
			btnClear.x = 602;
			var self : ChatRouletteClone = this;
			scrollBar.addEventListener(FlexEvent.HIDE, function(ev : FlexEvent):void{
				self.btnClear.x=619;
			});
			scrollBar.addEventListener(FlexEvent.SHOW, function(ev : FlexEvent) : void {
				self.btnClear.x = 602;
			});
		} */
		
		private function checkKeyPressed(event : KeyboardEvent) : void {
			switch(event.keyCode) {
				case Keyboard.F7:
					if(this.btnNext.enabled || this.btnNext.visible && !this.btnStop.visible) {
						onNext();
					}
					break;
				case Keyboard.F8:
					if(this.btnStop.enabled) {
						this.onStop();
					}
					break;
			}
		}
		
		private function autoDisconnectChange() : void {
			var delay : uint = AutoDisconnect.values[autoDisconnect.value] * 1000;
			if(delay <= 0)
			delay = AutoDisconnect.values[1] * 1000;
			
			if(!autoDisconnect.value && autoDisconnectTimer) {
				autoDisconnectTimer.stop();
				
				autoDisconnectCountdownTimer.stop();
			} else {
				if(!autoDisconnectTimer) {
					autoDisconnectTimer = new Timer(delay, 1);
					autoDisconnectTimer.addEventListener(TimerEvent.TIMER, this.disconnect);
				}
				
				if(!autoDisconnectCountdownTimer) {
					autoDisconnectCountdownTimer = new Timer(1000);
					autoDisconnectCountdownTimer.addEventListener(TimerEvent.TIMER, setCountdown);
				}
				
				autoDisconnectTimer.delay = delay;
				autoDisconnectTimer.reset();
				
				autoDisconnectCountdownTimer.reset();
				
				if(ccCallState == CCCallEstablished) {
					autoDisconnectTimer.start();
					
					autoDisconnectCountdownTimer.start();
					setCountdown(null);
				}
			}
		}
		
		private function setCountdown(event : TimerEvent) : void {
			var secPassed : int = autoDisconnectCountdownTimer.currentCount+1;
			var secRemaining : int = int(autoDisconnectTimer.delay/1000)-secPassed;
			
			btnStopAutoNextTimer.label = lang.getSimpleProperty("btnStopAutoNextLabel")+" ("+secRemaining+")";
		}
		
		private function disconnect(event : TimerEvent) : void {
			callLater(onNext);
		}
		
		private function onFilter() : void {
			if(mOtherId != "" && mOtherId != null) {
				userManager.filterOut(mOtherId);
				btnFilter.enabled = false;
			}
		}
		
		private function onReport() : void {
			if(mOtherId != "" && mOtherId != null) {
				userManager.report(mOtherId);
				btnReport.enabled = false;
			}
		}
		
		private function changeUsername() : void {
			if(myUsername.text == lang.getSimpleProperty('youText'))
			return;
			
			if(ccCallState == CCCallEstablished) 
			outgoingStream.send("sendUsername", myUsername.text);
		}
		
		private function beginLoadingAd() : void {
			
		}
		
		private function completeLoadingAd() : void {
			
		}
		
		private function loadHorizLayout() : void {
			ExternalInterface.call("function loadHoriz() {" + 
					"window.location.href='horizontal.html';" + 
					"}");
		}
		
		private function loadVerticalLayout() : void {
			ExternalInterface.call("function loadVertical() {" + 
					"window.location.href='vertical.html';" + 
					"}");
		}
		
		private function langFilterChange() : void {
			
			if(ccState == CCRegistered)
			userManager.updatePreference(mId, "lang", langFilter.selectedItem.code == null?"0":
				langFilter.selectedItem.code);
			
		}
		
		private function langSettingChange() : void {
			
			if(ccState == CCRegistered)
			userManager.updateSetting(mId, "lang", langSetting.selectedItem.code == null?"0":
				langSetting.selectedItem.code);
			
		}
		
		private function onSpeedChatClick() : void {
			cbAutoFindNext.selected = speedChat.selected;
			onAutoFindNext();
			
			minimumConnectedTime = speedChat.selected?speedChatMinimumConnectedTime:realMinimumConnectedTime;
			
			if(speedChat.selected)
			autoDisconnect.value = AutoDisconnect.values.indexOf(speedChatConnectedTime);
			else
			autoDisconnect.value = 0;
			
			autoDisconnectChange();
			
			speedDate.selected = false;
			speedDate.label = "SpeedDate (OFF)";
			
			speedChat.label = speedChat.selected?"SpeedChat (ON)":"SpeedChat (OFF)";
		}
		
		private function onSpeedDateClick() : void {
			cbAutoFindNext.selected = speedDate.selected;
			onAutoFindNext();
			
			minimumConnectedTime = speedDate.selected?speedDateMinimumConnectedTime:realMinimumConnectedTime;
			
			if(speedDate.selected)
			autoDisconnect.value = AutoDisconnect.values.indexOf(speedDateConnectedTime);
			else
			autoDisconnect.value = 0;
			
			autoDisconnectChange();
			
			speedChat.selected = false;
			speedChat.label = "SpeedChat (OFF)";
			
			speedDate.label = speedDate.selected?"SpeedDate (ON)":"SpeedDate (OFF)";
		}
		
		private function customFilter1SettingChange() : void {
			if(ccState == CCRegistered)
			userManager.updateSetting(mId, "cflt1", CustomFilter.customFilter1Values[customFilter1Setting.selectedIndex]);
		}
		
		private function customFilter2SettingChange() : void {
			if(ccState == CCRegistered)
			userManager.updateSetting(mId, "cflt2", CustomFilter.customFilter2Values[customFilter2Setting.selectedIndex]);
		}
		
		private function customFilter1PrefChange() : void {
			if(ccState == CCRegistered)
			userManager.updateSetting(mId, "cflt1", CustomFilter.customFilter1Values[customFilter1Pref.selectedIndex]);
		}
		
		private function customFilter2PrefChange() : void {
			if(ccState == CCRegistered)
			userManager.updateSetting(mId, "cflt2", CustomFilter.customFilter2Values[customFilter2Pref.selectedIndex]);
		}