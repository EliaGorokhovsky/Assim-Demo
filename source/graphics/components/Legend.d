module graphics.components.Legend;

import d2d;
import graphics.views.MainActivity;

enum LegendStyle : string {
    LINE = "--",
    DASH = "- -",       //TODO
    DASHDOT = "-.-",    //TODO
    POINT = "."
}

/**
 * A legend
 * Displays colors and labels
 */
class Legend : Component {

    iRectangle currentLocation;
    iRectangle textBox;
    iRectangle exampleBox;
    int textHeight;
    Font font;
    string[] entries;
    Color[] colors;
    LegendStyle[] styles;
    int borderWidth;

    /**
     *
     */
    override @property iRectangle location() {
        return this.currentLocation;
    }

    /**
     *
     */
    @property void location(iRectangle newLoc) {
        this.currentLocation = newLoc;
    }

    this(Display container, iRectangle location, string[] entries, Color[] colors, LegendStyle[] styles, int borderWidth = 3) {
        super(container);
        this.currentLocation = location;
        this.entries = entries;
        this.colors = colors;
        this.styles = styles;
        this.borderWidth = borderWidth;
        this.textBox = new iRectangle(this.location.initialPoint.x + 8 * this.location.extent.x / 27, this.location.initialPoint.y + this.location.extent.y / 16, this.location.extent.x * 2 / 3, this.location.extent.y * 27 / 32);
        this.exampleBox = new iRectangle(this.location.initialPoint.x + borderWidth, this.location.initialPoint.y + this.location.extent.y / 16, 8 * this.location.extent.x / 27 - borderWidth, this.location.extent.y * 27 / 32);
        this.textHeight = this.textBox.extent.y / this.entries.length - this.location.extent.y / 32;
    }

    /**
     * Draws the legend every turn
     */
    override void draw() {
        this.container.renderer.fill(this.location, PredefinedColor.DARKGREY);
        this.container.renderer.fill(
            new iRectangle(
                this.location.initialPoint.x + this.borderWidth, 
                this.location.initialPoint.y + this.borderWidth, 
                this.location.extent.x - 2 * this.borderWidth,
                this.location.extent.y - 2 * this.borderWidth
            ), PredefinedColor.LIGHTGREY
        );
        //Take 1/16 margins on the top and bottom as well as 1/32 margins in between
        foreach(i; 0..this.entries.length) {
            Texture text = new Texture(scaled((cast(MainActivity) this.container.activity).font.renderTextBlended(this.entries[i]), this.textBox.extent.x, this.textHeight), this.container.renderer); 
            iRectangle loc = new iRectangle(
                this.textBox.initialPoint.x,
                this.textBox.initialPoint.y + i * (this.textHeight + this.location.extent.y / 32),
                this.textBox.extent.x,
                this.textHeight
            );
            this.container.renderer.copy(text, loc);
            loc = new iRectangle(
                this.exampleBox.initialPoint.x,
                this.exampleBox.initialPoint.y + i * (this.textHeight + this.location.extent.y / 32),
                this.exampleBox.extent.x,
                this.textHeight
            );
            if(this.styles[i] == LegendStyle.LINE) {
                this.container.renderer.fill(new iRectangle(loc.center.x - loc.extent.x / 4, loc.center.y - loc.extent.y / 8, loc.extent.x / 2, loc.extent.y / 4), this.colors[i]);
            } else if(this.styles[i] == LegendStyle.POINT) {
                this.container.renderer.fill(new iRectangle(loc.center.x - loc.extent.x / 8, loc.center.y - loc.extent.x / 8, loc.extent.x / 4, loc.extent.x / 4), this.colors[i]);
            }
        }
        
    }

    /**
     *
     */
    void handleEvent(SDL_Event event) {

    }

}