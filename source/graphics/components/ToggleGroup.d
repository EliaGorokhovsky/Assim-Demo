module graphics.components.ToggleGroup;

import d2d;
import graphics.components.ConditionalText;
import graphics.components.ToggleButton;
import graphics.components.Label;
import graphics.views.MainActivity;

class ToggleGroup : ComponentGroup {

    this(Display container, iRectangle buttonLocation, iRectangle stateLocation, iRectangle nameLocation, bool* param, string name) {
        super(container, []);
        this.subComponents ~= new ToggleButton(this.container, buttonLocation, param);
        this.subComponents ~= new ConditionalText(this.container, stateLocation, param, "On", "Off");
        this.subComponents ~= new Label(this.container, nameLocation, name);
    }

}