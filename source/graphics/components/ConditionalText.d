module graphics.components.ConditionalText;

import d2d;
import graphics.views.MainActivity;

class ConditionalText : Component {

    iRectangle loc;
    bool* param;
    string onText;
    string offText;

    override @property iRectangle location() {
        return this.loc;
    }

    @property void location(iRectangle newLoc) {
        this.loc = newLoc;
    }

    this(Display container, iRectangle loc, bool* param, string onText, string offText) {
        super(container);
        this.loc = loc;
        this.param = param;
        this.onText = onText;
        this.offText = offText;
    }

    override void draw() {
        bool on = *param;
        string toWrite = on? this.onText : this.offText;
        Texture text = new Texture(scaled((cast(MainActivity) this.container.activity).font.renderTextBlended(toWrite), this.loc.extent.x, this.loc.extent.y), this.container.renderer); 
        this.container.renderer.copy(text, this.loc);
    }

    /**
     *
     */
    void handleEvent(SDL_Event event) {

    }

}