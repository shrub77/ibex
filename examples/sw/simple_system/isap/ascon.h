#ifndef ASCON_H_
#define ASCON_H_

// ASCON calls with round constants

#define NUM_BYTES 40
#define NUM_WORDS 10
typedef union
{
    struct {
        unsigned long x0_0, x0_1, x1_0, x1_1, x2_0, x2_1, x3_0, x3_1, x4_0, x4_1;
    };
    unsigned long words[NUM_WORDS];
    unsigned char bytes[NUM_BYTES];
} state_t;
void init_state(state_t *s, int length);

// Add data bytes to state
void add_bytes(state_t *s, const unsigned char *data, unsigned int offset, unsigned int length);

// Overwrite bytes to state
void overwrite_bytes(state_t *s, const unsigned char *data, unsigned int offset, unsigned int length);

void extract_bytes(const state_t *s, unsigned char *data, unsigned int offset, unsigned int length);

void ascon_p1(state_t* s);
void ascon_p6(state_t* s);
void ascon_p8(state_t* s);
void ascon_p12(state_t* s);



#endif