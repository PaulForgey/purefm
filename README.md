# pureFM software synthesizer
* 8 operators
* 16 note polyphonic
* 16 bit sine wave resolution (16384 samples per quandrant)
* 4096 pitch units per octave
* 16 octave range

## Build any algorithm
* All 8 operators may be dragged into almost any arrangement
* Arbitrary feedback path

## Envelopes
* Arbitrary number of stages
* Looping
* Selectable key-up point
* Each stage may be linear, exponential, or immediate value with delay

## LFO
* LFO has same envelope flexibility as the operators
* Sine, triangle, square, saw up, saw down, noise

## Mono mode
* Mono mode with portamento
* Each MIDI channel has its own voice
* Each voice keeps track of highest key down and stays triggered

### Source code README:

The "purefm-host" application is the container for the "pureme" app extension. After running
the host application, the extension should be available to use as a plug-in in Garage Band,
Logic, etc, under the vendor name "Shoes In One Hour" and plug-in name "pureFM".

The host application is a minimal test harness which loads the plugin, allows presets to be
saved or loaded, and sends down MIDI data from any inputs present on the system.

The sections of the plug-in are:

* Audio Unit

This is the `AUAudioUnit` implementation. It glues the kernel to the model classes which
provide the patch data.

* Model

These classes own the patch data used by the kernel and provide a KVO bridge to the UI.
The root object is an instance of `State`, which is serialized for the preset data. The audio
unit may replace this instance when de-serializing another copy as part of `setFullState:`,
which is effectively loading a preset.

There is also a mechanism to allow running state data to be published back to the model.
The model classes present this data back to the application via read only attributes.

This section has its own README file explaining memory ownership model which allows
the kernel to see changes atomically and safefly use a weak reference without ever needing
to reach in to the runtime library to delete instances or be left holding a last reference.

 * DSP

 This is the implementation of the synth engine, written in portable c++17. The engine could
 be cleanly ported to other platforms or plug-in mechanisms from this level. The Audio Unit
 section instantiates this along with its instance globals and state data, and plumbs the patch
 infromation from the model.
 
 * UI

 The `AudioUnitViewController` presenting the UI. It can see the patch information in the
 model classes via standard bindings through the `state` attribute.
 
