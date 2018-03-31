module graphics.views.MainActivity;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import d2d;
import graphics.Constants;
import graphics.components.PauseButton;
import logic.demo.EnsembleLeader;
import logic.demo.EnsembleFollower;
import logic.demo.PointGetter;
import logic.demo.LorenzPoint;
import logic.demo.ErrorGenerator;

/**
 * The site of the main UI
 */
class MainActivity : Activity {

    PointGetter truth; ///Gets truth
    EnsembleLeader ensembleMean; ///Gets the mean value of the ensemble
    EnsembleFollower[] ensembleMembers; ///Gets ensemble member points
    PointGetter[] pointGetters; ///A list of all the point getters
    double[][] drawablePoints; ///All the points to be on the screen
    AxisAlignedBoundingBox!(int, 2) location; ///The location of the graph element
    dVector xScale; ///The range of x(time) values represented on the graph
    uint xTicks = 4; ///How many tick marks are represented on the time scale
    dVector yScale; ///The range of y values represented on the graph
    uint yTicks = 5; ///How many tick marks are represented on the y scale
    iVector[][] toDraw; ///The points to be drawn in a frame
    Color truthColor; ///The color of the true curve
    Color ensembleMeanColor; ///The color of the ensemble mean curve
    Color ensembleColor; ///The color of the ensemble curves
    Color observationColor; ///The color of the observations
    Color[] colors; ///The list of all the colors for the curves
    Font font; ///The font with which to draw text
    bool isRunning; ///Whether the demo is paused
    double dt; ///How fast the scale moves in time
    double observationFrequency; ///How frequently measurements are taken
    double time = 0; ///Where the front is in time
    ErrorGenerator observer; ///How observations are recorded

    /**
     * Constructor for the main activity
     * Organizes the components into locations 
     */
    this(
            Display display, 
            PointGetter truth, EnsembleLeader ensembleMean, EnsembleFollower[] ensembleMembers, 
            ErrorGenerator observer,
            Color truthColor, Color ensembleMeanColor, Color ensembleColor, Color observationColor,
            AxisAlignedBoundingBox!(int, 2) location, 
            dVector xScale, dVector yScale, 
            double dt, double observationFrequency
        ) { 
        super(display);
        this.location = location;
        this.xScale = xScale;
        this.yScale = yScale;
        this.dt = dt;
        this.observationFrequency = observationFrequency;
        this.font = new Font("res/fonts/OpenSansRegular.ttf", 100);
        //Truth
        this.truth = truth;
        this.drawablePoints ~= truth.points.timeAssociate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.toDraw ~= null;
        this.truthColor = truthColor;
        //Ensemble mean
        this.ensembleMean = ensembleMean;
        this.drawablePoints ~= ensembleMean.points.timeAssociate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.toDraw ~= null;
        this.ensembleMeanColor = ensembleMeanColor;
        //Ensemble members
        this.ensembleMembers = ensembleMembers;
        foreach(pointGetter; ensembleMembers) {
            this.drawablePoints ~= pointGetter.points.timeAssociate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
            this.toDraw ~= null;
        }
        this.ensembleColor = ensembleColor;
        //Observer
        this.observer = observer;
        this.drawablePoints ~= null; //for observations
        this.toDraw ~= null;
        this.observationColor = observationColor;

        this.pointGetters = [this.truth, this.ensembleMean] ~ cast(PointGetter[]) this.ensembleMembers;
        this.colors = [this.truthColor, this.ensembleMeanColor];
        foreach(i; 0..this.ensembleMembers.length) this.colors ~= this.ensembleColor;

        this.components ~= new PauseButton(this.container, new iRectangle(logicalSize.x * 7 / 8, logicalSize.y / 2, logicalSize.x * 1 / 16, logicalSize.x / 32));
        
    }

    /**
     * Handles keyboard and mouse events
     */
    override void handleEvent(SDL_Event event) {
        if (this.container.keyboard.allKeys[SDLK_ESCAPE].testAndRelease()) {
            this.isRunning = !this.isRunning;
        }
    }

