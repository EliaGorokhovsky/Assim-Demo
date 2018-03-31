module logic.demo.EnsembleFollower;

import logic.data.Ensemble;
import logic.data.Timeseries;
import logic.data.Vector;
import logic.demo.EnsembleLeader;
import logic.demo.PointGetter;
import logic.integrators.RK4;

/** 
 * Represents an element of an ensemble
 * Returns a point from an ensemble
 * Should be used in conjuction with exactly one ensemble leader
 */
class EnsembleFollower : PointGetter {

    EnsembleLeader leader;
    int index;

    this(EnsembleLeader leader, int index) {
        this.leader = leader;
        this.index = index;
        this.points = new Timeseries!double([this.leader.ensemble.members[index].x], [this.leader.time]);
    }

    override double getPoint() {
        this.points.add(this.leader.time, this.leader.ensemble.members[this.index].x);
        return this.leader.ensemble.members[this.index].x;
    }

}