/* Princeton version 1.1, 10/89 */
/*****************************************************************************/
/*                                                                           */
/* Fast Fourier Transform                                                    */
/* Network Abstraction, Definitions                                          */
/* Kevin Peterson, MIT Media Lab, EMS                                        */
/* UROP - Fall '86                                                           */
/* REV: 6/12/87(KHP) - To incorporate link list of different sized networks  */
/*                                                                           */
/*****************************************************************************/

/* Overview:
	
   My realization of the FFT involves a representation of a network of
   "butterfly" elements that takes a set of 'N' sound samples as input and
   computes the discrete Fourier transform.  This network consists of a 
   series of stages (log2 N), each stage consisting of N/2 parallel butterfly
   elements.  Consecutive stages are connected by specific, predetermined flow 
   paths, (see Oppenheim, Schafer for details) and each butterfly element has
   an associated multiplicative coefficient.

   FFT NETWORK:
   -----------	
      ____    _    ____    _    ____    _    ____    _    ____
  o--|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |--o
     |reg1|  | |  |W^r1|  | |  |reg1|  | |  |W^r1|  | |  |reg1|
     |    |  | |  |    |  | |  |    |  | |  |    |  | |  |    | .....
     |    |  | |  |    |  | |  |    |  | |  |    |  | |  |    |  
  o--|____|o-| |-o|____|o-| |-o|____|o-| |-o|____|o-| |-o|____|--o
             | |          | |          | |          | |
             | |          | |          | |          | |
      ____   | |   ____   | |   ____   | |   ____   | |   ____ 
  o--|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |--o
     |reg2|  | |  |W^r2|  | |  |reg2|  | |  |W^r2|  | |  |reg2|
     |    |  | |  |    |  | |  |    |  | |  |    |  | |  |    | .....
     |    |  | |  |    |  | |  |    |  | |  |    |  | |  |    |
  o--|____|o-| |-o|____|o-| |-o|____|o-| |-o|____|o-| |-o|____|--o
             | |          | |          | |          | |
             | |          | |          | |          | |
       :      :     :      :     :      :     :      :     :
       :      :     :      :     :      :     :      :     :
       :      :     :      :     :      :     :      :     :
       :      :     :      :     :      :     :      :     :
       :      :     :      :     :      :     :      :     :

      ____   | |   ____   | |   ____   | |   ____   | |   ____ 
  o--|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |o-| |-o|    |--o
     |reg |  | |  |W^r |  | |  |reg |  | |  |W^r |  | |  |reg |
     | N/2|  | |  | N/2|  | |  | N/2|  | |  | N/2|  | |  | N/2| .....
     |    |  | |  |    |  | |  |    |  | |  |    |  | |  |    |
  o--|____|o-|_|-o|____|o-|_|-o|____|o-|_|-o|____|o-|_|-o|____|--o

              ^            ^            ^            ^
    Initial   |  Bttrfly   |   Rd/Wrt   |   Bttrfly  |   Rd/Wrt
    Buffer    |            |  Register  |            |  Register
              |____________|____________|____________|
                                 |
                                 |
                            Interconnect
			       Paths

   The use of "in-place" computation permits one to use only one set of 
   registers realized by an array of complex number structures.  To describe
   the coefficients for each butterfly I am using a two dimensional array
   (stage, butterfly) of complex numbers.  The predetermined stage connections
   will be described in a two dimensional array of indicies.  These indicies 
   will be used to determine the order of reading at each stage of the    
   computation.  
*/

/* some basic definitions */
#define        SHORT_SIZE              sizeof(short)
#define        INT_SIZE                sizeof(int)
#define        FLOAT_SIZE              sizeof(float)
#define        DOUBLE_SIZE             sizeof(double)
#define        PNTR_SIZE               sizeof(char *)

#define        PI                      3.1415927
#define        TWO_PI                  6.2831854

/* type definitions for I/O buffers */
#define        REAL                    0          /* real only          */
#define        IMAG                    2          /* imaginary only     */
#define        RECT                    8          /* real and imaginary */
#define        MAG                     16         /* magnitude only     */
#define        PHASE                   32         /* phase only         */
#define        POLAR                   64         /* magnitude and phase*/

/* scale definitions for I/O buffers */
#define        LINEAR                  0
#define        DB                      1          /* 20log10            */

/* transform direction definition */
#define        FORWARD                 1          /* Forward FFT        */
#define        INVERSE                 2          /* Inverse FFT        */

/* window type definitions */
#define        HANNING                 1
#define        RECTANGULAR             0



/* network structure definition */

typedef struct Tfft_net {
	                int             n;
			int             stages;
			int             bps;
			int		wtype;
			int             scale;
			int             direction;
			int             *load_index;
			double          *window, *inv_window;
                        double          *regr;
		        double          *regi;
			double          **indexpr;
			double          **indexpi;
		        double          **indexqr;
		        double          **indexqi;
                        double          *coeffr, *inv_coeffr;
                        double          *coeffi, *inv_coeffi;
			struct Tfft_net *next;  
	       }        FFT_NET;

#define dBMASK 0x01
#define GRAYSCALEMASK 0x02
