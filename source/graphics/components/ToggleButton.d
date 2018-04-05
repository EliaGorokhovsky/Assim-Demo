module graphics.components.ToggleButton;

import d2d;
import graphics.views.MainActivity;

/**
 * A component which toggles a certain parameter when clicked, as well as displaying that parameter's name and on state
 */
class ToggleButton : Button {

    iRectangle nameLocation; ///Where the name of the variable is
    iRectangle stateLocation; ///Where the state of the variable is (Off, On)
    bool* param;

    /**
     * Creates a pauseButton at a location
     */
    this(Display container, iRectangle location, iRectangle nameLocation, iRectangle stateLocation, bool* param) {
        super(container, location);
        this.nameLocation = nameLocation;
        this.stateLocation = stateLocation;
        this.param = param;
    }

    override void handleEvent(SDL_Event event) {
        super.handleEvent(event);
    }

    /**
     * Defined action when the button is clicked; switches isRunning
     */
    override void action() {
        *this.param = !*this.param;        
    }

    /**
     * Draws the button with different colors depending on its state - compressed or decompressed
     */
    override void draw() {
        bool isOn = *this.param;
        this.container.renderer.fill(this.location, PredefinedColor.DARKGREY);
        int xStart = isOn? this.location.center.x : this.location.initialPoint.x;
        this.container.renderer.fill(new iRectangle(xStart, this.location.initialPoint.y, this.location.extent.x / 2, this.location.extent.y), PredefinedColor.GREEN);
    }
}