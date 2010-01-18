package wtracks.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.core.client.GWT;
import com.google.gwt.dom.client.Document;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.event.dom.client.KeyCodes;
import com.google.gwt.event.dom.client.KeyPressEvent;
import com.google.gwt.event.dom.client.KeyPressHandler;
import com.google.gwt.maps.client.InfoWindowContent;
import com.google.gwt.maps.client.MapWidget;
import com.google.gwt.maps.client.control.LargeMapControl;
import com.google.gwt.maps.client.control.MapTypeControl;
import com.google.gwt.maps.client.geocode.Geocoder;
import com.google.gwt.maps.client.geocode.LatLngCallback;
import com.google.gwt.maps.client.geom.LatLng;
import com.google.gwt.maps.client.overlay.Marker;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.RootPanel;
import com.google.gwt.user.client.ui.SimpleCheckBox;
import com.google.gwt.user.client.ui.SubmitButton;
import com.google.gwt.user.client.ui.TextBox;

/**
 * Entry point classes define <code>onModuleLoad()</code>.
 */
public class Home implements EntryPoint {
	/**
	 * Create a remote service proxy to talk to the server-side Greeting service.
	 */
	private final WTrackServiceAsync greetingService = GWT.create(WTrackService.class);

	private MapWidget map;
	private Document doc;

	private TextBox addr;

	/**
	 * This is the entry point method.
	 */
	public void onModuleLoad() {

		LatLng cawkerCity = LatLng.newInstance(39.509, -98.434);
		// Open a map centered on Cawker City, KS USA

		map = new MapWidget(cawkerCity, 2);
		map.setSize("100%", "600px");

		// Add some controls for the zoom level
		map.addControl(new LargeMapControl());
		map.addControl(new MapTypeControl());

		// Add a marker
		map.addOverlay(new Marker(cawkerCity));


		// Add the map to the HTML host page
		RootPanel.get("map").add(map);
		
		doc = Document.get();
		
		addr = TextBox.wrap(doc.getElementById("addr"));
		addr.addKeyPressHandler(new KeyPressHandler() {
			@Override
			public void onKeyPress(KeyPressEvent event) {
				if (event.getCharCode() == KeyCodes.KEY_ENTER) {
					gotoAddress(addr.getValue());
				}
				
			}
		});
		SubmitButton.wrap(doc.getElementById("addrgo")).addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				gotoAddress(addr.getValue());
			}
		});

		SimpleCheckBox.wrap(doc.getElementById("showlabels")).addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				// TODO
			}

		});
		SimpleCheckBox.wrap(doc.getElementById("showmarkers")).addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				// TODO
			}

		});
		SimpleCheckBox.wrap(doc.getElementById("showwaypoints")).addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				// TODO
			}

		});
		Button.wrap(doc.getElementById("profile2D")).addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				// TODO
			}

		});
	}

	private void gotoAddress(final String address) {
		new Geocoder().getLatLng(address, new LatLngCallback() {
			
			@Override
			public void onSuccess(LatLng point) {
				map.setCenter(point, 13);
				map.getInfoWindow().open(point, new InfoWindowContent(address));
			}
			
			@Override
			public void onFailure() {
				Window.alert("gotoAddress failed");
			}
		});
	}
}
