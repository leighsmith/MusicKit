; includes.asm - specify macro include directories
;
    maclib  '/usr/local/lib/dsp/smsrc/' 	; system macro library
    maclib  '/usr/local/lib/dsp/umsrc/' 	; utility macro library
    if AP_MON
	maclib  '/usr/local/lib/dsp/apsrc/' 	; array proc macro lib
    else
	maclib  '/usr/local/lib/dsp/ugsrc/' 	; unit-generator library
    endif

; add last line to avoid asm bug

