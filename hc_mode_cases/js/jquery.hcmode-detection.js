/* Initialize high-contrast mode check when we have document.body */
$(function () {
    /* Get URL for test image
    * (data URIs are not supported by all browsers, and not properly removed when images are disabled in Firefox) */
    
    /* Configure these if necessary: */
    /* Absolute path to clear.gif, if available. If not, set this to "" and use imgPathFromScript instead */
    var imgPath = "";
    /* Path to clear.gif, relative to the location of this script*/
    var imgPathFromScript = "clear.gif";
    var dataSrc = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==";
    /* End configurable values */
    
    var currentTime = (new Date()).getTime();
    if (imgPath === "") {
        var script = $("script[src$='jquery.hcmode-detection.js']");
        var scriptPath = script.prop( "src" );
        var parts = scriptPath.split( "/" );
        parts.pop();
        scriptPath = parts.join( "/" ) + "/";
        imgPath = scriptPath + imgPathFromScript + "?t=" + currentTime;
    }
    else {
        imgPath += "?t=" + currentTime;
    }
    
    /* set defaults */
    $.support.images = true;
    $.support.backgroundImages = true;
    $.support.borderColors = true;
    $.support.highContrastMode = false;
    $.support.lightOnDark = false;

    var getColorValue = function ( colorTxt ) {
        var values = [], colorValue = 0, match;
        if (colorTxt.indexOf( "rgb(") != -1 ) {
            values = colorTxt.replace( "rgb(", "" ).replace( ")", "" ).split( ", " );
        }
        else if (colorTxt.indexOf( "#" ) != -1) {
            match = colorTxt.match( colorTxt.length == 7 ? /^#(\S\S)(\S\S)(\S\S)$/ : /^#(\S)(\S)(\S)$/ );
            if ( match ) {
                values = ["0x" + match[1], "0x" + match[2], "0x" + match[3]];
            }
        }
        for ( var i = 0; i < values.length; i++ ) {
            colorValue += parseInt( values[i], 16);
        }
        return colorValue;
    };

    /* create div for testing if high contrast mode is on or images are turned off */
    var div = document.createElement( "div" );
    div.style.borderWidth = "1px";
    div.style.borderStyle = "solid";
    div.style.borderTopColor = "#F00";
    div.style.borderRightColor = "#0FF";
    div.style.backgroundImage = "url(" + imgPath + ")";
    div.style.backgroundColor = "#FFF";
    div.style.position = "absolute";
    div.style.left = "-9999px";
    div.style.width = div.style.height = "2px";
    document.body.appendChild( div );

    var bkImg = $.css( div, "backgroundImage" );
    $.support.backgroundImages = !( bkImg !== null && (bkImg == "none" || bkImg == "url(invalid-url:)" ) );
    $.support.borderColors = $.css( div, "borderTopColor" ) != $.css(div, "borderRightColor" );
    $.support.lightOnDark = getColorValue( $.css(div, "color" ) ) - getColorValue( $.css( div, "backgroundColor" ) ) > 0;

    var img = new Image();
    img.style.border = "none";
    img.style.padding = img.style.margin = 0;
    img.style.border = "none";
    img.alt = "";
    img.id = "testMe";
    if ($.browser.msie) {
        if ($.browser.version >= 8) {
            div.appendChild(img);
            img.src = dataSrc;
            $.support.images = img.offsetWidth == 1;
        }
        div.outerHTML = ""; /* prevent mixed-content warning, see http://support.microsoft.com/kb/925014 */
    } else if ( ($.browser.opera && $.browser.version > 9) ) {
        div.appendChild( img );
        img.src = dataSrc;
        $.support.images = (img.offsetWidth == 1 && img.offsetHeight == 1);
        document.body.removeChild( div );
    } else if ($.browser.webkit || $.browser.mozilla){
        div.appendChild( img );
        img.src = $.browser.mozilla ? imgPath : dataSrc;
        $.support.images = !img.complete;
        //document.body.removeChild( div );
    }

    $.support.highContrastMode = !$.support.images || !$.support.backgroundImages || !$.support.borderColors;
    if ( $.support.highContrastMode ) {
        // timeout needed to reduce chances of other scripts resetting the class later
        setTimeout(function () { $( "html" ).addClass( "ui-helper-highcontrast" ); }, 0);
    }

    ///*
    setTimeout( function () {
        console.log( "$.support.images = " + $.support.images );
        console.log( "$.support.backgroundImages = " + $.support.backgroundImages);
        console.log( "$.support.borderColors = " + $.support.borderColors );
        console.log( "$.support.highContrastMode = " + $.support.highContrastMode );
        console.log( "$.support.lightOnDark = " + $.support.lightOnDark );
    }, 0 );
    //*/
});