;;; -*- Syntax: Common-Lisp; Package: COMMON-MUSIC; Base: 10; Mode: Lisp -*-

; To add a parameter, note that the parameter must appear several times.
; Use 'freq1' as an example.

(in-package "COMMON-MUSIC")
(defpart Mixsounds (synth-patch-mixin)
	 (&message amp timeOffset soundFile bearing freq0 freq1 
		   ampEnvTimeScale)
  ((patch :initform "sounds")
   (amp :initarg amp :message "amp:")
   (timeOffset :initarg timeOffset :message "timeOffset:")
   (soundFile :initarg soundFile :message "soundFile:")
   (bearing :initarg bearing :message "bearing:")
   (freq0 :initarg freq0 :message "freq0:")
   (freq1 :initarg freq1 :message "freq1:")
   (ampEnvTimeScale :initarg ampEnvTimeScale :message "ampEnvTimeScale:")
   )
  :define-event-method nil
  :define-resource nil)


(defpart MixsoundsMono (Mixsounds music-kit-mono-part) 
	 ()
  ()
  :define-event-method t)


(defpart MixsoundsPoly (Mixsounds music-kit-poly-part) 
	 ()
  ()
  :define-event-method t)


