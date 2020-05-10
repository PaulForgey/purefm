//
//  status.h
//  purefm-host
//
//  Created by Paul Forgey on 5/7/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef status_h
#define status_h

struct eg_status {
    int stage;
    int output;
};

struct voice_status {
    struct eg_status const *pitch;
    struct eg_status const *lfo;
    struct eg_status const *ops[8];
};

struct status {
    struct voice_status const *voice;
};

#endif /* status_h */
