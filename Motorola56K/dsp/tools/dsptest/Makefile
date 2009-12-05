NAME = dsptest
include ../Makefile.c

odsptest: dsptest.c
	cc -O dsptest.c -o odsptest -ldsp_s -lsys_s

benchmarks: odsptest
	odsptest -v | & grep kBytes
