package wtracks.server;

import wtracks.client.WTrackService;

import com.google.gwt.user.server.rpc.RemoteServiceServlet;

/**
 * The server side implementation of the RPC service.
 */
@SuppressWarnings("serial")
public class WTrackServiceImpl extends RemoteServiceServlet implements WTrackService {

  @Override
  public String getFile(String url, String contentType) {
    // TODO
    return null;
  }

  @Override
  public String[] getUserTracks(String userid) {
    // TODO
    return null;
  }
}
