import std.algorithm;
import std.stdio;

import d2d;
import graphics.Constants;
import graphics.views.MainActivity;
import logic.assimilation.EAKF;
import logic.data.Ensemble;
import logic.demo.EnsembleLeader;
import logic.demo.EnsembleFollower;
import logic.demo.RandomPoint;
import logic.demo.LorenzPoint;
import logic.demo.PointGetter;
import logic.demo.GaussianObserver;
import logic.integrators.RK4;
import logic.systems.Lorenz63;

/*
 * Key bindings:
 * F11 (use Fn + F11) - toggle fullscreen
 * Esc - pause/unpause
 * Tab - toggle showing ensemble
 * Left/right arrows - scroll in time scale (only when paused)
 * Space - center time scale on current time (only when paused)
 * PgUp - toggle observations
 * PgDn - toggle assimilation (assimilation only happens when observations are on, regardless of whether it's on or not)
 * Grave (`) - reset program
 */
void main(){
	double dt = 0.05;
    double observationFrequency = 1;
	double startTime = 0;
	Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE,
            "Assimilation Demo");
    SDL_SetWindowFullscreen(mainDisplay.window.handle(), SDL_WINDOW_FULLSCREEN_DESKTOP);
    //Point getters
    LorenzPoint truth = new LorenzPoint(dt, startTime, 1, 1, 1);
    EnsembleLeader leader = new EnsembleLeader(new RK4(new Lorenz63()), new Ensemble([]), dt, 0);
    leader.createEnsemble(1, 1, 1, 1, 1, 1, 800);
    EnsembleFollower[] followers;
    //foreach(i; 0..leader.ensemble.size) {
    foreach(i; 0..5) {
        followers ~= new EnsembleFollower(leader, cast(int)i);
    }
    GaussianObserver observer = new GaussianObserver(0.5, 0.5, 0.5);

    mainDisplay.activity = new MainActivity(
        mainDisplay, 
        truth, leader, followers, 
        observer, new EAKF(),
        PredefinedColor.RED, PredefinedColor.BLUE, PredefinedColor.GREEN, PredefinedColor.BLACK,
        new AxisAlignedBoundingBox!(int, 2)(new iVector(logicalSize.x * 1 / 16, logicalSize.y * 1 / 16), new iVector(logicalSize.x * 3 / 4, logicalSize.y * 7 / 8)),
        new dVector(-10, 5),
        new dVector(-15, 15),
        dt, observationFrequency
    );
    mainDisplay.renderer.logicalSize = logicalSize; //logicalSize defined in graphics.Constants
    mainDisplay.eventHandlers ~= new class EventHandler {
        void handleEvent(SDL_Event event) {
            if (mainDisplay.keyboard.allKeys[SDLK_F11].testAndRelease()) {
                SDL_SetWindowFullscreen(mainDisplay.window.handle(), mainDisplay.window.info()
                        .canFind(SDL_WINDOW_FULLSCREEN_DESKTOP) ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
            }
            if (mainDisplay.keyboard.allKeys[SDLK_BACKQUOTE].testAndRelease()) {
                mainDisplay.isRunning = false;
                mainDisplay.destroy();
                main();
            }
        }
    };
    mainDisplay.run();
}
