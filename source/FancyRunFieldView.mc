using Toybox.WatchUi;
using Toybox.Graphics;

class FancyRunFieldView extends WatchUi.DataField {

    hidden var mValue;
    hidden var hr_title;
    //consts
    hidden var is24Hour = true;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.00";
    hidden var distanceUnit = System.UNIT_METRIC ? 1000 : 1609.344; //米制或者英制
    hidden var hr_colors = [
		Graphics.COLOR_BLACK,0xccd1d1,Graphics.COLOR_BLUE,
		Graphics.COLOR_GREEN,Graphics.COLOR_ORANGE,Graphics.COLOR_RED
    ]; //心率区间颜色设置
	//values
    hidden var hr, distance, timerTime, speed, pace, cad, fiveK, tenK, half, marathon, battery, posAcc;
    //hidden var profile = UserProfile.getProfile();
    hidden var zoneInfo = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
    //hrzone pos
    hidden var hr_rect_x, hr_rect_y, hr_rect_w, hr_rect_h, hr_title_x, hr_title_y;
    hidden var hr_title_font;
    
    function initialize() {
        DataField.initialize();
        hr_rect_x = WatchUi.loadResource(Rez.Strings.hr_rect_x).toNumber();
        hr_rect_y = WatchUi.loadResource(Rez.Strings.hr_rect_y).toNumber();
        hr_rect_w = WatchUi.loadResource(Rez.Strings.hr_rect_w).toNumber();
        hr_rect_h = WatchUi.loadResource(Rez.Strings.hr_rect_h).toNumber();
        hr_title_x = WatchUi.loadResource(Rez.Strings.hr_title_x).toNumber();
        hr_title_y = WatchUi.loadResource(Rez.Strings.hr_title_y).toNumber();
        //string to int
        hr_title_font = WatchUi.loadResource(Rez.Strings.hr_title_font).toNumber();
        //System.println(hr_title_font);
        mValue = 0.0f;
        //System.println(Graphics.FONT_XTINY); //0
        //System.println(Graphics.FONT_TINY); //1
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
    	View.setLayout(Rez.Layouts.LayoutMain(dc));
        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	try {
	    	distance = info has :elapsedDistance ? info.elapsedDistance : 0;
	        if (distance == null) { distance = 0; }
	        timerTime = info has :timerTime ? info.timerTime : 0;
	        if (timerTime == null) { timerTime = 0; }
	        speed = info has :currentSpeed ? info.currentSpeed : 0;
	        if (speed == null) { speed = 0; }
	        cad = info has :currentCadence ? info.currentCadence : 0;
	        if (cad == null) { cad = 0; }
	        hr = info has :currentHeartRate ? info.currentHeartRate : 0;
	        if (hr == null) { hr = 0; }
	        battery = System.getSystemStats().battery; //battery
	        //position good, usable, poor, or not available
	        posAcc = info has :currentLocationAccuracy ? info.currentLocationAccuracy : Position.QUALITY_NOT_AVAILABLE;
	        if (posAcc == null) { posAcc = Position.QUALITY_NOT_AVAILABLE; }
    	} catch(ex) {
    	}
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	try {
    		var lblTime = View.findDrawableById("lblTime");
	    	lblTime.setText(formatTime());
	    	//drawHrBg(dc); //hr color
	//    	View.findDrawableById("hr_zone").setColor(Graphics.COLOR_BLUE);
	//		View.findDrawableById("hr_zone").setColor(Graphics.COLOR_BLUE);
			var pace = formatPace(speed);
			if (pace.length() > 4) {
	    		View.findDrawableById("lbl_pace_val").setFont(Graphics.FONT_NUMBER_MILD);
	    	} else {
	    		View.findDrawableById("lbl_pace_val").setFont(Graphics.FONT_NUMBER_MEDIUM);
	    	}
	    	var hrStr = "--";
	    	if (hr != 0) { hrStr = hr.toString(); }
	    	View.findDrawableById("lbl_hr_val").setText(hrStr);
	    	View.findDrawableById("lbl_pace_val").setText(formatPace(speed));
	    	View.findDrawableById("lbl_cad_val").setText(cad.toString());
	    	View.findDrawableById("lbl_timer_val").setText(formatTimerTime(timerTime));
	    	View.findDrawableById("lbl_dist_val").setText(getDistanceStr(distance));
	//        // Set the background color
	//        View.findDrawableById("Background").setColor(getBackgroundColor());
	//
	//        // Set the foreground color and value
	//        var value = View.findDrawableById("value");
	//        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
	//            value.setColor(Graphics.COLOR_WHITE);
	//        } else {
	//            value.setColor(Graphics.COLOR_BLACK);
	//        }
	//        value.setText(mValue.format("%.2f"));
	
	        // Call parent's onUpdate(dc) to redraw the layout
	        setGPS(posAcc);
			View.onUpdate(dc);        
	        drawHrBg(dc); //hr color
    	} catch (ex) {}
    	
    }
    
