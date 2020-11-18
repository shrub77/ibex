#include "ascon.h"
#include <stdlib.h>

// Ascon instruction macros for one round unrolled
#define ASCON_1 "ascon_p 0x04b;"
#define ASCON_6 "ascon_p 0x096; \n\t\
                 ascon_p 0x087; \n\t\
                 ascon_p 0x078; \n\t\
                 ascon_p 0x069; \n\t\
                 ascon_p 0x05a; \n\t\
                 ascon_p 0x04b; \n\t"

#define ASCON_8 "ascon_p 0x0b4; \n\t\
                 ascon_p 0x0a5; \n\t\
                 ascon_p 0x096; \n\t\
                 ascon_p 0x087; \n\t\
                 ascon_p 0x078; \n\t\
                 ascon_p 0x069; \n\t\
                 ascon_p 0x05a; \n\t\
                 ascon_p 0x04b; \n\t"

#define ASCON_12 "ascon_p 0x0f0; \n\t\
                 ascon_p 0x0e1; \n\t\
                 ascon_p 0x0d2; \n\t\
                 ascon_p 0x0c3; \n\t\
                 ascon_p 0x0b4; \n\t\
                 ascon_p 0x0a5; \n\t\
                 ascon_p 0x096; \n\t\
                 ascon_p 0x087; \n\t\
                 ascon_p 0x078; \n\t\
                 ascon_p 0x069; \n\t\
                 ascon_p 0x05a; \n\t\
                 ascon_p 0x04b; \n\t"

// initialize the state byte array
void init_state(state_t *s, int length)
{
    int i;
    for(i = 0; i < length; i++)
    {
        s->bytes[i] = 0x00;
    }
}
//copy state->bytes to byte array
void extract_bytes(const state_t *s, unsigned char *data, unsigned int offset, unsigned int length)
{
    int i;
    for(i = 0; i < length; i++)
    {
        data[i] = s->bytes[i+offset];
    }
}
// add bytes to state
void add_bytes(state_t *s, const unsigned char *data, unsigned int offset, unsigned int length)
{
    int i;
    for(i=0; i<length; i++)
    {
        s->bytes[i+offset] ^= data[i];
    }
}
// overwrite bytes in state
void overwrite_bytes(state_t *s, const unsigned char *data, unsigned int offset, unsigned int length)
{
    int i;
    for(i=0; i<length; i++)
    {
        s->bytes[i+offset] = data[i];
    }
}


void ascon_p1(state_t* s)
{
    // register constraints
    register unsigned long a2 asm ("a2") = s->x0_0;
    register unsigned long a3 asm ("a3") = s->x0_1;
    register unsigned long a4 asm ("a4") = s->x1_0;
    register unsigned long a5 asm ("a5") = s->x1_1;
    register unsigned long a6 asm ("a6") = s->x2_0;
    register unsigned long a7 asm ("a7") = s->x2_1;
    register unsigned long t3 asm ("t3") = s->x3_0;
    register unsigned long t4 asm ("t4") = s->x3_1;
    register unsigned long t5 asm ("t5") = s->x4_0;
    register unsigned long t6 asm ("t6") = s->x4_1;

    // preform ASCON permutation(s)
    asm(ASCON_1
        : "+r" (a2), "+r" (a3), "+r" (a4), "+r" (a5), "+r" (a6), "+r" (a7), "+r" (t3), "+r" (t4), "+r" (t5), "+r" (t6));
        
    // unpack registers back into the state
    s->x0_0 = a2;
    s->x0_1 = a3;

    s->x1_0 = a4;
    s->x1_1 = a5;

    s->x2_0 = a6;
    s->x2_1 = a7;

    s->x3_0 = t3;
    s->x3_1 = t4;

    s->x4_0 = t5;
    s->x4_1 = t6;
}


