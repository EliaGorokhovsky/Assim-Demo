module logic.demo.EnsembleLeader;

import logic.data.Ensemble;
import logic.data.Timeseries;
import logic.data.Vector;
import logic.demo.PointGetter;
import logic.integrators.Integrator;
import logic.integrators.RK4;

/**
 * The "leader" of an ensemble
 * Defines an ensemble; each ensemble has a leader
 * Gets the mean of the ensemble
 * Each ensemble leader should be accompanied by ensemble followers with given indices
 */
class EnsembleLeader : PointGetter {

    Ensemble ensemble;
    double dt;

    this(Integrator integrator, Ensemble ensemble, double dt, double startTime) {
        this.integrator = integrator;
        this.ensemble = ensemble;
        this.dt = dt;
        this.time = startTime;
        this.points = new Timeseries!double([this.ensemble.eMean.x], [this.time]);  
    }

    /**
     * Creates an ensemble of given size, error, and mean
     * Necessary because my implementation of Vector conflicts with d2d's
     */
    void createEnsemble(double x, double y, double z, double xError, double yError, double zError, int size) {
        this.ensemble = new Ensemble(Vector(x, y, z), size, Vector(xError, yError, zError));
    }

    override double getPoint() {
        this.time += this.dt;
        this.ensemble = this.integrator.integrateEnsemble(this.ensemble, this.dt);
        this.points.add(this.time, this.ensemble.eMean.x);
        return this.ensemble.eMean.x;
    }

}