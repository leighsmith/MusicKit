/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is used by the Music Kit to signal "no value" from functions and
    methods that return double. The value MK_NODVAL is a particular "NaN"
    ("not a number"). You cannot test its value directly.
    Instead, use MKIsNoDVal().

    Example:

         double myFunction(int arg)
         {
                 if (arg == 2)
                         return MK_NODVAL;
                 else return (double) arg * 2;
         }

         main()
         {
                 double d = myFunction(2);
                 if (MKIsNoDVal(d))
                         printf("Illegal value.\n");
         }

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project
*/
#ifndef __MK_noDVal_H___
#define __MK_noDVal_H___
  
#ifndef _MK_NANHI
#define _MK_NANHI 0x7ff80000 /* High bits of a particular non-signaling NaN */
#define _MK_NANLO 0x0        /* Low bits of a particular non-signaling NaN */
#endif

#ifndef MK_NODVAL

/*!
  @defgroup NoDValFns Test for no <b>double</b> value.
 */

/*!
  @brief Returns the special NaN that the MusicKit uses to signal "no value".

  A number of MusicKit functions and methods query for and return
  <b>double</b>-valued quantities, such as the values of parameters and
  time tags.  By convention, the value MK_NODVAL is returned if the
  queried-for value hasn't been set; however, you can't test for this
  value directly.  You must use the function <b>MKIsNoDVal()</b> instead,
  passing as the argument the value that you wish to test.  The function
  returns nonzero if <i>value</i> is equal to MK_NODVAL and 0 if it isn't.
     
  <b>MKGetNoDVal()</b> returns the no-<b>double</b>-value indicator. 
  You use this function as the return value for functions and methods of
  your own design in which you wish to indicate that a
  <b>double</b>-valued quantity hasn't been set.  For convenience,
  MK_NODVAL is defined as this function.  
  @return Returns an int.
  @see MKIsNoDVal().
  @ingroup NoDValFns
*/
inline double MKGetNoDVal(void)
{
    union {double d; int i[2];} u;
    u.i[0] = _MK_NANHI;
    u.i[1] = _MK_NANLO;
    return u.d;
}

/*!
  @brief Compares value to see if it is the special NaN that the MusicKit uses to signal "no value".

  A number of MusicKit functions and methods query for and return
  <b>double</b>-valued quantities, such as the values of parameters and
  time tags.  By convention, the value MK_NODVAL is returned if the
  queried-for value hasn't been set; however, you can't test for this
  value directly.  You must use the function <b>MKIsNoDVal()</b> instead,
  passing as the argument the value that you wish to test.  The function
  returns nonzero if <i>value</i> is equal to MK_NODVAL and 0 if it isn't.
     
  @param  value is a double.
  @return Returns an int.
  @ingroup NoDValFns
*/
inline int MKIsNoDVal(double value)
{
    union {double d; int i[2];} u;
    u.d = value;
    return (u.i[0] == _MK_NANHI); /* Don't bother to check low bits. */
}

/*!
  @brief  Special <i>double</i> value that means "invalid value."

  MusicKit methods that return a value of type <i>double</i> and want to
  signal an invalid value return MK_NODVAL, which stands for <b>N</b>o
  <b>D</b>ouble <b>VAL</b>ue.   This is not an actual valid floating point
  number.  It is a particular non-signaling "NAN" (not a number.) 
  Therefore, it can not be compared using ==.  You must use the special
  functions defined in <b>noDVal.h</b>.
 */
#define MK_NODVAL MKGetNoDVal()     /* For convenience */

#endif

#endif
