//
//  status.h
//  purefm-host
//
//  Created by Paul Forgey on 5/7/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef status_h
#define status_h

struct op_status {
    int stage;
    int output;
};

struct voice_status {
    int pitch_stage;
    int lfo_stage;
    int lfo_output;
    struct op_status const *ops[8];
};

struct status {
    struct voice_status const *voice;
};

#endif /* status_h */