void ascon_p6(state_t* s)
{
    // register constraints
    register unsigned long a2 asm ("a2") = s->x0_0;
    register unsigned long a3 asm ("a3") = s->x0_1;
    register unsigned long a4 asm ("a4") = s->x1_0;
    register unsigned long a5 asm ("a5") = s->x1_1;
    register unsigned long a6 asm ("a6") = s->x2_0;
    register unsigned long a7 asm ("a7") = s->x2_1;
    register unsigned long t3 asm ("t3") = s->x3_0;
    register unsigned long t4 asm ("t4") = s->x3_1;
    register unsigned long t5 asm ("t5") = s->x4_0;
    register unsigned long t6 asm ("t6") = s->x4_1;

    // preform ASCON permutation(s)
    asm(ASCON_6
        : "+r" (a2), "+r" (a3), "+r" (a4), "+r" (a5), "+r" (a6), "+r" (a7), "+r" (t3), "+r" (t4), "+r" (t5), "+r" (t6));
        
    // unpack registers back into the state
    s->x0_0 = a2;
    s->x0_1 = a3;

    s->x1_0 = a4;
    s->x1_1 = a5;

    s->x2_0 = a6;
    s->x2_1 = a7;

    s->x3_0 = t3;
    s->x3_1 = t4;

    s->x4_0 = t5;
    s->x4_1 = t6;
}

void ascon_p8(state_t* s)
{
    // register constraints
    register unsigned long a2 asm ("a2") = s->x0_0;
    register unsigned long a3 asm ("a3") = s->x0_1;
    register unsigned long a4 asm ("a4") = s->x1_0;
    register unsigned long a5 asm ("a5") = s->x1_1;
    register unsigned long a6 asm ("a6") = s->x2_0;
    register unsigned long a7 asm ("a7") = s->x2_1;
    register unsigned long t3 asm ("t3") = s->x3_0;
    register unsigned long t4 asm ("t4") = s->x3_1;
    register unsigned long t5 asm ("t5") = s->x4_0;
    register unsigned long t6 asm ("t6") = s->x4_1;

    // preform ASCON permutation(s)
    asm(ASCON_8
        : "+r" (a2), "+r" (a3), "+r" (a4), "+r" (a5), "+r" (a6), "+r" (a7), "+r" (t3), "+r" (t4), "+r" (t5), "+r" (t6));
        
    // unpack registers back into the state
    s->x0_0 = a2;
    s->x0_1 = a3;

    s->x1_0 = a4;
    s->x1_1 = a5;

    s->x2_0 = a6;
    s->x2_1 = a7;

    s->x3_0 = t3;
    s->x3_1 = t4;

    s->x4_0 = t5;
    s->x4_1 = t6;
}

void ascon_p12(state_t* s)
{
    // register constraints
    register unsigned long a2 asm ("a2") = s->x0_0;
    register unsigned long a3 asm ("a3") = s->x0_1;
    register unsigned long a4 asm ("a4") = s->x1_0;
    register unsigned long a5 asm ("a5") = s->x1_1;
    register unsigned long a6 asm ("a6") = s->x2_0;
    register unsigned long a7 asm ("a7") = s->x2_1;
    register unsigned long t3 asm ("t3") = s->x3_0;
    register unsigned long t4 asm ("t4") = s->x3_1;
    register unsigned long t5 asm ("t5") = s->x4_0;
    register unsigned long t6 asm ("t6") = s->x4_1;

    // preform ASCON permutation(s)
    asm(ASCON_12
        : "+r" (a2), "+r" (a3), "+r" (a4), "+r" (a5), "+r" (a6), "+r" (a7), "+r" (t3), "+r" (t4), "+r" (t5), "+r" (t6));
        
    // unpack registers back into the state
    s->x0_0 = a2;
    s->x0_1 = a3;

    s->x1_0 = a4;
    s->x1_1 = a5;

    s->x2_0 = a6;
    s->x2_1 = a7;

    s->x3_0 = t3;
    s->x3_1 = t4;

    s->x4_0 = t5;
    s->x4_1 = t6;
}