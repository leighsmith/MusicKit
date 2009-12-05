; ================================================================
  if QP_SAT
start_hub_write_data	      	; set up sound output to ssi port.
    bset  #B__IPS_ENABLE,y:Y_DEVSTAT ; enable hub write data
    jsr setup_wd_ptrs           ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
    rts
  endif
; ================================================================
  if QP_HUB
start_sat_read_data	      	
    bset  #B__IPS_ENABLE,y:Y_DEVSTAT 
    jsr setup_hub_rd_ptrs       ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
    rts
  endif
; ================================================================
  if QP_SAT
stop_hub_write_data	 ; cease sound output to hub.
	  bclr #B__IPS_ENABLE,y:Y_DEVSTAT     ; disable hub out service
	  bclr #B__IPS_RUNNING,y:Y_DEVSTAT    ; indicate need for ptr reset
          bclr #3,x:$FFFF                     ; disable irqb (level-sensitive)
	  rts
  endif
; ================================================================
  if QP_HUB
stop_sat_read_data	      	
    bclr  #B__IPS_ENABLE,y:Y_DEVSTAT 
    rts
  endif
