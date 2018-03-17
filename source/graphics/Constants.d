module graphics.Constants;

import std.math;
import std.traits;
import d2d;

iVector aspectRatio; //A vector representing the aspect ratio of the screen; both components should not share a common factor
iVector logicalSize; //The logical game size or resolution that this game draws and scales at

shared static this() {
    aspectRatio = new iVector(16, 9);
    logicalSize = aspectRatio * 100;
}