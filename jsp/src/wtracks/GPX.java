package wtracks;

import com.google.appengine.api.datastore.Key;
import java.util.Date;
import com.google.appengine.api.datastore.Text;
import javax.jdo.annotations.IdGeneratorStrategy;
import javax.jdo.annotations.PersistenceCapable;
import javax.jdo.annotations.Persistent;
import javax.jdo.annotations.PrimaryKey;

@PersistenceCapable
public class GPX {
    @PrimaryKey
    private String name;

    @Persistent
    private String owner;

    @Persistent
    private Text gpx;

    @Persistent
    private int sharedMode;

    public final static int SHARED_PRIVATE = 0;
    public final static int SHARED_LINK = 1;
    public final static int SHARED_PUBLIC = 2;

    @Persistent
    private Date saveDate;

    public GPX(String name, String owner, String gpx, int sharedMode, Date saveDate) {
        this.name = name;
        this.owner = owner;
        this.gpx = new Text(gpx);
        this.sharedMode = sharedMode;
        this.saveDate = saveDate;
    }

    // Accessors for the fields.  JDO doesn't use these, but your application does.

    public String getName() {
        return name;
    }

    public String getOwner() {
        return owner;
    }

    public String getGpx() {
        return gpx.getValue();
    }

    public int getSharedMode() {
        return sharedMode;
    }

    public Date getSaveDate() {
        return saveDate;
    }

}
