#ifndef __MK_DramEchos_H___
#define __MK_DramEchos_H___
/* This is a simple DRAM echo generator.  You create it by calling 
 * allocateDramEchos()
 *
 * Then, you can dynamically change the delay and scale with the 
 * set functions declared below.
 *
 */

void allocateDramEchos(id qp,double initialEchoAmp);
extern void setDramEchoDelay(int delayLength);
extern void setDramEchoScale(double val);


#endif
