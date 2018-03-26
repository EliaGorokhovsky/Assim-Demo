module logic.demo.LorenzPoint;

import logic.data.Timeseries;
import logic.data.Vector;
import logic.demo.PointGetter;
import logic.integrators.RK4;
import logic.systems.Lorenz63;

/**
 * Gets values from a Lorenz attractor
 */
class LorenzPoint : PointGetter { 

    Vector position;
    Lorenz63 system = new Lorenz63();
    RK4 integrator;

    this(double dt, double startTime, double x, double y, double z) {
        this.dt = dt;
        this.time = startTime;
        this.position = Vector(x, y, z); 
        this.initialPosition = this.position.x;
        this.startTime = startTime;
        this.integrator = new RK4(this.system);  
        this.points = new Timeseries!double([x], [startTime]);    
    }

    override double getPoint() {
        this.time += this.dt;
        this.position = integrator.integrate(this.position, this.dt);
        this.points.add(time, this.position.x);
        return this.position.x;
    }

}