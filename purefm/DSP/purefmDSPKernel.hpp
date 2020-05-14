//
//  purefmDSPKernel.hpp
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef purefmDSPKernel_hpp
#define purefmDSPKernel_hpp

#import "DSPKernel.hpp"
#import "tables.hpp"
#import "engine.hpp"
#import "globals.hpp"
#import "status.h"

#include <algorithm>

/*
 purefmDSPKernel
 */
class purefmDSPKernel : public DSPKernel {
public:
    
    // MARK: Member Functions

    purefmDSPKernel() : _engine(&_globals) {
        _status.voice = nullptr;
        _globals.status = &_status;
    }
    virtual ~purefmDSPKernel() {}

    void init(int channelCount, double inSampleRate) {
        chanCount = channelCount;
        sampleRate = float(inSampleRate);
        _globals.t.init(inSampleRate);

        if (inSampleRate >= 176400.0) {
            _globals.eg_mask = 0x3;
        } else if (inSampleRate >= 88200.0) {
            _globals.eg_mask = 0x1;
        } else {
            _globals.eg_mask = 0x0;
        }
    }

    void setPatch(patch_ptr::pointer const &patch) {
        _globals.patch.set(patch);
        _engine.update();
    }

    struct status const *getStatus() const {
        return &_status;
    }

    void reset() {
    }

    bool isBypassed() {
        return bypassed;
    }

    void setBypass(bool shouldBypass) {
        bypassed = shouldBypass;
    }

    void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
        inBufferListPtr = inBufferList;
        outBufferListPtr = outBufferList;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        float* out = (float*)outBufferListPtr->mBuffers[0].mData;

        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            const int frameOffset = int(frameIndex + bufferOffset);

            out[frameOffset] = (float)_engine.step() / (float)0x8000000;
        }
        for (int channel = 1; channel < chanCount; ++channel) {
            float *out2 = (float *)outBufferListPtr->mBuffers[channel].mData;
            if (out2 != out) {
                std::copy_n(out+bufferOffset, frameCount, out2+bufferOffset);
            }
        }
    }

    void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        _engine.midi(midiEvent.data);
    }

    // MARK: Member Variables

private:
    int chanCount = 0;
    float sampleRate = 44100.0;
    bool bypassed = false;
    AudioBufferList* inBufferListPtr = nullptr;
    AudioBufferList* outBufferListPtr = nullptr;
    struct globals _globals;
    struct status _status;
    class engine _engine;
};

#endif /* purefmDSPKernel_hpp */
