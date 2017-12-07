//testMe();

function testMe() {
	var img = new Image();
	var currentTime = (new Date()).getTime();
	if(navigator.appName.indexOf('Microsoft Internet Explorer') != -1){// ie
		console.log("kaas");
		img.onload = img.onabort = img.onerror = function(){console.log("boe!!!!")};
		//img.onabort = enaledActionRun;
		//img.onerror = enaledActionRun;
		img.src = currentTime+'.'+currentTime+'?time='+currentTime;
		setTimeout(function(){
			console.log("koe")
		}, 0);
	}
}


detectImageEnabledMode({
	onDetectImageIsDisabled:function(){
		console.log('images are disabled');
	},
	onDetectImageIsEnabled:function(){
		console.log('images are enabled');
	}
});
function detectImageEnabledMode(options){
	/* define disabled/enabled actions */
	var actionCounter = 0;
	var enabledAction = (options.onDetectImageIsEnabled && typeof(options.onDetectImageIsEnabled)=='function')?options.onDetectImageIsEnabled:function(){};
	var enaledActionRun = function(){
		if(actionCounter) return;
		actionCounter++;
		enabledAction();
	}
	var disabledAction = (options.onDetectImageIsDisabled && typeof(options.onDetectImageIsDisabled)=='function')?options.onDetectImageIsDisabled:function(){};
	var disabledActionRun = function(){
		if(actionCounter) return;
		actionCounter++;
		disabledAction();
	}
	/* create image */
	var img = new Image();
	var currentTime = (new Date()).getTime();
	if(navigator.appName.indexOf('Microsoft Internet Explorer') != -1){// ie
		console.log("kaas");
		img.onload = img.onabort = img.onerror = function(){console.log("boe")};
		//img.onabort = enaledActionRun;
		//img.onerror = enaledActionRun;
		img.src = currentTime+'.'+currentTime+'?time='+currentTime;
		setTimeout(function(){
			console.log("koe")
			disabledActionRun();
		}, 0);
	}else if (navigator.appName.indexOf('Opera') != -1) {// opera
		img.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="+'?time='+(new Date()).getTime();
		if(img.complete){
			enaledActionRun();
		}else{
			disabledActionRun();
		}
	}else{// other

		img.src = currentTime+'.'+currentTime+'?time='+currentTime;
		console.log("hey: " + img.src)
		if(img.complete){
			disabledActionRun();
		}else{
			enaledActionRun();
		}
	}
}
// tested in: ff 2+, opera 9+, chrome, safari 4+, ie 6+