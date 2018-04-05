module graphics.components.Label;

import d2d;
import graphics.views.MainActivity;

class Label : Component {

    iRectangle loc;
    string text;

    override @property iRectangle location() {
        return this.loc;
    }

    @property void location(iRectangle newLoc) {
        this.loc = newLoc;
    }

    this(Display container, iRectangle loc, string text) {
        super(container);
        this.loc = loc;
        this.text = text;
    }

    override void draw() {
        Texture text = new Texture(scaled((cast(MainActivity) this.container.activity).font.renderTextBlended(this.text), this.loc.extent.x, this.loc.extent.y), this.container.renderer); 
        this.container.renderer.copy(text, this.loc);
    }

    /**
     *
     */
    void handleEvent(SDL_Event event) {

    }

}