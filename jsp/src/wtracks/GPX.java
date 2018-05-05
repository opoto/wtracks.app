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
    private String id;

    @Persistent
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

    public GPX(String id, String name, String owner, String gpx, int sharedMode) {
        this.id = id;
        this.name = name;
        this.owner = owner;
        this.gpx = new Text(gpx);
        this.sharedMode = sharedMode;
        setSaveDate();
    }

    // Accessors for the fields.  JDO doesn't use these, but your application does.

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }
    
    public void setName(String name) {
      this.name = name;
    }
    
    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    public String getGpx() {
        return gpx.getValue();
    }
    
    public void setGpx(String gpx) {
        this.gpx = new Text(gpx);
    }

    public int getSharedMode() {
        return sharedMode;
    }

    public void setSharedMode(int sharedMode) {
        this.sharedMode = sharedMode;
    }

    public Date getSaveDate() {
        return saveDate;
    }
    
    public void setSaveDate() {
        saveDate = new Date();
    }

    public void setSaveDate(Date date) {
        this.saveDate = date;
    }

    public String toString() {
        return "{ name: " + name + ", id:" + id + ", owner: " + owner + ", sharedMode: " + sharedMode + ", saveDate: " + saveDate + "}";  
    }
}
