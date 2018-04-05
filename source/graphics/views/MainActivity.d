module graphics.views.MainActivity;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import d2d;
import graphics.Constants;
import graphics.components.PauseButton;
import graphics.components.Legend;
import graphics.components.ToggleGroup;
import logic.assimilation.Assimilator;
import logic.assimilation.likelihood.Likelihood;
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
    int moveScale = 2; ///The factor by which xScale moves every button press, scaling dt
    dVector xOffset; ///The default offset in time from the current running time
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
    bool showingEnsemble; ///Whether ensemble members are also being graphed (false for speed and cleanness)
    bool isAssimilating; ///Whether or not assimilation is happening
    bool isObserving; ///Whether or not observations are being made
    double dt; ///How fast the scale moves in time
    double observationFrequency; ///How frequently measurements are taken
    double time = 0; ///Where the front is in time
    ErrorGenerator observer; ///How observations are recorded
    Assimilator assimilator; ///Handles assimilation
    double errorSum = 0; ///Used in calculating RMSE; sum of squares of error
    double xErrorSum = 0; ///Error sum as if x were the only variable
    double RMSE; ///Root mean square error (sqrt of the mean of the squares of the distances between truth and ensemble mean)
    double xRMSE; ///RMSE in x
    int numTimes = 0; ///How many times should be counted in RMSE
    bool garbageCollect; ///Should points off the screen be deleted? if false, demo may slow down but you'll be able to return

    /**
     * Constructor for the main activity
     * Organizes the components into locations 
     */
    this(
            Display display, 
            PointGetter truth, EnsembleLeader ensembleMean, EnsembleFollower[] ensembleMembers, 
            ErrorGenerator observer, Assimilator assimilator,
            Color truthColor, Color ensembleMeanColor, Color ensembleColor, Color observationColor,
            AxisAlignedBoundingBox!(int, 2) location, 
            dVector xScale, dVector yScale, 
            double dt, double observationFrequency
        ) { 
        super(display);
        this.location = location;
        this.xScale = new dVector(xScale);
        this.xOffset = new dVector(xScale);
        this.yScale = new dVector(yScale);
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
        //Assimilation
        this.assimilator = assimilator;

        this.pointGetters = [this.truth, this.ensembleMean] ~ cast(PointGetter[]) this.ensembleMembers;
        this.colors = [this.truthColor, this.ensembleMeanColor];
        foreach(i; 0..this.ensembleMembers.length) this.colors ~= this.ensembleColor;

        //Components/Buttons
        this.components ~= new PauseButton(this.container, new iRectangle(logicalSize.x * 7 / 8, logicalSize.y / 2, logicalSize.x * 1 / 16, logicalSize.x / 32));
        this.components ~= new Legend(this.container, new iRectangle(this.location.initialPoint.x + this.location.extent.x * 3 / 4, this.location.initialPoint.y, this.location.extent.x * 1 / 4, this.location.extent.y * 1 / 4), ["Truth", "Ensemble Mean", "Ensemble", "Observation"], [PredefinedColor.RED, PredefinedColor.BLUE, PredefinedColor.GREEN, PredefinedColor.BLACK], [LegendStyle.LINE, LegendStyle.LINE, LegendStyle.LINE, LegendStyle.POINT]);
        iRectangle baseline = new iRectangle(logicalSize.x * 3 / 4, logicalSize.y * 1 / 32, logicalSize.x * 1 / 8, logicalSize.x * 1 / 64);
        this.components ~= new ToggleGroup(this.container, 
            new iRectangle(baseline.initialPoint.x + baseline.extent.x * 1 / 2, baseline.initialPoint.y, baseline.extent.x * 1 / 4, baseline.extent.y), 
            new iRectangle(baseline.initialPoint.x + baseline.extent.x * 3 / 4, baseline.initialPoint.y, baseline.extent.x * 1 / 4, baseline.extent.y), 
            new iRectangle(baseline.initialPoint.x, baseline.initialPoint.y, baseline.extent.x * 1 / 2, baseline.extent.y), 
            &this.showingEnsemble, "Showing Ensemble"
        );
    }

    /** 
     * Toggles deleting extra points
     * If turned on, also cleans up the timeseries
     */
    void toggleGarbageCollect() {
        this.garbageCollect = !this.garbageCollect;
        if(this.garbageCollect) {
            foreach(pointGetter; [this.truth] ~ cast(PointGetter[])[this.ensembleMean] ~ cast(PointGetter[])this.ensembleMembers) {
                while(pointGetter.points.times[1] < this.xScale.x) {
                    pointGetter.points.pop(0);
                }
            }
        }
    }

    /**
     * Resets the scale to center the current time
     * Done in a separate function for expandability
     */
    void resetToScale() {
        this.xScale = new dVector(this.xOffset + this.time);
    }

    /**
     * Handles keyboard and mouse events
     * TODO: Make buttons for this
     */
    override void handleEvent(SDL_Event event) {
        if (this.container.keyboard.allKeys[SDLK_ESCAPE].testAndRelease()) {
            this.isRunning = !this.isRunning;
        }
        if (this.container.keyboard.allKeys[SDLK_TAB].testAndRelease()) {
            this.showingEnsemble = !this.showingEnsemble;
        }
        if (this.container.keyboard.allKeys[SDLK_PAGEUP].testAndRelease()) {
            this.isObserving = !this.isObserving;
        }
        if (this.container.keyboard.allKeys[SDLK_PAGEDOWN].testAndRelease()) {
            this.isAssimilating = !this.isAssimilating;
        }
        if (this.container.keyboard.allKeys[SDLK_BACKSPACE].testAndRelease()) {
            this.toggleGarbageCollect();
        }
        if(!isRunning) {
            if(this.container.keyboard.allKeys[SDLK_LEFT].testAndRelease()) {
                this.xScale -= this.moveScale * this.dt;
            }
            if(this.container.keyboard.allKeys[SDLK_RIGHT].testAndRelease()) {
                this.xScale += this.moveScale * this.dt;
            }
            if(this.container.keyboard.allKeys[SDLK_SPACE].testAndRelease()) {
                this.resetToScale;
            }
        }
    }

    /**
     * Updates the toDraw list of pointGetters
     */
    void update(uint index) {
        PointGetter pointGetter = this.pointGetters[index];    
        if(this.xScale.x > pointGetter.points.times[0] && this.garbageCollect) {
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
     * Update without getting points
     * Used when not running and returning
     * Should probably be combined with update
     */
    void updateStagnant(uint index) {
        PointGetter pointGetter = this.pointGetters[index];    
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
                if(this.isObserving) {
                    Likelihood likelihood = new Likelihood(this.observer.observe(this.truth.position, this.time), this.observer.error);
                    if(this.isAssimilating) {
                        this.assimilator.setLikelihood(likelihood);
                        this.ensembleMean.ensemble = this.assimilator(this.ensembleMean.ensemble);
                        //The following code makes the ensemble generate twice on assimilation. It may look nicer
                        //Comment if speed is a concern
                        /*this.ensembleMean.points.add(this.time, this.ensembleMean.ensemble.eMean.x);
                        foreach(point; this.ensembleMembers) {
                            point.points.add(this.time, this.ensembleMean.ensemble.members[point.index].x);
                        }*/
                    }
                }
            }
            this.updateObservations();
            double ensx = this.ensembleMean.ensemble.eMean.x;
            double ensy = this.ensembleMean.ensemble.eMean.y;
            double ensz = this.ensembleMean.ensemble.eMean.z;
            double truex = this.truth.position.x;
            double truey = this.truth.position.y;
            double truez = this.truth.position.z;
            this.numTimes += 1;
            this.xErrorSum += (truex - ensx).pow(2);
            this.errorSum += (truex - ensx).pow(2) + (truey - ensy).pow(2) + (truez - ensz).pow(2);
            this.RMSE = sqrt(this.errorSum / this.numTimes);
            this.xRMSE = sqrt(this.xErrorSum / this.numTimes);
        } else {
            foreach(i; 0..this.pointGetters.length) {
                this.updateStagnant(i);
            }
            this.updateObservations;
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
        if(this.showingEnsemble) {
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
        //Write RMSE
        /*text = new Texture(this.font.renderTextSolid("RMSE: " ~ this.RMSE.to!string), this.container.renderer);
        this.container.renderer.copy(text, new iRectangle(this.location.bottomRight.x + logicalSize.x / 20, this.location.bottomRight.y - logicalSize.y / 10, 20 * (6 + this.RMSE.to!string.length), 40));
        text = new Texture(this.font.renderTextSolid("xRMSE: " ~ this.xRMSE.to!string), this.container.renderer);
        this.container.renderer.copy(text, new iRectangle(this.location.bottomRight.x + logicalSize.x / 20, this.location.bottomRight.y - logicalSize.y / 10 - 45, 20 * (7 + this.xRMSE.to!string.length), 40));*/

    }
}