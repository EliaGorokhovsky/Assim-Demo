module graphics.views.MainActivity;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import d2d;
import graphics.Constants;
import logic.demo.PointGetter;

/**
 * The site of the main UI
 */
class MainActivity : Activity {

    PointGetter[] pointGetters; ///Gets points to graph
    double[][] drawablePoints; ///All the points to be on the screen
    AxisAlignedBoundingBox!(int, 2) location; ///The location of the graph element
    dVector xScale; ///The range of x(time) values represented on the graph
    uint xTicks = 5; ///How many tick marks are represented on the time scale
    dVector yScale; ///The range of y values represented on the graph
    uint yTicks = 5; ///How many tick marks are represented on the y scale
    iVector[][] toDraw; ///The points to be drawn in a frame
    Color[] colors; ///The colors of each of the curves to draw
    Font font; ///The font with which to draw text

    /**
     * Constructor for the main activity
     * Organizes the components into locations 
     */
    this(Display display, PointGetter[] pointGetters, AxisAlignedBoundingBox!(int, 2) location, dVector xScale, dVector yScale) { 
        super(display);
        this.font = new Font("res/fonts/OpenSansRegular.ttf", 100);
        this.pointGetters = pointGetters;
        this.location = location;
        this.xScale = xScale;
        this.yScale = yScale;
        foreach(pointGetter; pointGetters) this.drawablePoints ~= pointGetter.points.timeAssociate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        foreach(pointGetter; pointGetters) this.toDraw ~= null;
        this.colors = [PredefinedColor.BLUE, PredefinedColor.RED, PredefinedColor.GREEN];
    }

    /**
     * Handles keyboard and mouse events
     */
    override void handleEvent(SDL_Event event) {
    }

    /**
     * Updates the toDraw list of pointGetters
     */
    void update(uint index) {
        PointGetter pointGetter = this.pointGetters[index];     
        if(this.xScale.x > pointGetter.points.times[0]) {
            pointGetter.points.pop(0);
        }  
        //if(((this.yScale.x + this.yScale.y) / 2 / this.pointGetter.dt).approxEqual(floor((this.yScale.x + this.yScale.y) / 2 / this.pointGetter.dt))) { 
            pointGetter.getPoint();
        //}
        double[double] associate = pointGetter.points.timeAssociate;
        //import std.stdio; writeln("Curve ", index, ": ", associate);
        this.drawablePoints[index] = associate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.toDraw[index] = null;
        assert(toDraw[index].length == 0, "toDraw isn't being emptied");
        //import std.stdio; writeln(index, ", ", this.drawablePoints[index].sort.map!(a => associate[a]));
        foreach(val; this.drawablePoints[index].sort) {
            if(this.yScale.x <= associate[val] && associate[val] <= this.yScale.y) {
                this.toDraw[index] ~= cast(iVector) new dVector(
                    this.location.initialPoint.x + (val - this.xScale.x) * (this.location.extent.x) / (this.xScale.y - this.xScale.x),
                    this.location.initialPoint.y + (associate[val] - this.yScale.x) * (this.location.extent.y) / (this.yScale.y - this.yScale.x)
                );
            }
        }
        //writeln(associate);
    }

    /**
     * Action taken every frame
     */
    override void update() {
        this.xScale += this.pointGetters[0].dt;
        foreach(i; 0..this.pointGetters.length) {
            this.update(i);
        }
    }

    /**
     * Draw instructions for the window
     */
    override void draw() {
        this.container.renderer.clear(PredefinedColor.WHITE);
        this.container.renderer.fill(this.location, PredefinedColor.LIGHTGREY);
        //Draw curves
        foreach(curve; 0..this.drawablePoints.length) {
            if(this.toDraw[curve].length > 1) {
                foreach(i; 0..this.toDraw[curve].length - 1) {
                    this.container.renderer.draw(new iSegment(this.toDraw[curve][i], this.toDraw[curve][i + 1]), this.colors[curve]);
                }
            //this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.toDraw[$ - 1] - 5, new iVector(10, 10)), PredefinedColor.GREEN);  
            //this.container.renderer.draw(new iSegment(new iVector(this.toDraw[$ - 1].x, this.location.initialPoint.y), new iVector(this.toDraw[$ - 1].x, this.location.bottomLeft.y)), PredefinedColor.RED);      
            } else if(this.toDraw[curve].length == 1) {
                this.container.renderer.draw(this.toDraw[curve][0]);
            }
        }
        //Draw scale
        //TODO: Avoid hardcoding location
        this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.location.initialPoint.x - 2, this.location.initialPoint.y - 2, 4, this.location.extent.y + 4));
        this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.location.bottomLeft.x - 2, this.location.bottomLeft.y - 2, this.location.extent.x + 4, 4));
        foreach(i; 0..this.xTicks) {
            double value =  this.xScale.x + i * (this.xScale.y - this.xScale.x) / (this.xTicks - 1);
            string textValue = value.to!string;
            string roundedTextValue = value.trunc.to!string;
            Texture text = new Texture(this.font.renderTextSolid(textValue), this.container.renderer);
            int xCenter = this.location.bottomLeft.x + i * this.location.extent.x / (this.xTicks - 1);
            this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(xCenter - 2, this.location.bottomLeft.y - logicalSize.y / 80, 4, logicalSize.y / 40));
            this.container.renderer.copy(text, new iRectangle(xCenter - 10 * (roundedTextValue.length + 2), this.location.bottomLeft.y + logicalSize.y / 80, 20 * textValue.length, 40));
        }
        foreach(i; 0..this.yTicks) {
            double value = this.yScale.y - i * (this.yScale.y - this.yScale.x) / (this.yTicks - 1);
            string textValue = value.to!string;
            Texture text = new Texture(this.font.renderTextSolid(textValue), this.container.renderer);
            int yCenter = this.location.initialPoint.y + i * this.location.extent.y / (this.yTicks - 1);
            this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.location.initialPoint.x - logicalSize.y / 80, yCenter - 2, logicalSize.y / 40, 4));
            this.container.renderer.copy(text, new iRectangle(this.location.initialPoint.x - logicalSize.y / 80 - 20 * textValue.length, yCenter - 20, 20 * textValue.length, 40));
        }
        Texture text = new Texture(this.font.renderTextSolid("t"), this.container.renderer);
        this.container.renderer.copy(text, new iRectangle(this.location.bottomRight.x + logicalSize.x / 80, this.location.bottomRight.y - 20, 20, 40));
        text = new Texture(this.font.renderTextSolid("x"), this.container.renderer);
        this.container.renderer.copy(text, new iRectangle(this.location.initialPoint.x - 10, this.location.initialPoint.y - 40 - logicalSize.y / 80, 20, 40));
    }
}