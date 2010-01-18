package wtracks.client;

import com.google.gwt.user.client.rpc.RemoteService;
import com.google.gwt.user.client.rpc.RemoteServiceRelativePath;

/**
 * The client side stub for the RPC service.
 */
@RemoteServiceRelativePath("greet")
public interface WTrackService extends RemoteService {
	String getFile(String url, String contentType);
	
	String[] getUserTracks(String userid);
}
