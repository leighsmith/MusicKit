        page
;------------------------------------------------------------------------------
;
;       File    :       PINHARD.EQU
;
;       Project :       Pinnacle Board
;
;       Purpose :       Define DSP view of hardware.
;
;       Owner   :       Carson Zirkle
;
;------------------------------------------------------------------------------


HostExOffset    equ     $24             ; offset of the host exceptions

RamStart        equ     $04000          ; where ram begins in all cases
xRamStart       equ     $04000          ; where ram begins in x:
yRamStart       equ     $04000          ; where ram begins in y:
pRamStart       equ     $04000          ; where ram begins in p:
                                ; note - x:4000 = y:8000
                                ;        x:8000 = y:4000
                                ;        x:4000 = p:4000

RamSize         equ     $008000         ; 32k x 24 what a life!
RamMSize        equ     RamSize-1


yrPerphStart    equ     $00ffc0         ; start of the external registers


;--- write
;--- NOTE!!!: write only,  bxxx  instructions on write only registers are NO NOs!
yrSRSEL         equ     $00ffc0         ; y:$ffc0 - Sample Rate SElect latch for ADC and DAC

bSRSELICLK      equ     $0              ; bit selects input clk
vSRSELICLK24M   equ     $0              ; 0 - ICLK = 24Mhz
vSRSELICLK33M   equ     $1              ; 1 - ICLK = 33Mhz

bSRSELIDIV      equ     $1              ; bit selects input clk divide by
vSRSELIDIV3     equ     $0              ; 0 - JCLK = ICLK/3
vSRSELIDIV2     equ     (1<<bSRSELIDIV) ; 1 - JCLK = ICLK/2

bSRSELJDIV0     equ     $2              ; bit select clk divide by of output of last divider
bSRSELJDIV1     equ     $3              ; bit select clk divide by of output of last divider
vSRSELJDIV8     equ     $0                                      ; 0 - MCLK = JCLK/8
vSRSELJDIV4     equ     (1<<bSRSELJDIV0)                        ; 1 - MCLK = JCLK/4
vSRSELJDIV2     equ     (1<<bSRSELJDIV1)                        ; 2 - MCLK = JCLK/2
vSRSELJDIV0     equ     ((1<<bSRSELJDIV1)|(1<<bSRSELJDIV0))     ; 3 - MCLK = JCLK/0

vSRSELOFF       equ     $0
vSRSEL08K       equ     $1
vSRSEL16K       equ     $2
vSRSEL32K       equ     $3
vSRSEL06K       equ     $4
vSRSEL12K       equ     $5
vSRSEL24K       equ     $6
vSRSEL48K       equ     $7
vSRSEL05K       equ     $8
vSRSEL11K       equ     $9
vSRSEL22K       equ     $a
vSRSEL44K       equ     $b
;-vSRSELxxK       equ     $c            ; 8.3
vSRSEL17K       equ     $d              ; 16.5
vSRSEL33K       equ     $e
;-vSRSELxxK       equ     $f            ; 66k (too fast)


yrDACNTL        equ     $00ffc1         ; Digital Audio Control register
bDACNTLHDRREC   equ     $0              ; Controls SSI data in routing
vDACNTLADCREC   equ     $0              ; ADC data -> SSI data in
vDACNTLHDRREC   equ     (1<<bDACNTLHDRREC)      ; HDR data -> SSI data in
bDACNTLHDROUT   equ     $1              ; Controls HDR out routing
vDACNTLDSPHDR   equ     $0              ; DSP SSI out -> HDR
vDACNTLKZHDR    equ     (1<<bDACNTLHDROUT)      ; Kurtzweil out -> HDR

yrRAMWRITELOW   equ     $00ffc2         ; y:$ffc2 - enables writeing into d0-d7
bRAMWRITEen     equ     $0              ; bit 0 allows the dsp to write into the ram
                                        ; 0 = disable writing into d0-d7
                                        ; 1 = enable writing into d0-d7



yrMIDICNTL      equ     $00ffc3         ; controls MIDI routing
bMCHDROUT       equ     $0              ; controls DSP -> WaveBlaster Header out
vMCHDROFF       equ     $0              ; No MIDI data -> WaveBlaster Header out
vMCHDROUT       equ     (1<<bMCHDROUT)  ; DSP SCI out -> WaveBlaster Header out
bMCEXTOUT       equ     $1              ; controls DSP -> MIDI out (external game port)
vMCEXTOFF       equ     $0              ; No MIDI data -> MIDI out
vMCEXTOUT       equ     (1<<bMCEXTOUT)  ; DSP SCI out -> MIDI out
bMCDSPIN        equ     $2              ; DSP SCI in selector
vMCDIEXT        equ     $0              ; DSP SCI in <- MIDI in (external game port)
vMCDIHDR        equ     (1<<bMCDSPIN)   ; DSP SCI in <- WaveBlaster Header in




yrExtReg        equ     $00ffc4         ; y:$ffc4 - select external register
bDPCS0          equ     $0              ; CS for Line In volume when low volume can be clock in
bDPCS1          equ     $1              ; CS for Mic In volume when low volume can be clock in
bDPCS2          equ     $2              ; CS for AUX In volume when low volume can be clock in
bDPIICCLK       equ     $3              ; clk for Digital Audio RX/TX
bTXVer          equ     $4              ; Set this when TX DAD data is valid
bDPData         equ     $5              ; data line for the digital phers.
bDPClk          equ     $6              ; clk line for the digital phers.
bDPMute         equ     $7              ; Mute the output

vDPCS0          equ     (1<<bDPCS0)     ; values which can be used as immediates
vDPCS1          equ     (1<<bDPCS1)
vDPCS2          equ     (1<<bDPCS2)
vDPIICCLK       equ     (1<<bDPIICCLK)
vTXVer          equ     (1<<bTXVer)
vDPData         equ     (1<<bDPData)
vDPClk          equ     (1<<bDPClk)
vDPMute         equ     (1<<bDPMute)

yrExtReg1       equ     $00ffc5         ; y:$ffc5 - just an extra place to write

bDATRXVERF      equ     4
