NAME
     constant (UG macro) - generate a constant signal

 SYNOPSIS
     constant pf,ic,sout,aout0,cnst0

 MACRO ARGUMENTS
     pf        = global label prefix (any text unique to invoking macro)
     ic        = instance count (s.t. pf\_constant_\ic\_ is globally unique)
     sout      = output vector memory space ('x' or 'y')
     aout0     = initial output vector memory address
     cnst0     = initial constant value

 DSP MEMORY ARGUMENTS
     Access         Description              Initialization
     ------         -----------              --------------
     x:(R_X)+       Current output address   aout0
     y:(R_Y)+       Current constant value   cnst0

 DESCRIPTION
     The constant unit-generator write a constant into a signal vector.
     In pseudo-C notation:

     aout = x:(R_X)+;
     cnst = y:(R_Y)+;
     for (n=0;n<I_NTICK;n++) sout:aout[n] = cnst;
       
 MAXIMUM EXECUTION TIME
     42 DSP clock cycles for one "tick" which equals 16 audio samples.

 SOURCE
     /usr/local/lib/dsp/ugsrc/constant.asm

