import std.algorithm;
import std.stdio;

import d2d;
import graphics.Constants;
import graphics.views.MainActivity;
import logic.data.Ensemble;
import logic.demo.EnsembleLeader;
import logic.demo.EnsembleFollower;
import logic.demo.RandomPoint;
import logic.demo.LorenzPoint;
import logic.demo.PointGetter;
import logic.integrators.RK4;
import logic.systems.Lorenz63;

void main(){
	double dt = 0.05;
	double startTime = 0;
	Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE,
            "Assimilation Demo");
    //Point getters
    Color[] colors = [];
    LorenzPoint truth = new LorenzPoint(dt, startTime, 1, 1, 1);
    colors ~= PredefinedColor.RED;
    EnsembleLeader leader = new EnsembleLeader(new RK4(new Lorenz63()), new Ensemble([1.01, 1, 0.99], [1.01, 1.01, 0.99], [1.01, 1, 0.99]), dt, 0);
    colors ~= PredefinedColor.BLUE;
    PointGetter[] followers;
    /*foreach(i; 0..leader.ensemble.size) {
        followers ~= new EnsembleFollower(leader, cast(int)i);
        colors ~= PredefinedColor.GREEN;
    }*/

    mainDisplay.activity = new MainActivity(
        mainDisplay, 
        truth, leader, [],
        PredefinedColor.RED, PredefinedColor.BLUE, PredefinedColor.GREEN,
        new AxisAlignedBoundingBox!(int, 2)(new iVector(logicalSize.x * 1 / 16, logicalSize.y * 1 / 16), new iVector(logicalSize.x * 3 / 4, logicalSize.y * 7 / 8)),
        new dVector(-20, 10),
        new dVector(-15, 15),
        dt
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
