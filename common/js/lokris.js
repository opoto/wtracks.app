/* ==========================================================================

   = Lokris - An Ajax library for Javascript =

   Lokris provides some basic Ajax functions.
   Originally developed for use on ajaxbuch.de.

   It's named after "Ajax the Lesser", son of the King of Locris
   (http://en.wikipedia.org/wiki/Ajax_the_Lesser).
   The spelling (with k) follows the transcription of the 
   ancient greek name of the region of Locris.

   (c) 2006 Linkwerk.com, Christoph Leisegang, Stefan Mintert
   Licence:   http://www.ajaxbuch.de/lokris/lokris-licence.txt
   Home page: http://www.ajaxbuch.de/lokris/

   $Id: lokris.js,v 1.2 2006/08/02 21:24:07 sm Exp $

   ========================================================================== */


var Lokris = new Object();

/* Setting global defaults */
Lokris.Defaults = {
    rawResponse:    false,
    async:          true,
    method:         "GET",
    postBody:       null,
    user:           undefined,
    password:       undefined,
    timeoutHandler: undefined,
    timeout:        60000,
    postMime:       "application/x-www-form-urlencoded",
    errorHandler:   function(req) {alert("HTTP error: "+req.status)}
};

/* Defining IE prog IDs
   For details see http://msdn.microsoft.com/library/en-us/xmlsdk/html/5016cf75-4358-4c1f-912e-c071aa0a0991.asp */
Lokris.MSIEIDS = ["Msxml2.XMLHTTP.6.0", "Msxml2.XMLHTTP.5.0", "Msxml2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0", "Microsoft.XMLHTTP"];

/* Lokris.AjaxCall - The Ajax function */
Lokris.AjaxCall = function (uri, callbackFunction, options) {

    var lwAjax = new Object; // "Host" Obbject for XmlHttpRequest and own properties
    var req    = null;       // Define local XmlHttpRequest
    Lokris.XMLHTTPRequestImplementation = "";

    // Evaluate Options
    var raw 	= (options != undefined && options.rawResponse != undefined) ? options.rawResponse : Lokris.Defaults.rawResponse;
    var async 	= (options != undefined && options.async != undefined) ? options.async : Lokris.Defaults.async;
    var method 	= (options != undefined && options.method != undefined) ? options.method : Lokris.Defaults.method;
    var body 	= (options != undefined && options.postBody != undefined) ? options.postBody : Lokris.Defaults.postBody;
    var user    = (options != undefined && options.user != undefined) ? options.user : Lokris.Defaults.user;
    var password= (options != undefined && options.password != undefined) ? options.password : Lokris.Defaults.password;
    var timeoutHandler 	= (options != undefined && options.timeoutHandler != undefined) ? options.timeoutHandler : Lokris.Defaults.timeoutHandler;
    var timeout 	= (options != undefined && options.timeout != undefined) ? options.timeout : Lokris.Defaults.timeout;
    var postMime        = (options != undefined && options.mime != undefined) ? options.mime : Lokris.Defaults.postMime;
    var errorHandler    = (options != undefined && options.errorHandler != undefined) ? options.errorHandler : Lokris.Defaults.errorHandler;


    if (window.XMLHttpRequest) { // Check for native XmlHttpRequest ...
        req = new XMLHttpRequest();
	Lokris.XMLHTTPRequestImplementation = "XMLHttpRequest";
    } else if (window.ActiveXObject) { // ... or ActiveX
	for (var i = 0; i < Lokris.MSIEIDS.length; i++) {
	    try {
		req = new ActiveXObject(Lokris.MSIEIDS[i]);
		Lokris.XMLHTTPRequestImplementation = Lokris.MSIEIDS[i];
		break;
	    } catch (e) { }
	}
    } 
    if ( req === null) { // Sorry, no Ajax
        alert("Ajax not available");
        return null;
    }

    lwAjax.request = req; 
    if (timeoutHandler != undefined) {
        lwAjax.timeoutHandler = timeoutHandler;
        lwAjax.timeoutId = window.setTimeout(function() { lwAjax.request.abort(); lwAjax.timeoutHandler(lwAjax.request) }, timeout);
    };
    // Register Event Handler
    lwAjax.request.onreadystatechange = Lokris.getReadyStateHandler(lwAjax, callbackFunction, raw, errorHandler);

    // Send Request
    lwAjax.request.open(method, uri, async, user, password);

    // Content-Type for Post Requests
    if (method.toLowerCase() == "post") {
        lwAjax.request.setRequestHeader("Content-Type",postMime);
    }

    lwAjax.request.send(body);

    return lwAjax.request;
}


/* ==========================================================================
   lwGetReadyStateHandler(XMLHttpRequest: req, function: responseXmlHandler, bool: raw)

   Returns a callback function, to be called each time req.readystate
   changes. If the XMLHttpRequest finishes successfully
   responseHandler() is called on req.responseXML or req.responseText,
   depending on the content type

   Inspired by: http://www-128.ibm.com/developerworks/library/j-ajax1/?ca=dgr-lnxw01Ajax
   ========================================================================== */

    Lokris.getReadyStateHandler = function (lwAjax, responseHandler, raw, errorHandler) {

  if (responseHandler == null || responseHandler === undefined) {
    return function() {};  // Dummy function
    // Background: When async==false, MSIE calls getreadystatechange.
    // Mozilla doesn't! 
    // Therefore: Call Lokris.AjaxCall with "null" as 
    // 2nd argument (responseHandler).
    // This if-clause returns a dummy function to be called
    // from MSIE (and Opera, mybe other browsers).
    // Check manual for an example of a synchronous call.
  }


  // Return an anonymous function that listens to the 
  // XMLHttpRequest instance
  return function () {

    // If the request's status is "complete"
    if (lwAjax.request.readyState == 4) {
      if (lwAjax.timeoutId != undefined) {
	window.clearTimeout(lwAjax.timeoutId);
      }
      
      // Check that a successful server response was received
      if (lwAjax.request.status == 200) {

	if (raw != undefined && raw) {
	  responseHandler(lwAjax.request);
	} else {
	  var mimeType = String("" + lwAjax.request.getResponseHeader("Content-Type")).split(';')[0];

	  if ( mimeType == "text/xml" ) {
	    // Pass the XML payload of the response to the 
            // handler function
            responseHandler(lwAjax.request.responseXML);
	  } else {
            // Pass the text payload of the response to the
            // handler function
	    responseHandler(lwAjax.request.responseText);
	  }
	}
      } else {
	  // An HTTP problem has occurred
	  errorHandler(lwAjax.request);
      }
    }
  }
}



/* ==== Backward Compatibility ==== 
   For pages using the old name of the Ajax function 
*/

lwAjaxCall = Lokris.AjaxCall;