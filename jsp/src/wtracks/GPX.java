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
    private boolean isPublic;

    @Persistent
    private Date saveDate;

    public GPX(String name, String owner, String gpx, boolean isPublic, Date saveDate) {
        this.name = name;
        this.owner = owner;
        this.gpx = new Text(gpx);
        this.isPublic = isPublic;
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

    public boolean isPublic() {
        return isPublic;
    }

    public Date getSaveDate() {
        return saveDate;
    }

}
