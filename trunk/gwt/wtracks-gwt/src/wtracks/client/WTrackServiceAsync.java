package wtracks.client;

import com.google.gwt.user.client.rpc.AsyncCallback;

/**
 * The async counterpart of <code>GreetingService</code>.
 */
public interface WTrackServiceAsync {
  void getFile(String url, String contentType, AsyncCallback<String> callback);

  void getUserTracks(String userid, AsyncCallback<String[]> callback);
}