    /**
     * Updates the toDraw list of pointGetters
     */
    void update(uint index) {
        PointGetter pointGetter = this.pointGetters[index];    
        if(this.xScale.x > pointGetter.points.times[0]) {
            pointGetter.points.pop(0);
        }
        pointGetter.getPoint();
        double[double] associate = pointGetter.points.timeAssociate;
        this.drawablePoints[index] = associate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.toDraw[index] = null;
        foreach(val; this.drawablePoints[index].sort) {
            if(this.yScale.x <= associate[val] && associate[val] <= this.yScale.y) {
                this.toDraw[index] ~= cast(iVector) new dVector(
                    this.location.initialPoint.x + (val - this.xScale.x) * (this.location.extent.x) / (this.xScale.y - this.xScale.x),
                    this.location.initialPoint.y + (associate[val] - this.yScale.x) * (this.location.extent.y) / (this.yScale.y - this.yScale.x)
                );
            }
        }
    }

    /**
     * updates toDraw observations
     */
    void updateObservations() {
        double[double] associate = this.observer.points.timeAssociate;
        this.drawablePoints[$ - 1] = associate.keys.filter!(a => (this.xScale.x <= a && a <= this.xScale.y)).array;
        this.toDraw[$ - 1] = null;
        foreach(val; this.drawablePoints[$ - 1].sort) {
            if(this.yScale.x <= associate[val] && associate[val] <= this.yScale.y) {
                this.toDraw[$ - 1] ~= cast(iVector) new dVector(
                    this.location.initialPoint.x + (val - this.xScale.x) * (this.location.extent.x) / (this.xScale.y - this.xScale.x),
                    this.location.initialPoint.y + (associate[val] - this.yScale.x) * (this.location.extent.y) / (this.yScale.y - this.yScale.x)
                );
            }
        }
    }

    /**
     * Action taken every frame
     */
    override void update() {
        if(isRunning) {
            this.xScale += this.dt;
            this.time += this.dt;
            foreach(i; 0..this.pointGetters.length) {
                this.update(i);
            }
            if(abs(this.time % this.observationFrequency) < this.dt) {
                this.observer.observe(this.truth.position, this.time);
            }
            this.updateObservations();
        }
    }

    /**
     * Draw instructions for the window
     */
    override void draw() {
        this.container.renderer.clear(PredefinedColor.LIGHTGREY);
        this.container.renderer.fill(this.location, PredefinedColor.WHITE);
        //Draw curves
        //Ensemble members
        foreach(curve; 2..this.drawablePoints.length - 1) {
            if(this.toDraw[curve].length > 1) {
                foreach(i; 0..this.toDraw[curve].length - 1) {
                    this.container.renderer.draw(new iSegment(this.toDraw[curve][i], this.toDraw[curve][i + 1]), this.colors[curve]);
                }
                //this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.toDraw[curve][$ - 1] - 5, new iVector(10, 10)), this.colors[curve]);  
            } else if(this.toDraw[curve].length == 1) {
                this.container.renderer.draw(this.toDraw[curve][0]);
            }
        }
        //Truth
        if(this.toDraw[0].length > 1) {
            foreach(i; 0..this.toDraw[0].length - 1) {
                this.container.renderer.draw(new iSegment(this.toDraw[0][i], this.toDraw[0][i + 1]), this.colors[0]);
            }
            //this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.toDraw[0][$ - 1] - 5, new iVector(10, 10)), this.colors[0]);  
        } else if(this.toDraw[0].length == 1) {
            this.container.renderer.draw(this.toDraw[0][0]);
        }
        //Ensemble mean
        if(this.toDraw[1].length > 1) {
            foreach(i; 0..this.toDraw[1].length - 1) {
                this.container.renderer.draw(new iSegment(this.toDraw[1][i], this.toDraw[1][i + 1]), this.colors[1]);
            }
            //this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(this.toDraw[1][$ - 1] - 5, new iVector(10, 10)), this.colors[1]);  
        } else if(this.toDraw[1].length == 1) {
            this.container.renderer.draw(this.toDraw[1][0]);
        }
        //Observations
        foreach(point; this.toDraw[$ - 1]) {
            this.container.renderer.fill(new AxisAlignedBoundingBox!(int, 2)(point - 5, new iVector(11, 11)), this.observationColor);
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