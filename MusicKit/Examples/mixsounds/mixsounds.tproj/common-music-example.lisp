(defscorefile 
  (pathname "test.score" 
   after '(mixsounds "test.score" "test.snd")  ; mixsounds must be in your path
   header  "envelope fader = [(0,0)(1,1)(2,0)];")
  (with-part MixsoundsPoly ()
	     (setf soundFile (quotify "/usr/lib/NextPrinter/printeropen.snd"))
	     (setf timeOffset (random 1.0))
	     (setf ampEnv "fader")
	     (setf rhythm (random 3.5))
	     (setf duration (+ (random 8.0) .25))
	     (setf ampEnvTimeScale 2)  ; 2 == size to fit
	     (setf freq0 'c2)
	     (setf freq1 (item (notes c4 d e g) :kill t))
	     ))
