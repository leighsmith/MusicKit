	include 'pinequ'
PIN_IN_VOL move #>$c0c000,a ; <left><right><0> volume. c0 is unity
 	; select dp0 w/o clk, muted       
	; select dp0 w/o clk, muted
        move    #>(vDPMute|vDPCS1|vDPCS2|vDPIICCLK),y0     
	; same, with data set         
	move    #>(vDPMute|vDPCS1|vDPCS2|vDPIICCLK|vDPData),y1     
        move    y0,y:yrExtReg             ; enable dp clk low
        do      #16,CTDDone
		  ; 16 bits
          rol     a  y0,b1		  ; rotate next bit into place
          tcs     y1,b             	  ; if carry is set then data is one
          move    b1,y:yrExtReg           ; put data and selection out
          bset	  #bDPClk,b1		  ; set clk bit
          move    b1,y:yrExtReg           ; put data, selection and clk out
          move    y0,y:yrExtReg           ; put out selection only(drop clk and data)
CTDDone
	; turn off all chip selects
        bset    #bDPCS0,y0 
        move    y0,y:yrExtReg           ; turn off selectors
