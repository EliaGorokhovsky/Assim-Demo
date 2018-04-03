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
 * Grave (`) - reset program (Don't do this too much! internally)
 */
void main(){
    MainActivity reset(double dt, double observationFrequency, double startTime, 
                        double startX, double startY, double startZ, 
                        double ensembleError, double observerError,
                        dVector yScale, dVector xScale, int ensembleSize, int ensembleShown,
                        Display mainDisplay) {       
        LorenzPoint truth = new LorenzPoint(dt, startTime, startX, startY, startZ);
        EnsembleLeader leader = new EnsembleLeader(new RK4(new Lorenz63()), new Ensemble([]), dt, startTime);
        leader.createEnsemble(startX, startY, startZ, ensembleError, ensembleError, ensembleError, ensembleSize);
        EnsembleFollower[] followers;
        foreach(i; 0..ensembleShown) {
            followers ~= new EnsembleFollower(leader, cast(int)i);
        }
        GaussianObserver observer = new GaussianObserver(observerError, observerError, observerError);
        return new MainActivity(
            mainDisplay, 
            truth, leader, followers, 
            observer, new EAKF(),
            PredefinedColor.RED, PredefinedColor.BLUE, PredefinedColor.GREEN, PredefinedColor.BLACK,
            new AxisAlignedBoundingBox!(int, 2)(new iVector(logicalSize.x * 1 / 16, logicalSize.y * 1 / 16), new iVector(logicalSize.x * 3 / 4, logicalSize.y * 7 / 8)),
            xScale,
            yScale,
            dt, observationFrequency
        );
    }

	double dt = 0.05;
    double observationFrequency = 1;
	double startTime = 0;
    double startX = 1;
    double startY = 1;
    double startZ = 1;
    double ensembleError = 1;
    double observerError = 0.5;
    dVector yScale = new dVector(-15, 15);
    dVector xScale = new dVector(-10, 5);
    int ensembleSize = 5;
    int ensembleShown = 5;

    Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_TARGETTEXTURE,
        "Assimilation Demo");
    mainDisplay.activity = reset(dt, observationFrequency, startTime, startX, startY, startZ, ensembleError, observerError, yScale, xScale, ensembleSize, ensembleShown, mainDisplay);
    mainDisplay.renderer.logicalSize = logicalSize; //logicalSize defined in graphics.Constants
    mainDisplay.eventHandlers ~= new class EventHandler {
        void handleEvent(SDL_Event event) {
            if (mainDisplay.keyboard.allKeys[SDLK_F11].testAndRelease()) {
                SDL_SetWindowFullscreen(mainDisplay.window.handle(), mainDisplay.window.info()
                        .canFind(SDL_WINDOW_FULLSCREEN_DESKTOP) ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
            }
            if (mainDisplay.keyboard.allKeys[SDLK_BACKQUOTE].testAndRelease()) {
                mainDisplay.activity = reset(dt, observationFrequency, startTime, startX, startY, startZ, ensembleError, observerError, yScale, xScale, ensembleSize, ensembleShown, mainDisplay);
            }
        }
    };
    mainDisplay.run();
}