    /*******************user functions*************/
    function setGPS(posAcc) {
    	var color = Graphics.COLOR_BLACK;
    	//var text = "GPS";
    	var lblGPS = View.findDrawableById("lblGPS");
        if (posAcc == Position.QUALITY_POOR) {
        	color = Graphics.COLOR_DK_RED;
        } else if (posAcc == Position.QUALITY_USABLE) {
        	color = Graphics.COLOR_ORANGE;
        } else if (posAcc == Position.QUALITY_GOOD) {
        	color = Graphics.COLOR_DK_GREEN;
        }
        lblGPS.setColor(color);
    }
    
    function drawHrBg(dc) {
    	var hr_zone = getHRZone(hr);
    	if (hr_zone < 0) {
    	    return;
    	}
    	var hr_zone_color = getHRColor(hr_zone);
    	dc.setColor(hr_zone_color, Graphics.COLOR_TRANSPARENT);
    	dc.fillRectangle(hr_rect_x, hr_rect_y, hr_rect_w, hr_rect_h);
    	hr_title = WatchUi.loadResource(Rez.Strings.hr);
    	var lbl = View.findDrawableById("lbl_hr_title");
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	dc.drawText(hr_title_x, hr_title_y, hr_title_font, hr_title, Graphics.TEXT_JUSTIFY_CENTER);
    }
    

    
    /**********************format functions**********************/
    
    //Time format
    function formatTime() {
    	var clockTime = System.getClockTime();
        var time;
        if (is24Hour) {
            time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
        } else {
            time = Lang.format("$1$:$2$", [computeHour(clockTime.hour), clockTime.min.format("%.2d")]);
            time += (clockTime.hour < 12) ? " am" : " pm";
        }
        return time;
    }
    
    //Compute hour
    function computeHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;      
    }
    
    //process distance
    function getDistanceStr(distanceVal) {
        //distanceUnit = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC ? 1000 : 1609.344;
    	var distStr;
    	if (distanceVal > 0) {
    		var dist = distanceVal / distanceUnit;
    		if (dist < 100) {
    			distStr = dist.format("%.2f");
    		} else {
    			distStr = dist.format("%.1f");
    		}
    	} else {
    	    distStr = ZERO_DISTANCE;
    	}
    	return distStr;
    }
    
    //format timer time
    function formatTimerTime(ms) {
   		var duration = ZERO_TIME;
    	if (ms == 0) { return duration; }
    	var num = ms / 1000;
    	var hour = 0;
    	var second = num % 60;
    	var minute = num / 60;
    	if (minute >= 60) {
    	    hour = minute / 60;
    	    minute = minute % 60;
    	}
    	if (hour == 0) {
    		duration = minute.format("%d") + ":" + second.format("%02d");
    	} else {
    		duration = hour.format("%d") + ":" + minute.format("%02d") + ":" + second.format("%02d");
    	}
    	return duration;
    }
    
    //compute and format pace 
    function formatPace(speed_mps) {
    	if (speed_mps <= 0) {
    		return "--:--";
    	}
    	var unit = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC ? 1000 : 1609.344;
    	var paceSeconds = 1 / speed_mps * unit;
    	//System.println(distanceUnit);
    	var num = paceSeconds.toLong();
    	var second = num % 60;
    	var minute = num / 60;
    	var duration = minute.format("%d") + ":" + second.format("%02d");
    	return duration;
    }
    
    //get hr zone
    function getHRZone(val) {
	    /*
		    * min zone 1 - The minimum heart rate threshold for zone 1
			* max zone 1 - The maximum heart rate threshold for zone 1
			* max zone 2 - The maximum heart rate threshold for zone 2
			* max zone 3 - The maximum heart rate threshold for zone 3
			* max zone 4 - The maximum heart rate threshold for zone 4
			* max zone 5 - The maximum heart rate threshold for zone 5
	    */
    	var zone = -1;
    	var hr = val.toNumber() == null ? 0 : val.toNumber();
    	if (hr <= 0) { return zone; }
    	if (hr < zoneInfo[0]) {zone = -1;} 
    	else if (hr <= zoneInfo[1]) {zone = 1;}
    	else if (hr <= zoneInfo[2]) {zone = 2;}
    	else if (hr <= zoneInfo[3]) {zone = 3;}
    	else if (hr <= zoneInfo[4]) {zone = 4;}
    	else {zone = 5;}
    	return zone;
    }
    
    //get hr color
    function getHRColor(hrZone) {
    	return hr_colors[hrZone];
    }
    
    //cadence zone
    function getCadZone(cad) {
	    /**
	    
	    */
    	var zone = -1;
    	
    }
    
    function getCadColor(zone) {
    }

}
