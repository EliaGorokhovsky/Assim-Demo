module graphics.components.PauseButton;

import d2d;
import graphics.views.MainActivity;

/**
 * A component which toggles the game pausing when clicked
 */
class PauseButton : Button {

    /**
     * Creates a pauseButton at a location
     */
    this(Display container, iRectangle location) {
        super(container, location);
    }

    override void handleEvent(SDL_Event event) {
        super.handleEvent(event);
    }

    /**
     * Defined action when the button is clicked; switches isRunning
     */
    override void action() {
        (cast(MainActivity) this.container.activity).isRunning = !(cast(MainActivity) this.container.activity).isRunning;
    }

    /**
     * Draws the button with different colors depending on its state - compressed or decompressed
     */
    override void draw() {
        Texture text;
        iRectangle textLocation = new iRectangle(
            this.location.initialPoint.x + this.location.extent.x / 16, 
            this.location.initialPoint.y + this.location.extent.y / 16,
            this.location.extent.x * 7 / 8,
            this.location.extent.y * 7 / 8
        );
        if((cast(MainActivity) this.container.activity).isRunning) {
            this.container.renderer.fill(this.location, PredefinedColor.RED);
            text = new Texture((cast(MainActivity) this.container.activity).font.renderTextSolid("Stop"), this.container.renderer);
        } else {
            this.container.renderer.fill(this.location, PredefinedColor.GREEN);
            text = new Texture((cast(MainActivity) this.container.activity).font.renderTextSolid("Start"), this.container.renderer);
        }
        this.container.renderer.copy(text, textLocation);
    }
}