#include "../musickit_c.h"
/* 6/1/95/jos - created */

void pnf(pnfVars *s){
	int i;
	word c;
	
	for (i=0; i<NTICK; i++) {
		c = (s->last_u > 0) ? s->a1 : s->a0;
		s->output[i] = c*s->input[i] + s->last_u;
		s->last_u = s->input[i] - c*s->output[i];
	}
}

