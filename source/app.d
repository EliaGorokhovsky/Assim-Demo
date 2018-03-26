import std.algorithm;
import std.stdio;

import d2d;
import graphics.Constants;
import graphics.views.MainActivity;
import logic.demo.RandomPoint;
import logic.demo.LorenzPoint;

void main(){
	Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE,
            "Assimilation Demo");
    mainDisplay.activity = new MainActivity(
		mainDisplay, 
		[new LorenzPoint(0.05, 0, 1, 1, 1), new LorenzPoint(0.05, 0, 1.01, 1.01, 1.01), new LorenzPoint(0.05, 0, 0.99, 0.99, 0.99)], 
		//new RandomPoint(new dVector(-20, 20), 0.01, 0),
		new AxisAlignedBoundingBox!(int, 2)(new iVector(0, 0), new iVector(logicalSize.x * 3 / 4, logicalSize.y)),
		new dVector(-10, 5),
		new dVector(-17, 17)
	);
    mainDisplay.renderer.logicalSize = logicalSize; //logicalSize defined in graphics.Constants
    mainDisplay.eventHandlers ~= new class EventHandler {
        void handleEvent(SDL_Event event) {
            if (mainDisplay.keyboard.allKeys[SDLK_F11].testAndRelease()) {
                SDL_SetWindowFullscreen(mainDisplay.window.handle(), mainDisplay.window.info()
                        .canFind(SDL_WINDOW_FULLSCREEN_DESKTOP) ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
            }
        }
    };
    mainDisplay.run();
}
