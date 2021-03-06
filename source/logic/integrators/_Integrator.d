module logic.integrators.Integrator;

import logic.data.Ensemble;
import logic.data.Vector;
import logic.systems.System;

/**
 * An overarching definition of what makes an integrator
 * Each integrator needs to be able to return a state from a state and a slope
 */
abstract class Integrator {

    System slope;   ///Should store a function to return slope from position

    Vector opCall(Vector state, double dt) {
        return this.integrate(state, dt);
    }

    Ensemble opCall(Ensemble ensemble, double dt) {
        return this.integrateEnsemble(ensemble, dt);
    }

    Vector integrate(Vector state, double dt);
    Ensemble integrateEnsemble(Ensemble ensemble, double dt);
    Vector integrateTo(Vector state, double timeDifference, uint steps);

}