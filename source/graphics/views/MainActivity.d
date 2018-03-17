module graphics.views.MainActivity;

import std.algorithm;
import std.array;
import std.math;
import d2d;
import logic.demo.PointGetter;

/**
 * The site of the main UI
 */
class MainActivity : Activity {

    PointGetter pointGetter; ///Gets points to graph
    double[] drawablePoints; ///All the points to be on the screen
    AxisAlignedBoundingBox!(int, 2) location;
    dVector xScale;
    dVector yScale;
    iVector[] toDraw; ///The points to be drawn in a frame

    /**
     * Constructor for the main activity
     * Organizes the components into locations 
     */
    this(Display display, PointGetter pointGetter, AxisAlignedBoundingBox!(int, 2) location, dVector xScale, dVector yScale) { 
        super(display);
        this.pointGetter = pointGetter;
        this.pointGetter.points.add(xScale.x, (yScale.y - yScale.x) / 2);
        this.location = location;
        this.xScale = xScale;
        this.yScale = yScale;
        this.drawablePoints = pointGetter.points.timeAssociate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
    }

    /**
     * Handles keyboard and mouse events
     */
    override void handleEvent(SDL_Event event) {
    }

    /**
     * Action taken every frame
     */
    override void update() {        
        //if(((this.yScale.x + this.yScale.y) / 2 / this.pointGetter.dt).approxEqual(floor((this.yScale.x + this.yScale.y) / 2 / this.pointGetter.dt))) { 
            this.pointGetter.getPoint();
        //}
        double[double] associate = this.pointGetter.points.timeAssociate;
        this.drawablePoints = associate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.xScale += this.pointGetter.dt;
        this.toDraw = null;
        double[double] timeSeries = this.pointGetter.points.timeAssociate;
        foreach(val; this.drawablePoints.sort) {
            if(this.yScale.x <= timeSeries[val] && timeSeries[val] <= this.yScale.y) {
                this.toDraw ~= cast(iVector) new dVector(
                    this.location.initialPoint.x + (val - this.xScale.x) * (this.location.extent.x) / (this.xScale.y - this.xScale.x),
                    this.location.initialPoint.y + (timeSeries[val] - this.yScale.x) * (this.location.extent.y) / (this.yScale.y - this.yScale.x)
                );
            }
        }
    }

    /**
     * Draw instructions for the window
     */
    override void draw() {
        this.container.renderer.clear(PredefinedColor.WHITE);
        if(toDraw.length > 1) {
            foreach(i; 0..this.toDraw.length - 1) {
                this.container.renderer.draw(new iSegment(this.toDraw[i], this.toDraw[i + 1]), PredefinedColor.BLUE);
            }
        } else if(toDraw.length == 1) {
            this.container.renderer.drawPoint(this.toDraw[0]);
        }        
    }
}