NAME
     biquad (UG macro) - Direct-form, two-pole, two-zero, filter section

 SYNOPSIS
     biquad pf,ic,y,aout0,sinp,ainp0,s20,s10,go20,a2o20,a1o20,b2o20,b1o20

 MACRO ARGUMENTS
     pf        = global label prefix (any text unique to invoking macro)
     ic        = instance count (s.t. pf\_biquad_\ic\_ is globally unique)
     sout      = output vector memory space ('y' only)
     aout0     = initial output vector memory address
     sinp      = input vector memory space ('x' or 'y')
     ainp0     = initial input vector memory address
     s20       = initial twice-delayed state variable
     s10       = initial once-delayed state variable
     go20      = initial half-gain term (applied to biquad input signal)
     a2o20     = initial half-coefficient of twice-delayed output
     a1o20     = initial half-coefficient of once-delayed output
     b2o20     = initial half-coefficient of twice-delayed input
     b1o20     = initial half-coefficient of once-delayed input

 DSP MEMORY ARGUMENTS
     Access         Description              Initialization
     ------         -----------              --------------
     x:(R_X)+       Current output address   aout0
     x:(R_X)+       Current input address    ainp0
     x:(R_X)+       s2 state variable        s20
     x:(R_X)+       s1 state variable        s10
     y:(R_Y)+       go2  half-gain term      go20
     y:(R_Y)+       a2o2 half-coefficient    a2o20
     y:(R_Y)+       a1o2 half-coefficient    a1o20
     y:(R_Y)+       b2p2 half-coefficient    b2o20
     y:(R_Y)+       b1p2 half-coefficient    b1o20

 DESCRIPTION
     The biquad unit-generator implements a two-pole, two-zero
     filter section in direct form. All filter coefficients in
     dsp argument memory are assumed to be divided by two. The
     reason for this convention is that the a1 coefficient, for
     stable second-order resonators, varies between -2.0 and 2.0.
     The output space can only be y DSP memory.

     The section transfer function is

                            -1         -2
                1  +  b1 * z   + b2 * z
     H(z) = g * -------------------------
                            -1         -2
                1  +  a1 * z   + a2 * z

     where g=2*go2, b1=2*b1o2, b2=2*b2o2, a1=2*a1o2, and a2=2*a2o2.

     In pseudo-C notation:

     ainp = x:(R_X)+;         aout = x:(R_X)+;
     s2   = x:(R_X)+;         s1   = x:(R_X)+;
     go2  = y:(R_Y)+;
     a2o2 = y:(R_Y)+;         a1o2 = y:(R_Y)+;
     b2o2 = y:(R_Y)+;         b1o2 = y:(R_Y)+;

     for (n=0;n<I_NTICK;n++) {
          s0 = go2*sinp:ainp[n] - a1o2*s1 - a2o2*s2;
          sout:aout[n] = 2.0 * (s0 + b1o2*s1 + b2o2*s2);
          s2 = s1;
          s1 = 2.0 * s0;
     }
       
 USAGE RESTRICTIONS
     The memory space of the output signal must be y.

 REFERENCE
     "The Motorola DSP56000 Digital Signal Processor"
     Kevin L. Kloker, Motorola, Inc.
     IEEE Micro, December 1986, pp. 29-48.
     See page 45 for Kloker's biquad from which this one was written.
     See also page B-9 of the Motorola DSP56000 Digital Signal Processor
     User's Manual for the same biquad algorithm minus documentation.

 MAXIMUM EXECUTION TIME

 SOURCE
     /usr/local/lib/dsp/ugsrc/biquad.asm

 SEE ALSO
     /usr/local/lib/dsp/ugsrc/onezero.asm     - one-zero filter section
     /usr/local/lib/dsp/ugsrc/onepole.asm     - one-pole filter section
     /usr/local/lib/dsp/ugsrc/twopole.asm     - two-pole filter section
 
