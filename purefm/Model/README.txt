These model classes bridge the user interface, preset state, and engine state.

We want to avoid runtime calls and garbage collection in the audio render
thread, which means the patch information needs to be safely available without
taking locks or potentially being left with the last reference to free, but
model classes may be created, modified, or deallocated at any time.

The authoritative source of the data is contained in the engine's structs
declared in DSP/globals.hpp.

The instances, however, are actually owned by the model classes and wrapped in
shared_ptr types.

Think of ptr_msg<T> as a single element queue, with the model being the
producer side and the engine the consumer. These are owned by the engine.

When a voice starts playing via a key down event, it refereshes the current
patch information via a ptr_msg<T>. The engine side gets a pointer to the
current patch via get(), and this pointer is guaranteed valid until a
subsequent call to get() again, which returns a potentially new pointer.
(In the common case where nothing has changed, this call is very cheap.)

The model side of this mechanism updates its shared_ptr<T> to the ptr_msg<T>
via set(). Subsequent calls to set() will release the shared pointers in
the prior calls, perhaps immediately if get() was never called to claim it,
otherwise in a later call to set() once the engine is done with it, or,
ultimately, when the ptr_msg instance goes away with the engine when unloaded.

So a model class will create and own a shared_ptr<T>, which when created
or changed will update the engine via ptr_msg<T>::set().

Envelope.mm probably has the most complex example of how this comes together.

Simple scaler parameters are accessed without any sort of locking as data
races are unimportant with them. If a set of values would need to change as an
atomic group, they should be put in their own struct and updated via the
pointer mechanism.
