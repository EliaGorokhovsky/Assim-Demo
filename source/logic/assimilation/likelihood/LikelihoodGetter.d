module logic.assimilation.likelihood.LikelihoodGetter;

import std.algorithm;
import std.math;
import logic.assimilation.likelihood.Likelihood;
import logic.data.Ensemble;
import logic.data.Timeseries;
import logic.data.Vector;

/**
 * Gets the likelihood for assimilation given information about the system
 */
class LikelihoodGetter {

    Timeseries!Vector observations;
    Vector stateError;

    this(Timeseries!Vector observations, Vector stateError) {
        this.observations = observations;
        this.stateError = stateError;
    }

    /**
     * Returns likelihood packaged with mean and deviation for a given time
     */
    Likelihood opCall(double time) {
        assert(this.observations.times.any!(a => a.approxEqual(time, 1e-6, 1e-6)), "Time not in list");
        return new Likelihood(this.observations.value(time), this.stateError);
    }

    /**
     * Returns likelihood given ensembles
     */
    Likelihood opCall(double time, Timeseries!Ensemble ensembles) {
        return null;
    }

}
