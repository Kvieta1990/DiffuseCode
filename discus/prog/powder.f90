MODULE powder
!
USE errlist_mod 
!
IMPLICIT NONE
!
PUBLIC
!
CONTAINS
!+                                                                      
!     Calculation of powder diffraction pattern.                        
!                                                                       
!*****7*****************************************************************
      SUBROUTINE do_powder 
!-                                                                      
!     Main menu for powder diffraction pattern                          
!+                                                                      
      USE discus_config_mod 
      USE diffuse_mod 
      USE crystal_mod 
      USE diffuse_mod 
      USE fourier_sup
      USE powder_mod 
      USE discus_show_menu
!
      USE calc_expr_mod
      USE doact_mod 
      USE do_eval_mod
      USE do_wait_mod
      USE get_params_mod
      USE learn_mod 
      USE class_macro_internal
      USE prompt_mod 
      USE sup_mod
!                                                                       
      IMPLICIT none 
!                                                                       
      CHARACTER(5) befehl 
      CHARACTER(LEN=LEN(prompt)) :: orig_prompt
      CHARACTER(1024) line, zeile
      INTEGER lp, length, lbef 
      INTEGER indxg
      LOGICAL lend
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
      lend = .false. 
      CALL no_error 
      orig_prompt = prompt
      prompt = prompt (1:len_str (prompt) ) //'/powd' 
!                                                                       
main: DO while (.not.lend) 
      CALL get_cmd (line, length, befehl, lbef, zeile, lp, prompt) 
      IF (ier_num.eq.0) then 
         IF (line /= ' '      .and. line(1:1) /= '#' .and. &
             line /= char(13) .and. line(1:1) /= '!'        ) THEN
!                                                                       
!     ----search for "="                                                
!                                                                       
indxg = index (line, '=') 
IF (indxg.ne.0.AND..NOT. (str_comp (befehl, 'echo', 2, lbef, 4) ) &
              .AND..NOT. (str_comp (befehl, 'syst', 2, lbef, 4) )    &
              .AND..NOT. (str_comp (befehl, 'help', 2, lbef, 4) .OR. &
                          str_comp (befehl, '?   ', 2, lbef, 4) )    &
              .AND. INDEX(line,'==') == 0                            ) THEN
!                                                                       
!     ------evaluatean expression and assign the value to a variabble   
!                                                                       
               CALL do_math (line, indxg, length) 
            ELSE 
!                                                                       
!------ ----execute a macro file                                        
!                                                                       
               IF (befehl (1:1) .eq.'@') then 
                  IF (length.ge.2) then 
                     CALL file_kdo (line (2:length), length - 1) 
                  ELSE 
                     ier_num = - 13 
                     ier_typ = ER_MAC 
                  ENDIF 
!                                                                       
!     ----list asymmetric unit 'asym'                                   
!                                                                       
               ELSEIF (str_comp (befehl, 'asym', 2, lbef, 4) ) then 
                  CALL show_asym 
!                                                                       
!     ----continues a macro 'continue'                                  
!                                                                       
               ELSEIF (str_comp (befehl, 'continue', 2, lbef, 8) ) then 
                  CALL macro_continue (zeile, lp) 
!                                                                       
!     ----list atoms present in the crystal 'chem'                      
!                                                                       
               ELSEIF (str_comp (befehl, 'chem', 2, lbef, 4) ) then 
                  CALL show_chem 
!                                                                       
!------ ----Echo a string, just for interactive check in a macro 'echo' 
!                                                                       
               ELSEIF (str_comp (befehl, 'echo', 2, lbef, 4) ) then 
                  CALL echo (zeile, lp) 
!                                                                       
!      ---Evaluate an expression, just for interactive check 'eval'     
!                                                                       
               ELSEIF (str_comp (befehl, 'eval', 2, lbef, 4) ) then 
                  CALL do_eval (zeile, lp) 
!                                                                       
!     ----exit 'exit'                                                   
!                                                                       
               ELSEIF (str_comp (befehl, 'exit', 2, lbef, 4) ) then 
                  lend = .true. 
!                                                                       
!     ----help 'help','?'                                               
!                                                                       
      ELSEIF (str_comp (befehl, 'help', 2, lbef, 4) .or.str_comp (befehl&
     &, '?   ', 1, lbef, 4) ) then                                      
                  IF (str_comp (zeile, 'errors', 2, lp, 6) ) then 
                     lp = lp + 7 
                     CALL do_hel ('discus '//zeile, lp) 
                  ELSE 
                     lp = lp + 12 
                     CALL do_hel ('discus powd '//zeile, lp) 
                  ENDIF 
!                                                                       
!     switch to electrons diffraction 'electron'                                
!                                                                       
               ELSEIF (str_comp (befehl, 'electron', 1, lbef, 8) ) then 
                  lxray = .true. 
                  diff_radiation = RAD_ELEC
!                                                                       
!     switch to neutron diffraction 'neut'                              
!                                                                       
               ELSEIF (str_comp (befehl, 'neut', 1, lbef, 4) ) then 
                  lxray = .false. 
                  diff_radiation = RAD_NEUT
!                                                                       
!     ----run transformation 'run'                                      
!                                                                       
               ELSEIF (str_comp (befehl, 'run ', 1, lbef, 4) ) then 
                  CALL dlink (ano, lambda, rlambda, renergy, l_energy, &
                              diff_radiation, diff_power) 
                  IF (ier_num.eq.0) then 
                     CALL powder_run 
                     IF(ier_num == 0) THEN
                        four_was_run = .true.
                        IF (pow_four_type.eq.POW_HIST) THEN 
                           four_last = POWD_DY
                        ELSE
                           four_last = POWD_CO
                        ENDIF 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----show current parameters 'show'                                
!                                                                       
               ELSEIF (str_comp (befehl, 'show', 2, lbef, 4) ) then 
                  CALL dlink (ano, lambda, rlambda, renergy, l_energy, &
                              diff_radiation, diff_power) 
                  CALL pow_show 
!                                                                       
!------- -Set values 'set'                                              
!                                                                       
               ELSEIF (str_comp (befehl, 'set', 2, lbef, 3) ) then 
                  CALL do_pow_set (zeile, lp) 
!                                                                       
!------- -Operating System Kommandos 'syst'                             
!                                                                       
               ELSEIF (str_comp (befehl, 'syst', 2, lbef, 4) ) then 
                  IF (zeile.ne.' ') then 
                     CALL do_operating (zeile (1:lp), lp) 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!------  -----waiting for user input                                    
!                                                                       
               ELSEIF (str_comp (befehl, 'wait', 3, lbef, 4) ) then 
                  CALL do_input (zeile, lp) 
!                                                                       
!     switch to x-ray diffraction 'xray'                                
!                                                                       
               ELSEIF (str_comp (befehl, 'xray', 1, lbef, 4) ) then 
                  lxray = .true. 
                  diff_radiation = RAD_XRAY
!                                                                       
!     ------unknown command                                             
!                                                                       
               ELSE 
                  ier_num = - 8 
                  ier_typ = ER_COMM 
               ENDIF 
            ENDIF 
         ENDIF 
      ENDIF 
      IF (ier_num.ne.0) THEN 
         CALL errlist 
         IF (ier_sta.ne.ER_S_LIVE) THEN 
            IF (lmakro .OR. lmakro_error) THEN  ! Error within macro or termination errror
               IF(sprompt /= prompt ) THEN
                  ier_num = -10
                  ier_typ = ER_COMM
                  ier_msg(1) = ' Error occured in powder menu'
                  prompt_status = PROMPT_ON 
                  prompt = orig_prompt
                  RETURN
               ELSE
                  IF(lmacro_close) THEN
                     CALL macro_close 
                     prompt_status = PROMPT_ON 
                  ENDIF 
               ENDIF 
            ENDIF 
            IF (lblock) THEN 
               ier_num = - 11 
               ier_typ = ER_COMM 
               prompt_status = PROMPT_ON 
               prompt = orig_prompt
               RETURN 
            ENDIF 
            CALL no_error 
            lmakro_error = .FALSE.
            sprompt = ' '
         ENDIF 
      ENDIF 
         IF(linteractive .OR. lmakro) THEN
               CYCLE main
         ELSE
               EXIT main
         ENDIF 
      ENDDO  main
!
      prompt = orig_prompt
!                                                                       
      END SUBROUTINE do_powder                      
!*****7*****************************************************************
      SUBROUTINE pow_show 
!-                                                                      
!     Prints summary of powder diffraction settings                     
!+                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE diffuse_mod 
      USE metric_mod
      USE powder_mod 
      USE trig_degree_mod
      USE wink_mod
!
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      CHARACTER(8) radiation 
      CHARACTER (LEN=8), DIMENSION(3), PARAMETER :: c_rad = (/ &
         'X-ray   ', 'neutron ', 'electron' /)
      CHARACTER(14) cfour (0:1) 
      CHARACTER(28) ccalc (0:5) 
      CHARACTER(21) cpref (1:2) 
      CHARACTER(29) cprofile (0:2) 
!                                                                       
      REAL hkl (3), h1, h2, dstar, ttheta 
      REAL del_tth_min (3) 
      REAL del_tth_max (3) 
!                                                                       
!     REAL skalpro 
!     REAL asind 
!     REAL sind 
!                                                                       
      DATA cfour / 'normal Fourier', 'Stacking fault' / 
      DATA ccalc / 'rez. space integration      ', 'Debye formula       &
     &        ', 'Debye formula long          ', 'Debye formula fast    &
     &      ', 'Debye formula via histogram ', 'new integration       ' &
     &/                                                                 
      DATA cpref / 'Rietveld Toraya model', 'Modified March model ' / 
      DATA cprofile / 'Profile function switched off', 'Gaussian        &
     &             ', 'Pseudo-Voigt                 ' /                 
!                                                                       
      WRITE (output_io, 1000) 
!                                                                       
!     radiation = 'neutron' 
!     IF (lxray) radiation = 'x-ray' 
      radiation = c_rad(diff_radiation)
      IF (lambda.eq.' ') then 
         IF(diff_radiation==2) THEN
            WRITE (output_io, 1201) radiation, rlambda , renergy
         ELSE 
            WRITE (output_io, 1200) radiation, rlambda , renergy
         ENDIF 
      ELSE 
         WRITE (output_io, 1210) radiation, lambda, rlambda 
      ENDIF 
!                                                                       
      IF (pow_axis.eq.POW_AXIS_DSTAR) then 
         WRITE (output_io, 1211) 'dstar=2 sin(Theta)/lambda' 
      ELSEIF (pow_axis.eq.POW_AXIS_TTH) then 
         WRITE (output_io, 1211) '2-Theta' 
      ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
         WRITE (output_io, 1211) 'Q=4pi sin(Theta)/lambda' 
      ELSE 
         WRITE (output_io, 1211) 'Has not been defined!' 
      ENDIF 
      IF (pow_axis.eq.POW_AXIS_DSTAR.or.pow_axis.eq.POW_AXIS_TTH) then 
         IF (rlambda.ne.0.0) then 
            pow_ds_max = 2. * sind (pow_tthmax * 0.5) / rlambda 
            pow_ds_min = 2. * sind (pow_tthmin * 0.5) / rlambda 
         ENDIF 
         WRITE (output_io, 1220) pow_tthmin, pow_tthmax 
         WRITE (output_io, 1221) pow_ds_min, pow_ds_max 
         WRITE (output_io, 1230) pow_deltatth 
         WRITE (output_io, 1240) pow_hkl_del 
!                                                                       
         hkl (1) = 1.0 
         hkl (2) = 0.0 
         hkl (3) = 0.0 
         h1 = pow_ds_min / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 + pow_hkl_del (1) 
         hkl (1) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_min (1) = abs (ttheta - pow_tthmin) 
         hkl (1) = 1.0 
         hkl (2) = 0.0 
         hkl (3) = 0.0 
         h1 = pow_ds_max / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 - pow_hkl_del (1) 
         hkl (1) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_max (1) = abs (ttheta - pow_tthmax) 
!                                                                       
         hkl (2) = 1.0 
         hkl (1) = 0.0 
         hkl (3) = 0.0 
         h1 = pow_ds_min / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 + pow_hkl_del (2) 
         hkl (2) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_min (2) = abs (ttheta - pow_tthmin) 
         hkl (2) = 1.0 
         hkl (1) = 0.0 
         hkl (3) = 0.0 
         h1 = pow_ds_max / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 - pow_hkl_del (2) 
         hkl (2) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_max (2) = abs (ttheta - pow_tthmax) 
!                                                                       
         hkl (3) = 1.0 
         hkl (2) = 0.0 
         hkl (1) = 0.0 
         h1 = pow_ds_min / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 + pow_hkl_del (3) 
         hkl (3) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_min (3) = abs (ttheta - pow_tthmin) 
         hkl (3) = 1.0 
         hkl (2) = 0.0 
         hkl (1) = 0.0 
         h1 = pow_ds_max / sqrt (skalpro (hkl, hkl, cr_rten) ) 
         h2 = h1 - pow_hkl_del (3) 
         hkl (3) = h2 
         dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
         ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
         del_tth_max (3) = abs (ttheta - pow_tthmax) 
!                                                                       
         WRITE (output_io, 1245) 
         WRITE (output_io, 1250) del_tth_min 
         WRITE (output_io, 1260) del_tth_max 
         WRITE (output_io, 1270) pow_hkl_shift 
         WRITE (output_io, 1240) pow_hkl_del 
!                                                                       
         WRITE (output_io, 2100) cprofile (pow_profile) 
         IF (pow_profile.eq.0) then 
            CONTINUE 
         ELSEIF (pow_profile.eq.POW_PROFILE_GAUSS) then 
            WRITE (output_io, 1235) pow_delta 
            WRITE (output_io, 2123) pow_width 
         ELSEIF (pow_profile.eq.POW_PROFILE_PSVGT) then 
            WRITE (output_io, 2120) pow_u, pow_v, pow_w 
            WRITE (output_io, 2121) pow_eta, pow_etax 
            WRITE (output_io, 2122) pow_p1, pow_p2, pow_p3, pow_p4 
            WRITE (output_io, 2123) pow_width 
         ENDIF 
!                                                                       
      ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
         WRITE (output_io, 1290) pow_qmin, pow_qmax 
         WRITE (output_io, 1291) pow_deltaq 
         WRITE (output_io, 2100) cprofile (pow_profile) 
         IF (pow_profile.eq.0) then 
            CONTINUE 
         ELSEIF (pow_profile.eq.POW_PROFILE_GAUSS) then 
            WRITE (output_io, 1235) pow_delta 
            WRITE (output_io, 2123) pow_width 
         ELSEIF (pow_profile.eq.POW_PROFILE_PSVGT) then 
            WRITE (output_io, 2120) pow_u, pow_v, pow_w 
            WRITE (output_io, 2121) pow_eta, pow_etax 
            WRITE (output_io, 2122) pow_p1, pow_p2, pow_p3, pow_p4 
            WRITE (output_io, 2123) pow_width 
         ENDIF 
      ENDIF 
!                                                                       
      IF (ldbw) then 
         WRITE (output_io, 1300) 'used' 
      ELSE 
         WRITE (output_io, 1300) 'ignored' 
      ENDIF 
!                                                                       
      IF (ano) then 
         WRITE (output_io, 1310) 'used' 
      ELSE 
         WRITE (output_io, 1310) 'ignored' 
      ENDIF 
!                                                                       
      IF (pow_pref) then 
         WRITE (output_io, 1340) cpref (pow_pref_type) 
         WRITE (output_io, 1341) pow_pref_g1, pow_pref_g2 
         WRITE (output_io, 1342) pow_pref_hkl 
      ELSE 
         WRITE (output_io, 1340) 'off' 
      ENDIF 
!                                                                       
      WRITE (output_io, 1400) cfour (pow_four_mode) 
      IF (pow_four_mode.eq.0.or.pow_four_mode.eq.5) then 
         IF (pow_l_all) then 
            WRITE (output_io, 1450) 
         ELSE 
            WRITE (output_io, 1455) 
         ENDIF 
      ENDIF 
      IF (pow_lp.eq.POW_LP_NONE) then 
         WRITE (output_io, 1500) 
      ELSEIF (pow_lp.eq.POW_LP_BRAGG) then 
         WRITE (output_io, 1510) pow_lp_ang 
      ELSEIF (pow_lp.eq.POW_LP_NEUT) then 
         WRITE (output_io, 1520) 
      ELSEIF (pow_lp.eq.POW_LP_SYNC) then 
         WRITE (output_io, 1530) pow_lp_fac, pow_lp_ang 
      ENDIF 
      WRITE (output_io, 1600) ccalc (pow_four_type) 
!DBG_RBN write (output_io,*) ' Fourier Version ',ccalc(pow_four_vers)   
!                                                                       
 1000 FORMAT    ( ' Settings for Powder Diffraction segment :') 
 1200 FORMAT    ( '   Radiation               : ',A,', wavelength = ',  &
     &          F7.4,' A == ', F8.4,'keV')                               
 1201 FORMAT    ( '   Radiation               : ',A,', wavelength = ',  &
     &          F7.4,' A == ', F8.4,'meV')
 1210 FORMAT    ( '   Radiation               : ',A,', wavelength = ',A4,   &
     &                    ' = ',F7.4,' A')                              
 1211 FORMAT    ( '   Calculations for axis   : ',a) 
 1220 FORMAT    ( '   TTHmin, TTHmax          : ',f10.5,2x,f10.5) 
 1221 FORMAT    ( '   d* min, d* max          : ',f10.5,2x,f10.5) 
 1230 FORMAT    ( '   DELTA TTH               : ',f10.5) 
 2100 FORMAT    ( '   Instrument resolution   : ',A) 
 1235 FORMAT( '   Instrument resolution   : ',f10.5,2x,'(0.0 = off)') 
 2120 FORMAT    ( '       Profile U,V,W       : ',f10.5,2x,f10.5,2x,    &
     &                                                   f10.5)         
 2121 FORMAT    ( '       Profile Eta, X      : ',f10.5,2x,f10.5) 
 2122 FORMAT    ( '       Profile asymmetry   : ',4(f10.5,2x)) 
 2123 FORMAT    ( '       Profile width *FWHM : ',1(f10.5,2x)) 
 1240 FORMAT    ( '   dH, dK, dL              : ',3(f10.5,2x)) 
 1245 FORMAT    ( '   Corr. steps in TTH') 
 1250 FORMAT    ( '   at TTHmin               : ',3(f10.5,2x)) 
 1260 FORMAT    ( '   at TTHmax               : ',3(f10.5,2x)) 
 1270 FORMAT    ( '   shift for dH,dK,dL      : ',3(f10.5,2x)) 
 1290 FORMAT    ( '   Q  min, Q  max          : ',f10.5,2x,f10.5) 
 1291 FORMAT    ( '   DELTA Q                 : ',f10.5) 
 1300 FORMAT    ( '   Temp. factors           : ',A) 
 1310 FORMAT    ( '   Anomalous scat.         : ',A) 
 1340 FORMAT    ( '   Preferred orientation   : ',A) 
 1341 FORMAT    ( '   Preferred damp,portion  : ',2(f10.5,2x)) 
 1342 FORMAT    ( '   Preferred axis hkl      : ',3(f10.5,2x)) 
 1400 FORMAT    ( '   Fourier Mode            : ',A) 
 1450 FORMAT    ( '       Bragg Reflections   : ','included') 
 1455 FORMAT    ( '       Bragg Reflections   : ','excluded') 
 1500 FORMAT    ( '   Powder diffractometer   : ','none specified',     &
     &                   ' no Lorentz/Polarisation effect calculated')  
 1510 FORMAT    ( '   Powder diffractometer   : ','Bragg-Brentano',/    &
     &                   '   2-Theta Monochromator   : ',f10.5)         
 1520 FORMAT    ( '   Powder diffractometer   : ',                      &
     &                   'Neutron Debye-Scherrer')                      
 1530 FORMAT    ( '   Powder diffractometer   : ','3-axis Synchrotron',/&
     &                   '   Polarisation fraction   : ',f10.5,/        &
     &                   '   2-Theta Monochromator   : ',f10.5)         
 1600 FORMAT    ( '   Fourier calculation via : ',A) 
      END SUBROUTINE pow_show                       
!*****7*****************************************************************
      SUBROUTINE do_pow_set (zeile, lcomm) 
!-                                                                      
!     Set various paramters for the powder diffraction                  
!+                                                                      
      USE discus_config_mod 
      USE debye_mod 
      USE diffuse_mod 
      USE powder_mod 
      USE ber_params_mod
      USE get_params_mod
      USE trig_degree_mod
      USE string_convert_mod
      IMPLICIT none 
!                                                                       
      INTEGER MAXW 
      PARAMETER (MAXW = 7) 
!                                                                       
!                                                                       
      CHARACTER(1024) cpara (MAXW) 
      CHARACTER ( * ) zeile 
      CHARACTER (LEN=1024) :: symbol
      INTEGER lpara (MAXW) 
      INTEGER lcomm 
      INTEGER :: lsymbol
      INTEGER ianz 
      INTEGER i 
      REAL werte (MAXW) 
!                                                                       
      LOGICAL str_comp 
!     REAL cosd 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lcomm) 
      IF (ier_num.eq.0) then 
         IF (str_comp (cpara (1) , 'axis', 2, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               IF (str_comp (cpara (2) , 'dstar', 1, lpara (2) , 5) )   &
               then                                                     
                  pow_axis = POW_AXIS_Q 
               ELSEIF (str_comp (cpara (2) , 'q', 1, lpara (2) , 1) )   &
               then                                                     
                  pow_axis = POW_AXIS_Q 
               ELSEIF (str_comp (cpara (2) , 'tth', 1, lpara (2) , 3) ) &
               then                                                     
                  pow_axis = POW_AXIS_TTH 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'back', 2, lpara (1) , 4) ) then 
            IF (ianz.ge.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  DO i = 2, ianz 
                  pow_back (i - 2) = werte (i) 
                  ENDDO 
                  pow_nback = ianz - 2
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'bragg', 2, lpara (1) , 5) )     &
         then                                                           
            IF (ianz.eq.2) then 
               IF (str_comp (cpara (2) , 'incl', 1, lpara (2) , 4) )    &
               then                                                     
                  pow_l_all = .true. 
               ELSEIF (str_comp (cpara (2) , 'excl', 1, lpara (2) , 4) )&
               then                                                     
                  pow_l_all = .false. 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'disp', 2, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               IF (str_comp (cpara (2) , 'anom', 1, lpara (2) , 4) )    &
               then                                                     
                  ano = .true. 
               ELSEIF (str_comp (cpara (2) , 'off', 1, lpara (2) , 3) ) &
               then                                                     
                  ano = .false. 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'delta', 2, lpara (1) , 5) )     &
         then                                                           
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_delta = werte (2) 
                  pow_profile = POW_PROFILE_GAUSS 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'dtth', 2, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF(werte(2)<0.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta step must be positive!'
                  ELSEIF(werte(2)>180.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta step must be less than 180degrees'
                  ELSE
                     pow_deltatth = werte (2) 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'dq', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_deltaq = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'dh', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_del (1) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'dk', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_del (2) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'dl', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_del (3) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     set the energy of the radiation to be used 'energy'                             
!                                                                       
         ELSEIF (str_comp (cpara(1), 'energy', 2, lpara(1), 6) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               renergy  = werte (2) 
               lambda   = ' ' 
               l_energy = .true.
            ELSE 
               ier_num = -6 
               ier_typ = ER_COMM 
            ENDIF 
!
         ELSEIF (str_comp (cpara (1) , 'pref', 2, lpara (1) , 4) ) then 
            IF (ianz.ge.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               IF (str_comp (cpara (2) , 'off', 2, lpara (2) , 3) )     &
               then                                                     
                  pow_pref = .false. 
               ELSE 
                  IF (str_comp (cpara (2) , 'riet', 2, lpara (2) , 4) ) &
                  then                                                  
                     pow_pref_type = POW_PREF_RIET 
                     pow_pref = .true. 
                  ELSEIF (str_comp (cpara (2) , 'march', 2, lpara (2) , &
                  4) ) then                                             
                     pow_pref_type = POW_PREF_MARCH 
                     pow_pref = .true. 
                  ELSEIF (str_comp (cpara (2) , 'damp', 2, lpara (2) ,  &
                  4) .or.str_comp (cpara (2) , 'g1', 2, lpara (2) , 2) )&
                  then                                                  
                     cpara (2) = '0' 
                     lpara (2) = 1 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_pref_g1 = werte (3) 
                     ENDIF 
                  ELSEIF (str_comp (cpara (2) , 'portion', 2, lpara (2) &
                  , 7) .or.str_comp (cpara (2) , 'g2', 2, lpara (2) , 2)&
                  ) then                                                
                     cpara (2) = '0' 
                     lpara (2) = 1 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_pref_g2 = werte (3) 
                     ENDIF 
                  ELSEIF (str_comp (cpara (2) , 'hkl', 2, lpara (2) , 7)&
                  ) then                                                
                     cpara (2) = '0' 
                     lpara (2) = 1 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_pref_hkl (1) = werte (3) 
                        pow_pref_hkl (2) = werte (4) 
                        pow_pref_hkl (3) = werte (5) 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'profile', 2, lpara (1) , 7) )   &
         then                                                           
            IF (ianz.ge.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               IF (str_comp (cpara (2) , 'off', 2, lpara (2) , 3) )     &
               then                                                     
                  pow_profile = 0 
                  pow_delta = 0.0 
                  pow_eta = 0.5 
               ELSEIF (str_comp (cpara (2) , 'gauss', 2, lpara (2) , 5) &
               ) then                                                   
                  pow_profile = POW_PROFILE_GAUSS 
               ELSEIF (str_comp (cpara (2) , 'pseudo', 2, lpara (2) , 6)&
               ) then                                                   
                  pow_profile = POW_PROFILE_PSVGT 
               ELSEIF (str_comp (cpara (2) , 'eta', 2, lpara (2) , 3) ) &
               then                                                     
                  cpara (1) = '0' 
                  lpara (1) = 1 
                  cpara (2) = '0' 
                  lpara (2) = 1 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     pow_eta = werte (3) 
                     IF (ianz.eq.4) then 
                        pow_etax = werte (4) 
                     ELSE 
                        pow_etax = 0.0 
                     ENDIF 
                  ENDIF 
               ELSEIF (str_comp (cpara (2) , 'uvw', 2, lpara (2) , 3) ) &
               then                                                     
                  cpara (1) = '0' 
                  lpara (1) = 1 
                  cpara (2) = '0' 
                  lpara (2) = 1 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     pow_u = werte (3) 
                     pow_v = werte (4) 
                     pow_w = werte (5) 
                  ENDIF 
               ELSEIF (str_comp (cpara (2) , 'asym', 2, lpara (2) , 4) )&
               then                                                     
                  cpara (1) = '0' 
                  lpara (1) = 1 
                  cpara (2) = '0' 
                  lpara (2) = 1 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     pow_p1 = werte (3) 
                     pow_p2 = werte (4) 
                     pow_p3 = werte (5) 
                     pow_p4 = werte (6) 
                  ENDIF 
               ELSEIF (str_comp (cpara (2) , 'width', 2, lpara (2) , 5) &
               ) then                                                   
                  cpara (1) = '0' 
                  lpara (1) = 1 
                  cpara (2) = '0' 
                  lpara (2) = 1 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     pow_width = werte (3) 
                  ENDIF 
!DBGRBN ELSEIF(str_comp(cpara(2),'parameter',2,lpara(2),9)) then        
!DBGRBN if    (str_comp(cpara(3),'theta',2,lpara(3),5)) then            
!DBGRBN pow_pr_par = POW_PROFILE_PAR_TTH                                
!DBGRBN ELSEIF(str_comp(cpara(3),'q',2,lpara(3),1)) then                
!DBGRBN pow_pr_par = POW_PROFILE_PAR_Q                                  
!DBGRBN endif                                                           
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'scale', 2, lpara (1) , 5) )     &
         then                                                           
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_scale = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'sh', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_shift (1) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'sk', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_shift (2) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'stepr', 2, lpara (1) , 5) )     &
         then                                                           
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_del_hist = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'sl', 2, lpara (1) , 2) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_hkl_shift (3) = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     Switch Fourier type between normal Fourier and DEBYE calculation  
!                                                                       
         ELSEIF (str_comp (cpara (1) , 'calc', 1, lpara (1) , 4) ) then 
            IF (ianz.ge.2) then 
               IF (str_comp (cpara (2) , 'comp', 1, lpara (2) , 4) )    &
               then                                                     
                  pow_four_type = POW_COMPL 
                  pow_four_vers = POW_NEW 
!DBG_RBN              pow_four_vers = POW_COMPL                         
!DBG_RBN                                                                
!DBG_RBN        The new fourier mode seems to work fine for right now,  
!DBG_RBN        make this the standard. Keep old for debugging...       
!DBG_RBN            ELSEIF(str_comp(cpara(2),'new',1,lpara(2),3)) then  
!DBG_RBN              pow_four_type = POW_COMPL                         
!DBG_RBN              pow_four_vers = POW_NEW                           
               ELSEIF (str_comp (cpara (2) , 'debye', 1, lpara (2) , 5) ) THEN                                                   
                     pow_four_type = POW_HIST 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!------ Switch Fourier mode between normal Fourier and Stacking         
!       Fault 'four'                                                    
!                                                                       
         ELSEIF (str_comp (cpara (1) , 'four', 1, lpara (1) , 4) ) THEN 
            IF (ianz.eq.2) then 
               IF (str_comp (cpara (2) , 'four', 1, lpara (2) , 4) )    &
               then                                                     
                  pow_four_mode = POW_FOURIER 
               ELSEIF (str_comp (cpara (2) , 'stack', 1, lpara (2) , 5) &
               ) then                                                   
                  pow_four_mode = POW_STACK 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     Switch application of LP correction to proper instrument 'lpcor'  
!                                                                       
         ELSEIF (str_comp (cpara (1) , 'lpcor', 1, lpara (1) , 5) ) THEN                                                           
            IF (ianz.ge.2) then 
               IF (str_comp (cpara (2) , 'bragg', 4, lpara (2) , 5) )   &
               then                                                     
                  pow_lp = POW_LP_BRAGG 
                  CALL del_params (2, ianz, cpara, lpara, maxw) 
                  IF (ianz.eq.1) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_lp_ang = werte (1) 
                        pow_lp_fac = (cosd (pow_lp_ang) ) **2 
                     ELSE 
                        RETURN 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSEIF (str_comp (cpara (2) , 'corre', 4, lpara (2) , 5) )   &
               then                                                     
                  pow_lp = POW_LP_CORRE 
                  CALL del_params (2, ianz, cpara, lpara, maxw) 
                  IF (ianz.eq.1) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_lp_ang = werte (1) 
                        pow_lp_fac = 0.5
                     ELSE 
                        RETURN 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSEIF (str_comp (cpara (2) , 'neutron', 4, lpara (2) ,  &
               7) ) then                                                
                  pow_lp = POW_LP_NEUT 
               ELSEIF (str_comp (cpara (2) , 'none', 4, lpara (2) , 4) )&
               then                                                     
                  pow_lp = POW_LP_NONE 
               ELSEIF (str_comp (cpara (2) , 'synchrotron', 4, lpara (2)&
               , 11) ) then                                             
                  pow_lp = POW_LP_SYNC 
                  CALL del_params (2, ianz, cpara, lpara, maxw) 
                  IF (ianz.eq.1.or.ianz.eq.2) then 
                     werte (2) = 0.0 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        pow_lp_fac = werte (1) 
                        pow_lp_ang = werte (2) 
                        pow_lp_cos = abs (cosd (pow_lp_ang) ) 
                     ELSE 
                        RETURN 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSE 
                  ier_num = - 90 
                  ier_TYP = ER_APPL 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     Switch usage of temperature coefficients on/off 'temp'            
!                                                                       
         ELSEIF (str_comp (cpara (1) , 'temp', 1, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               IF (str_comp (cpara (2) , 'igno', 1, lpara (2) , 4) )    &
               then                                                     
                  ldbw = .false. 
               ELSEIF (str_comp (cpara (2) , 'use', 1, lpara (2) , 3) ) &
               then                                                     
                  ldbw = .true. 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'tthmax', 5, lpara (1) , 6) )    &
         then                                                           
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF(werte(2)<0.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta max must be positive!'
                  ELSEIF(werte(2)>180.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta max must be less than 180degrees'
                  ELSE
                     pow_tthmax = werte (2) 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'tthmin', 5, lpara (1) , 6) )    &
         then                                                           
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF(werte(2)<0.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta min must be positive!'
                  ELSEIF(werte(2)>180.0) THEN
                     ier_num = -107
                     ier_typ = ER_APPL
                     ier_msg(1) = '2Theta min must be less than 180degrees'
                  ELSE
                     pow_tthmin = werte (2) 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'qmax', 4, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_qmax = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'qmin', 4, lpara (1) , 4) ) then 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  pow_qmin = werte (2) 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     set the wave length to be used 'wvle'                             
!                                                                       
         ELSEIF (str_comp (cpara (1) , 'wvle', 1, lpara (1) , 4) ) THEN 
            IF (ianz.eq.2) then 
               cpara (1) = '0' 
               lpara (1) = 1 
               symbol    = cpara(2)
               lsymbol   = lpara(2)
               CALL do_cap (symbol) 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  rlambda = werte (2) 
                  lambda = ' ' 
                  l_energy = .false.
               ELSEIF (ichar ('A') <=  ichar (symbol    (1:1) ) .AND.&
                       ichar (symbol    (1:1) ) <= ichar ('Z') ) THEN                 
                  lambda = symbol(1:lsymbol)  
                  l_energy = .false.
                  CALL no_error
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSE 
            ier_num = - 8 
            ier_typ = ER_COMM 
         ENDIF 
      ENDIF 
!                                                                       
      END SUBROUTINE do_pow_set                     
!*****7*****************************************************************
      SUBROUTINE powder_run 
!-                                                                      
!     Calculate global parameters and start the individual modes        
!+                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE debye_mod
      USE diffuse_mod 
      USE molecule_mod 
      USE discus_plot_mod
      USE discus_plot_init_mod
      USE powder_mod 
      USE trig_degree_mod
      USE wink_mod
      IMPLICIT none 
!                                                                       
!
      INTEGER                 :: i
      LOGICAL                 :: do_mol      ! Molecules with Biso /= 0.0
      INTEGER                 :: powder_nmol ! Number of look up dimensions molecules
      REAL   , DIMENSION(1:3) :: u
!                                                                       
!     REAL sind 
!
      u = 0.0
!                                                                       
!     Calculate the global maximum h,k,l                                
!                                                                       
      IF (rlambda.ne.0.0) then 
!                                                                       
!      Perform error checking                                           
!                                                                       
         IF (pow_four_type.eq.POW_COMPL.or.pow_four_type.eq.POW_NEW)    &
         THEN                                                           
            IF (pow_hkl_del (1) .eq.0.and.pow_hkl_del (1)               &
            .eq.0.and.pow_hkl_del (1) .eq.0) then                       
               ier_num = - 106 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
         ENDIF 
         IF (pow_axis.eq.POW_AXIS_TTH) then 
            IF (pow_tthmax.le.pow_tthmin.or.pow_deltatth.le.0.0) then 
               ier_num = - 107 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
         ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
            IF (pow_qmax.le.pow_qmin.or.pow_deltaq.le.0.0) then 
               ier_num = - 108 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
         ENDIF 
!
!        Caclulate hkl limits 
!
         IF(pow_axis.eq.POW_AXIS_TTH) THEN
            pow_ds_max = 2. * sind ((pow_tthmax+pow_deltatth) * 0.5) / rlambda 
            pow_ds_min = 2. * sind (pow_tthmin * 0.5) / rlambda 
         ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
            pow_ds_max = (pow_qmax+pow_deltaq)/REAL(zpi)
            pow_ds_min = pow_qmin/REAL(zpi)
            IF(pow_qmax*rlambda/2./zpi > 1.0) THEN
               ier_num = -108
               ier_typ = ER_APPL
               ier_msg(1) = 'Qmax is too large for current wave length'
               ier_msg(2) = 'Qmax*lambda/(4pi) is greater than one!'
               ier_msg(3) = 'Reduce Qmax or the wave length'
               RETURN
            ENDIF
         ENDIF
         pow_hkl_max (1) = cr_a0 (1) * pow_ds_max 
         pow_hkl_max (2) = cr_a0 (2) * pow_ds_max 
         pow_hkl_max (3) = cr_a0 (3) * pow_ds_max 
!                                                                       
         IF (pow_four_type.eq.POW_COMPL) THEN 
            CALL powder_complete ()
         ELSEIF (pow_four_type.eq.POW_NEW) THEN 
            CALL powder_complete ()
         ELSEIF (pow_four_type.eq.POW_HIST) then 
            CALL plot_ini_trans (1.0,                          &
                 pl_tran_g, pl_tran_gi, pl_tran_f, pl_tran_fi, &
                 cr_gten, cr_rten, cr_eps)

            CALL powder_trans_atoms_tocart (u)
!
!           u is the body diagonal of the cartesian box around the crystal
!           calculate its length and use the length to allocate the histogram size
!
!
!           Any molecules with b-value /= zero ?
!
            do_mol      = .false.
            powder_nmol = 0
            search_mol: DO i=1, mole_num_type
               IF(mole_biso(i) > 0.0) THEN
                  do_mol   = .true.
                  powder_nmol = mole_num_type + mole_num_type*(mole_num_type+1)/2
                  EXIT search_mol
               ENDIF
            ENDDO search_mol
            IF(do_mol) THEN
               CALL powder_debye_hist_cart_mole (u, cr_nscat, do_mol, powder_nmol)
            ELSE
               CALL powder_debye_hist_cart      (u, cr_nscat)
            ENDIF
!           CALL alloc_debye (       1,      1,   MAXDQXY, MASK )
            CALL powder_trans_atoms_fromcart 
         ENDIF 
      ENDIF 
!                                                                       
      END SUBROUTINE powder_run                     
!*****7*****************************************************************
      SUBROUTINE powder_complete ()
!-                                                                      
!     Calculate global parameters and start the individual modes        
!+                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE diffuse_mod 
      USE fourier_sup
      USE metric_mod
      USE powder_mod 
      USE powder_tables_mod 
      USE stack_menu
      USE wink_mod
!                                                                       
      USE param_mod 
      USE prompt_mod 
      USE precision_mod 
      USE trig_degree_mod
      IMPLICIT none 
!                                                                       
!     INTEGER, INTENT(IN)  :: cr_nscat_temp
!                                                                       
      CHARACTER(1024) line 
      INTEGER laenge 
      INTEGER i 
      INTEGER h_start, h_end 
      INTEGER k_start, k_end 
      INTEGER :: l_start=0, l_end=1
      INTEGER ih, ik 
      INTEGER                    :: n_qxy   = 1
      INTEGER                    :: n_nscat = 1
      INTEGER                    :: n_natom = 1
      INTEGER                    :: n_pkt   = 1
      INTEGER itth 
!      INTEGER, DIMENSION(0:cr_nscat_temp) :: natom ! (0:MAXSCAT) 
      LOGICAL l_twoparts
      LOGICAL l_ano 
      LOGICAL l_hh_real 
      LOGICAL l_kk_real 
      LOGICAL l_ll_real 
      LOGICAL                   :: calc_f2aver, rept_f2aver
      REAL llstart, llend 
      REAL :: llstart2=0.0, llend2=1.0
      REAL (PREC_DP):: xstart, xdelta   ! start/step in dstar for sinthea/lambda table
      REAL hh, kk, ll 
      REAL rr, rrr, rtm 
      REAL hkl (3) 
      REAL ttheta, dstar , q
      REAL (KIND=PREC_DP)  :: inten 
      REAL u (3), v (3), w_min (3), w_max (3) 
      REAL u2, vv, ww 
      REAL aaa, bbb, ccc 
      REAL llstartmini 
      REAL llendmini 
      REAL ss 
!                                                                       
!      REAL calc_preferred 
!     REAL skalpro 
!     REAL asind 
      REAL seknds 
!
      n_qxy   = 1
      n_nscat = 1
      n_natom = 1
      n_pkt   = 1
      l_twoparts = .false.
      calc_f2aver = .true.    ! Assume that we need form factors
      rept_f2aver = .true.    ! Assume that we need to repeat them
!                                                                       
!DBG_RBN      open(13,file='hkl.list',status='unknown')                 
      ss = seknds (0.0) 
!                                                                       
!     Set Fourier definitions                                           
!                                                                       
      inc (2) = 1 
      DO i = 1, 3 
         vi (i, 1) = 0.0 
         vi (i, 2) = 0.0 
      ENDDO 
      vi (3, 1) = pow_hkl_del (3) 
      four_log = .false. 
!
      IF(pow_axis == POW_AXIS_Q ) THEN
         n_pkt = NINT((pow_qmax+pow_deltaq  -pow_qmin  )/pow_deltaq  ) + 2
      ELSEIF(pow_axis == POW_AXIS_TTH ) THEN
         n_pkt = NINT((pow_tthmax+pow_deltatth-pow_tthmin)/pow_deltatth) + 2
      ENDIF
      IF(n_pkt .gt. POW_MAXPKT) THEN
         CALL alloc_powder ( n_pkt )
      ENDIF
!     reset powder diagramm                                             
!                                                                       
      pow_qsp(:)    = 0.0D0   ! 0:POW_MAXPKT
      pow_f2aver(:) = 0.0D0   ! 0:POW_MAXPKT
      pow_faver2(:) = 0.0D0   ! 0:POW_MAXPKT
      pow_nreal     = 0
      pow_u2aver    = 0.0
!     DO i = 1, POW_MAXPKT 
!     pow_qsp (i) = 0.0 
!     ENDDO 
      n_qxy   = MAX(n_qxy,inc(1) * inc(2),n_pkt,MAXQXY)
      n_nscat = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
      n_natom = MAX(n_natom,cr_natoms,DIF_MAXAT)
      IF (inc (1) * inc (2) .gt. MAXQXY  .OR.          &
          n_pkt             .gt. MAXQXY  .OR.          &
          cr_nscat>DIF_MAXSCAT              ) THEN
        CALL alloc_diffuse (n_qxy,  n_nscat,  n_natom )
        IF (ier_num /= 0) THEN
          RETURN
        ENDIF
      ENDIF
!                                                                       
!------ calculate complex exponent table, form factor table             
!                                                                       
      pow_npkt = n_pkt            ! set actual number of powder data points
      IF(pow_axis == POW_AXIS_Q ) THEN
         xstart = pow_qmin  /zpi
         xdelta = pow_deltaq/zpi
         CALL powder_stltab(n_pkt, xstart  ,xdelta    )   ! Really only needed for <f^2> and <f>^2 for F(Q) and S(Q)
      ELSE
         calc_f2aver = .false.
         rept_f2aver = .false.
      ENDIF
      CALL four_cexpt 
      CALL four_formtab 
      CALL powder_getatoms 
!                                                                       
!     calculate global limits along h                                   
!                                                                       
!DBG                                                                    
      l_ano = ano 
!DBG      write(*,*) 'ANOMALOUS ',l_ano                                 
      IF (l_ano) then 
         h_start = - int (pow_hkl_max (1) / pow_hkl_del (1) ) 
      ELSE 
         h_start = 0 
      ENDIF 
      h_end = int (pow_hkl_max (1) / pow_hkl_del (1) ) 
!                                                                       
!     loop over h                                                       
!                                                                       
      DO ih = h_start, h_end 

      hh = ih * pow_hkl_del (1) + pow_hkl_shift (1) 
      hkl (1) = hh 
      l_hh_real = abs ( (nint (hh) - hh) / pow_hkl_del (1) ) .gt.0.51 
!                                                                       
!     --Produce output to keep the user informed                        
!                                                                       
      WRITE (output_io, 5000) hh, pow_hkl_del (1), pow_hkl_max (1) 
!                                                                       
!     --NEW LIMITS                                                      
!                                                                       
      WRITE (line, 6000) hh 
 6000 FORMAT      (f12.6,',0,0, 1,0,0, rdrr') 
      laenge = 29 
      CALL do_proj (line, laenge) 
      u (1) = res_para (1) 
      u (2) = res_para (2) 
      u (3) = res_para (3) 
      u2 = skalpro (u, u, cr_rten) 
      line = '0,1,0, 1,0,0, ddrr' 
      laenge = 18 
      CALL do_proj (line, laenge) 
      v (1) = res_para (4) 
      v (2) = res_para (5) 
      v (3) = res_para (6) 
      vv = sqrt (skalpro (v, v, cr_rten) ) 
      v (1) = v (1) / vv 
      v (2) = v (2) / vv 
      v (3) = v (3) / vv 
      rr = pow_ds_max**2 - u2 
!DBG_RBN                                                                
!DBG      write(*,*) ' Vector u ',u                                     
!DBG      write(*,*) ' Vector v ',v                                     
!DBG      write(*,*) ' x*       ',rr                                    
      IF (rr.ge.0) then 
         w_min (1) = u (1) - sqrt ( (rr) ) * v (1) 
         w_min (2) = u (2) - sqrt ( (rr) ) * v (2) 
         w_min (3) = u (3) - sqrt ( (rr) ) * v (3) 
         ww = sqrt (skalpro (w_min, w_min, cr_rten) ) 
!DBG        write(*,'(a,5f10.4)') ' k minimum ',w_min, ww,pow_ds_max    
         w_max (1) = u (1) + sqrt ( (rr) ) * v (1) 
         w_max (2) = u (2) + sqrt ( (rr) ) * v (2) 
         w_max (3) = u (3) + sqrt ( (rr) ) * v (3) 
         ww = sqrt (skalpro (w_max, w_max, cr_rten) ) 
!DBG        write(*,'(a,5f10.4)') ' k maximum ',w_max, ww,pow_ds_max    
!DBG        write(line,'(a4,f6.2)') 'hkl.',hh                           
!DBG        do i=5,14                                                   
!DBG          if(line(i:i).eq. ' ') then                                
!DBG            line(i:i) = '0'                                         
!DBG          endif                                                     
!DBG        ENDDO                                                       
!DBG        open(15,file=line,status='unknown')                         
!DBG        line(1:3) = 'edg'                                           
!DBG        open(16,file=line,status='unknown')                         
!DBG        line(1:3) = 'HHH'                                           
!DBG        open(17,file=line,status='unknown')                         
!DBG        line(1:3) = 'EEE'                                           
!DBG        open(18,file=line,status='unknown')                         
      ENDIF 
      IF (rr.gt.0) then 
         eck (1, 1) = hh 
         eck (1, 2) = hh 
         eck (1, 3) = hh 
         IF (.not.l_ano.and.ih.eq.0) then 
            k_start = 0 
         ELSE 
            k_start = int( w_min (2) / pow_hkl_del (2) )
         ENDIF 
         k_end = int( w_max (2) / pow_hkl_del (2) )
!DBG_RBN                                                                
!DBG      k_start = -6.00000/pow_hkl_del(2)                             
!DBG      k_end   =  6.00000/pow_hkl_del(2)                             
!DBG      k_start = w_min(2)/pow_hkl_del(2)                             
!DBG      k_end   = w_max(2)/pow_hkl_del(2)                             
!DBGXXX      if(hkl(1).eq.-6.) then                                     
!DBG        write(*,*) 'k_start k_end',k_start,k_end                    
!DBG        write(*,*)                                                  
!DBGXXX      endif                                                      
!                                                                       
!     ----Start loop over k                                             
!                                                                       
         DO ik = k_start, k_end 
!DBGXXX      if(hkl(1).eq.0.0) then                                     
!DBGXXX        write(*,*) ' ik*pow_hkl_del(2) ',ik*pow_hkl_del(2)       
!DBGXXX        write(*,*) ' pow_hkl_shift(2)  ',pow_hkl_shift(2)        
!DBGXXX      endif                                                      
         kk = ik * pow_hkl_del (2) + pow_hkl_shift (2) 
         hkl (2) = kk 
         l_kk_real = abs ( (nint (kk) - kk) / pow_hkl_del (2) )         &
         .gt.0.51                                                       
!                                                                       
!     --Produce output to keep the user informed                        
!                                                                       
!       write (output_io,5010) kk,pow_hkl_del(2),pow_hkl_max(2)         
!                                                                       
         aaa = cr_rten (3, 3) 
         bbb = 2 * (cr_rten (1, 3) * hkl (1) + cr_rten (2, 3) * hkl (2) &
         )                                                              
         ccc = cr_rten (1, 1) * hkl (1) **2 + 2. * cr_rten (1, 2)       &
         * hkl (1) * hkl (2) + cr_rten (2, 2) * hkl (2) **2 -           &
         pow_ds_max**2                                                  
         rrr = bbb**2 - 4. * aaa * ccc 
!DBG          if(.not.l_ano .and. ih.eq.0 .and. ik.eq.0) then           
!DBG            write(*,*) ' rrr ',rrr                                  
!DBG          endif                                                     
         IF (rrr.ge.0) then 
!DBGXXX        write(*,*) ' hkl ',hkl                                   
!DBGXXX        write(*,'(a,3f10.4)') ' aaa,bbb,ccc ',aaa,bbb,ccc        
            llstart = ( - bbb - sqrt (rrr) ) / 2. / aaa 
            hkl (3) = llstart 
!DBGXXX        ww   = sqrt(skalpro(hkl,hkl,cr_rten))                    
!DBGXXX        write(*,'(a,5f10.4)') ' l minimum ',hkl, ww,pow_ds_max   
            llend = ( - bbb + sqrt (rrr) ) / 2. / aaa 
            hkl (3) = llend 
!DBGXXX        ww   = sqrt(skalpro(hkl,hkl,cr_rten))                    
!DBGXXX        write(*,'(a,5f10.4)') ' l maximum ',hkl, ww,pow_ds_max   
!                                                                       
            ccc = cr_rten (1, 1) * hkl (1) **2 + 2. * cr_rten (1, 2)    &
            * hkl (1) * hkl (2) + cr_rten (2, 2) * hkl (2) **2 -        &
            pow_ds_min**2                                               
            rtm = bbb**2 - 4. * aaa * ccc 
!DBGXXX          if(ih.eq.0 .and. ik.eq.0) then                         
!DBGXXX            write(*,*) ' llstart ',llstart                       
!DBGXXX            write(*,*) ' llend   ',llend                         
!DBGXXX            write(*,*) ' rtm ',rtm                               
!DBGXXX          endif                                                  
            IF (rtm.gt.0) then 
!                                                                       
!     --------- Intersection with 2Theta minimum sphere                 
!                                                                       
               llendmini = ( - bbb - sqrt (rtm) ) / 2. / aaa 
               hkl (3) = llendmini 
!DBGXXX  ww   = sqrt(skalpro(hkl,hkl,cr_rten))                          
!DBGXXX  write(*,'(a,5f10.4)')'2THETA min: l minimum ',hkl,ww,pow_ds_min
               llstartmini = ( - bbb + sqrt (rtm) ) / 2. / aaa 
               hkl (3) = llstartmini 
!DBGXXX        ww   = sqrt(skalpro(hkl,hkl,cr_rten))                    
               IF (.not.l_ano.and.ih.eq.0.and.ik.eq.0) then 
!                                                                       
!     ----------- Save computational time, start at 2th minimum,        
!     ----------- only one line calculated                              
!                                                                       
!DBGXXX  write(*,'(a,5f10.4)')'2THETA min: l maximum ',hkl,ww,pow_ds_min
!DBGXXX  write(*,*) ' l_ano ',l_ano                                     
!DBGXXX  write(*,*) ' ih    ',ih                                        
!DBGXXX  write(*,*) ' ik    ',ik                                        
!DBGXXX  write(*,*) ' TEST  ',(.not.l_ano .and. ih.eq.0 .and. ik.eq.0)  
!DBGXXX        write(*,*)                                               
!DBGXXX                write(* ,'(2f12.4)') hkl(2),llstart              
!DBGXXX                write( *,'(2f12.4)') hkl(2),llendmini            
!DBGXXX                write( *,'(2f12.4)') hkl(2),llstartmini          
!DBGXXX                write( *,'(2f12.4)') hkl(2),llend                
                  llstart = llstartmini 
                  l_start = int( llstart / pow_hkl_del (3) )
                  l_end = int( llend / pow_hkl_del (3) )
                  l_twoparts = .false. 
!DBG                  write(15,'(2f12.4)') hkl(2),llstart               
!DBG                  write(15,'(2f12.4)') hkl(2),llend                 
               ELSE 
!                                                                       
!     ----------- Calculate all, two lines calculated                   
!                                                                       
                  llstart2 = llstartmini 
                  llend2 = llend 
                  llstart = llstart 
                  llend = llendmini 
                  l_start = int( llstart / pow_hkl_del (3) )
                  l_end = int( llend / pow_hkl_del (3) )
                  l_twoparts = .true. 
!DBG                  write(15,'(2f12.4)') hkl(2),llstart               
!DBG                  write(15,'(2f12.4)') hkl(2),llend                 
!DBGXXX      if(ih.eq.0 .and. ik.eq.0) then                             
!DBGXXX                write(* ,'(2f12.4)') hkl(2),llstart2             
!DBGXXX                write( *,'(2f12.4)') hkl(2),llend2               
!DBGXXX                write( *,'(2f12.4)') hkl(2),llstart              
!DBGXXX                write( *,'(2f12.4)') hkl(2),llendmini            
!DBGXXX      endif                                                      
               ENDIF 
            ELSE 
!                                                                       
!     --------- No intersection with 2-Theta minimum                    
!                                                                       
               IF (.not.l_ano.and.ih.eq.0.and.ik.eq.0) then 
                  l_start = 0 
                  l_end = int( llend / pow_hkl_del (3) )
!DBG                  write(15,'(2f12.4)') hkl(2),0.00                  
!DBG                  write(15,'(2f12.4)') hkl(2),llend                 
               ELSE 
                  l_start = int( llstart / pow_hkl_del (3) )
                  l_end = int( llend / pow_hkl_del (3) )
!DBG                  write(15,'(2f12.4)') hkl(2),llstart               
!DBG                  write(15,'(2f12.4)') hkl(2),llend                 
               ENDIF 
               l_twoparts = .false. 
            ENDIF 
         ENDIF 
!DBG_RBN      END OF NEW L LIMIT                                        
!                                                                       
         IF (rrr.gt.0) then 
            eck (2, 1) = kk 
            eck (2, 2) = kk 
            eck (2, 3) = kk 
!                                                                       
!     --------Distinguish between intersection with tthmin and no       
!     --------New code, first segment is always run                     
!                                                                       
!                                                                       
!     ----------No intersection with 2Theta min sphere                  
!               or first of the two segments                            
!                                                                       
!DBG          if(.not.l_ano .and. ih.eq.0 .and. ik.eq.0) then           
!DBG                write(* ,'(3f12.4)') hkl(1),hkl(2),llstart          
!DBG                write(* ,'(3f12.4)') hkl(1),hkl(2),llendmini        
!DBG                write(* ,'(3f12.4)') hkl(1),hkl(2),llstartmini      
!DBG                write(* ,'(3f12.4)') hkl(1),hkl(2),llend            
!DBG          endif                                                     
!DBG_RBN                                                                
!DBG      l_start = -6.0/pow_hkl_del(3)                                 
!DBG      l_end   =  6.0/pow_hkl_del(3)                                 
!DBG      l_start =  llstart/pow_hkl_del(3)                             
!DBG      l_end   =  llend  /pow_hkl_del(3)                             
            eck (3, 1) = l_start * pow_hkl_del (3) + pow_hkl_shift (3) 
            eck (3, 2) = l_end * pow_hkl_del (3) + pow_hkl_shift (3) 
            eck (3, 3) = l_start * pow_hkl_del (3) + pow_hkl_shift (3) 
            inc (1) = nint ( (eck (3, 2) - eck (3, 1) ) / pow_hkl_del ( &
            3) ) + 1                                                    
!DBG_RBN                                                                
!DBGXXX          if(.not.l_ano .and. ih.eq.0 .and. ik.eq.0) then        
!DBGXXX      write(*,*) 'l_start , l_end ',l_start , l_end              
!DBGXXX      write(*,*) 'eck(3,*)        ',eck(3,1),eck(3,2),eck(3,3)   
!DBGXXX      write(*,*) 'inc(1)          ',inc(1)                       
!DBGXXX      endif                                                      
            IF (inc (1) * inc (2) .gt. MAXQXY  .OR.          &
                cr_nscat>DIF_MAXSCAT              ) THEN
              n_qxy   = MAX(n_qxy,inc(1) * inc(2),MAXQXY)
              n_nscat = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
              n_natom = MAX(n_natom,cr_natoms,DIF_MAXAT)
              CALL alloc_diffuse (n_qxy,  n_nscat,  n_natom )
              IF (ier_num.ne.0) THEN
                RETURN
              ENDIF
            ENDIF
            IF (inc (1) .gt.MAXQXY) then 
               ier_num = - 8 
               ier_typ = ER_APPL 
               WRITE (ier_msg (1), 8888) inc (1) 
               WRITE (ier_msg (2), 8889) MAXQXY 
               ier_msg (3) = 'Increase dl or reduce TTHMAX' 
               RETURN 
            ENDIF 
            IF (pow_four_mode.eq.POW_FOURIER) then 
               IF (pow_four_vers.eq.POW_COMPL) then 
!DBG_RBN                                                                
                  CALL four_run 
               ELSE 
                  CALL four_run_powder 
               ENDIF 
            ELSEIF (pow_four_mode.eq.POW_STACK) then 
               CALL st_fourier(rept_f2aver)
               rept_f2aver = .false.   ! No further calculations needed
            ENDIF 
            DO i = 1, inc (1) 
            hkl (3) = eck (3, 1) + (i - 1) * vi (3, 1) 
            ll = hkl (3) 
            l_ll_real = abs ( (nint (ll) - ll) / pow_hkl_del (3) )      &
            .gt.0.51                                                    
            IF (pow_l_all.or..not.pow_l_all.and. (                      &
            l_hh_real.or.l_kk_real.or.l_ll_real) ) then                 
               dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
!DBG_RBN                                                                
                  IF(pow_axis==POW_AXIS_TTH) THEN
               IF (rlambda * 0.5 * dstar.le.1.0) then 
                  ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
                  IF (pow_tthmin.le.ttheta.and.ttheta.le.(pow_tthmax+pow_deltatth))    &
                  then                                                  
                     itth = int( (ttheta - pow_tthmin) / pow_deltatth )
                     inten = DBLE (csf (i) * conjg (csf (i) ) ) 
                     IF (pow_pref) then 
!write(*,'(a,3(f4.0,1x),1x,f5.2,1x,f10.2,1x,f10.2)') 'hkl',hkl,ttheta,   &
!                        inten , inten * calc_preferred (hkl,            &
!                        pow_pref_type, pow_pref_hkl, pow_pref_g1,       &
!                        pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH)     
                        inten = inten * DBLE(calc_preferred (hkl,            &
                        pow_pref_type, pow_pref_hkl, pow_pref_g1,       &
                        pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH))     
                     ENDIF 
                     pow_qsp (itth) = pow_qsp (itth) + inten 
!DBG_RBN                                                                
!DBG                write(16,'(2f12.4)') hkl(2),hkl(3)                  
                  ENDIF 
               ENDIF 
                  ELSEIF(pow_axis==POW_AXIS_Q  ) THEN
                     q = REAL(zpi) * dstar
                     IF( pow_qmin <= q .AND. q <= (pow_qmax+pow_deltaq) ) THEN
                        itth = int( (q - pow_qmin) / pow_deltaq )
                        inten = DBLE (csf (i) * conjg (csf (i) ) ) 
                        IF (pow_pref) then 
                           inten = inten * DBLE(calc_preferred (hkl,         &
                           pow_pref_type, pow_pref_hkl, pow_pref_g1,    &
                           pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH))  
                        ENDIF 
                        pow_qsp (itth) = pow_qsp (itth) + inten 
                     ENDIF 
                  ENDIF 
            ENDIF 
!DBG_RBN      write(13,4444) hkl,dstar,ttheta,csf(i),                   
!DBG_RBN     &                 real(csf(i)*conjg(csf(i))),              
!DBG_RBN     &               pow_l_all,l_hh_real,l_kk_real,l_ll_real,   
!DBG_RBN     &               pow_l_all .or. .not.pow_l_all .and.        
!DBG_RBN     &               (l_hh_real .or. l_kk_real .or. l_ll_real)  
! 4444 FORMAT    (3(2x,f5.1),f8.5,f8.3,2x,f12.6,f12.6,2x,f12.6,5(2x,l1)) 
            ENDDO 
            IF (l_twoparts) then 
!                                                                       
!     ----------Intersection with 2Theta min sphere, calculate          
!               second section along line                               
!                                                                       
               l_start = int( llstart2 / pow_hkl_del (3) )
               l_end = int( llend2 / pow_hkl_del (3) )
!DBG                write(17,'(2f12.4)') hkl(2),llstart2                
!DBG                write(17,'(2f12.4)') hkl(2),llend2                  
!DBG_RBN                                                                
!DBG      l_start = -6.0/pow_hkl_del(3)                                 
!DBG      l_end   =  6.0/pow_hkl_del(3)                                 
!DBG      l_start =  llstart2 /pow_hkl_del(3)                           
!DBG      l_end   =  llend2   /pow_hkl_del(3)                           
               eck (3, 1) = l_start * pow_hkl_del (3) 
               eck (3, 2) = l_end * pow_hkl_del (3) 
               eck (3, 3) = l_start * pow_hkl_del (3) 
               inc (1) = nint ( (eck (3, 2) - eck (3, 1) ) /            &
               pow_hkl_del (3) ) + 1                                    
               IF (inc (1) * inc (2) .gt. MAXQXY  .OR.          &
                   cr_nscat>DIF_MAXSCAT              ) THEN
                 n_qxy   = MAX(n_qxy,inc(1) * inc(2),MAXQXY)
                 n_nscat = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
                 n_natom = MAX(n_natom,cr_natoms,DIF_MAXAT)
                 CALL alloc_diffuse (n_qxy,  n_nscat,  n_natom )
                 IF (ier_num.ne.0) THEN
                   RETURN
                 ENDIF
               ENDIF
               IF (inc (1) .gt.MAXQXY) then 
                  ier_num = - 8 
                  ier_typ = ER_APPL 
                  WRITE (ier_msg (1), 8888) inc (1) 
                  WRITE (ier_msg (2), 8889) MAXQXY 
                  ier_msg (3) = 'Increase dl or adjust TTHMIN / TTHMAX' 
                  RETURN 
               ENDIF 
               IF (pow_four_mode.eq.POW_FOURIER) then 
                  IF (pow_four_vers.eq.POW_COMPL) then 
!DBG_RBN                                                                
                     CALL four_run 
                  ELSE 
                     CALL four_run_powder 
                  ENDIF 
               ELSEIF (pow_four_mode.eq.POW_STACK) then 
                  CALL st_fourier(rept_f2aver)
                  rept_f2aver = .false.   ! no further calculations needed
               ENDIF 
               DO i = 1, inc (1) 
               hkl (3) = eck (3, 1) + (i - 1) * vi (3, 1) 
               ll = hkl (3) 
               l_ll_real = abs ( (nint (ll) - ll) / pow_hkl_del (3) )   &
               .lt.0.51                                                 
               IF (pow_l_all.or..not.pow_l_all.and. (                   &
               l_hh_real.or.l_kk_real.or.l_ll_real) ) then              
                  dstar = sqrt (skalpro (hkl, hkl, cr_rten) ) 
                  IF(pow_axis==POW_AXIS_TTH) THEN
                  IF (rlambda * 0.5 * dstar.le.1.0) then 
                     ttheta = 2.0 * asind (rlambda * 0.5 * dstar) 
                     IF (pow_tthmin.le.ttheta.and.ttheta.le.(pow_tthmax+pow_deltatth))    &
                     then                                               
                        itth = int( (ttheta - pow_tthmin) / pow_deltatth )
                        inten = DBLE (csf (i) * conjg (csf (i) ) ) 
                        IF (pow_pref) then 
                           inten = inten * DBLE(calc_preferred (hkl,         &
                           pow_pref_type, pow_pref_hkl, pow_pref_g1,    &
                           pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH))  
                        ENDIF 
                        pow_qsp (itth) = pow_qsp (itth) + inten 
!DBG      write(18,'(2f12.4)') hkl(2),hkl(3)                            
                     ENDIF 
                  ENDIF 
                  ELSEIF(pow_axis==POW_AXIS_Q  ) THEN
                     q = REAL(zpi) * dstar
                     IF( pow_qmin <= q .AND. q <= (pow_qmax+pow_deltaq) ) THEN
                        itth = int( (q - pow_qmin) / pow_deltaq )
                        inten = DBLE (csf (i) * conjg (csf (i) ) ) 
                        IF (pow_pref) then 
                           inten = inten * DBLE(calc_preferred (hkl,         &
                           pow_pref_type, pow_pref_hkl, pow_pref_g1,    &
                           pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH))  
                        ENDIF 
                        pow_qsp (itth) = pow_qsp (itth) + inten 
                     ENDIF 
                  ENDIF 
               ENDIF 
!DBG_RBN      write(13,4444) hkl,dstar,ttheta,csf(i),                   
!DBG_RBN     &        real(csf(i)*conjg(csf(i))),                       
!DBG_RBN     &        pow_l_all,l_hh_real,l_kk_real,l_ll_real,          
!DBG_RBN     &        pow_l_all .or. .not.pow_l_all .and.               
!DBG_RBN     &        (l_hh_real .or. l_kk_real .or. l_ll_real)         
               ENDDO 
            ENDIF 
         ENDIF 
         ENDDO 
      ENDIF 
!DBG        close(15)                                                   
!DBG        close(16)                                                   
!DBG        close(17)                                                   
!DBG        close(18)                                                   
      ENDDO 
!
!     CALCULATE normalized average squared atomic form factor
!
      IF(calc_f2aver) THEN
         DO i=1,pow_npkt
            pow_f2aver(i) = pow_f2aver(i) / DBLE(pow_nreal)
            pow_faver2(i) = pow_faver2(i) / DBLE(pow_nreal)
         ENDDO
         pow_faver2(:) = pow_faver2(:)**2
         pow_u2aver = pow_u2aver / pow_nreal /8./REAL(pi**2)
      ENDIF
!                                                                       
      CALL dealloc_powder_nmax ! was allocated in powder_getatoms
!
!     Prepare and calculate average form factors
!
!      natom = 0
!      DO i=1,cr_natoms
!         natom(cr_iscat(i)) = natom(cr_iscat(i)) + 1
!      ENDDO
!      pow_nreal = SUM(natom)  ! Add real atom numbers 
!      CALL powder_f2aver ( cr_nscat , natom , cr_dw)
!
      ss = seknds (ss) 
      WRITE (output_io, 4000) ss 
!DBG_RBN      close(13)                                                 
!                                                                       
 4000 FORMAT     (/,' Elapsed time    : ',G12.6,' sec') 
 5000 FORMAT     (' Currently at H = ',f9.4,'   (dH = ',f9.4,           &
     &                   ', maxH = ',f9.4,')')                          
 8888 FORMAT    ('Current number = ',i10) 
 8889 FORMAT    ('Maximum number = ',i10) 
      END SUBROUTINE powder_complete                
!*****7*****************************************************************
      SUBROUTINE powder_debye_hist_cart (udist, cr_nscat_temp)
!-                                                                      
!     Calculate the powder pattern by using the Debye Formula according 
!     to Giacovacco                                                     
!     Histogram Version                                                 
!+                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE debye_mod 
      USE diffuse_mod 
      USE fourier_sup
      USE metric_mod
      USE output_mod 
      USE powder_mod 
      USE powder_tables_mod 
      USE wink_mod
!                                                                       
      USE prompt_mod 
      USE precision_mod 
      USE trig_degree_mod
      IMPLICIT none 
!                                                                       
      REAL,    INTENT(IN)  :: udist(3)
      INTEGER, INTENT(IN)  :: cr_nscat_temp
!                                                                       
      INTEGER, DIMENSION(0:cr_nscat_temp) :: natom ! (0:MAXSCAT) 
      INTEGER ibin 
      INTEGER j, k, l 
      INTEGER i, iscat, jscat 
      INTEGER(KIND=PREC_INT_LARGE) :: iarg, iadd 
      INTEGER                :: n_hist
      INTEGER                :: n_qxy   = 1
      INTEGER                :: n_nscat = 1
      INTEGER                :: n_natom = 1
      REAL                   :: distance
      REAL (PREC_DP) :: xstart, xdelta   ! start/step in dstar for sinthea/lambda table
      REAL ss, st
      REAL                   :: shift
      REAL   (KIND=PREC_DP), DIMENSION(:,:,:), ALLOCATABLE :: partial
      INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: histogram
      INTEGER, DIMENSION(:,:  ), ALLOCATABLE :: look
      REAL u (3), v (3) 
      REAL (KIND=PREC_DP) :: arg 
!                                                                       
      INTEGER IAND 
!     REAL skalpro 
!     REAL do_blen, sind 
!     REAL sind 
      REAL seknds 
!                                                                       
      n_qxy   = 1
      n_nscat = 1
      n_natom = 1
      ier_num = 0 
!DBG      write (output_io,*) ' cr_nscat ',cr_nscat                     
!                                                                       
!------ preset some values                                              
!                                                                       
      num (1) = 1021 
      num (2) = 1 
      DO i = 1, 3 
      u (i) = 0.0 
      v (i) = 0.0 
      xm (i) = 0.0 
      uin (i) = 0.0 
      vin (i) = 0.0 
      ENDDO 
      IF (pow_axis.eq.POW_AXIS_DSTAR) then 
         CONTINUE 
      ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
         u (1) = 1.00 
         xm (1) = pow_qmin / REAL(zpi)
         ss = pow_qmax / REAL(zpi) 
         st = (pow_qmax - pow_deltaq) / REAL(zpi )
         uin (1) = pow_deltaq / REAL(zpi )
         num (1) = nint ( (ss - xm (1) ) / uin (1) ) + 1 
      ELSEIF (pow_axis.eq.POW_AXIS_TTH) then 
         u (1) = 1.00 
         xm (1) = 2 * sind (0.5 * pow_tthmin) / rlambda 
         ss = 2 * sind (0.5 *  pow_tthmax                 ) / rlambda 
         st = 2 * sind (0.5 * (pow_tthmax - pow_deltatth) ) / rlambda 
         uin (1) = (ss - st) / 2. 
         num (1) = nint ( (ss - xm (1) ) / uin (1) ) + 1 
      ENDIF 
!DBG      write(*,*) ' XM  ',xm(1)                                      
!DBG      write(*,*) ' SS  ',ss                                         
!DBG      write(*,*) ' ST  ',st                                         
!DBG      write(*,*) ' UIN ',uin(1)                                     
!DBG      write(*,*) ' NUM ',num(1)                                     
!
!    Allocate arrays
!
      n_qxy    = num (1) * num (2) + 1
      distance = sqrt(udist(1)**2+udist(2)**2+udist(3)**2)
      n_hist   = nint(distance/pow_del_hist) + 2
!     n_qxy   = MAX(n_qxy,num(1) * num(2),MAXQXY,MAXDQXY)
      n_nscat = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
      n_natom = MAX(n_natom,cr_natoms,DIF_MAXAT)
      IF (num (1) * num (2) .gt. MAXQXY  .OR.          &
          num (1) * num (2) .gt. MAXDQXY .OR.          &
          cr_nscat>DIF_MAXSCAT              ) THEN
         CALL alloc_diffuse (n_qxy,  n_nscat,  n_natom )
      ENDIF
      CALL alloc_debye  (cr_nscat, n_hist, n_qxy, MASK )
!     IF(pow_axis == POW_AXIS_Q ) THEN
!        n_qxy = NINT((pow_qmax  -pow_qmin  )/pow_deltaq  ) + 1
!     ELSEIF(pow_axis == POW_AXIS_TTH ) THEN
!        n_qxy = NINT((pow_tthmax-pow_tthmin)/pow_deltatth) + 1
!     ENDIF
      CALL alloc_powder (n_qxy                   )
!                                                                       
!     prepare loopuptable for atom types
!                                                                       
      ALLOCATE(look     (1:cr_nscat,1:cr_nscat))
      look  = 0
      nlook = 0 
      DO i = 1, cr_nscat 
      DO j = i, cr_nscat 
      nlook = nlook + 1 
      look (i, j) = nlook 
      look (j, i) = nlook 
      ENDDO 
      ENDDO 
!
      ALLOCATE(partial  (1:num(1)*num(2),1:nlook,0:0))
      ALLOCATE(histogram(0:n_hist       ,1:nlook,0:0))
!                                                                       
!------ zero some arrays                                                
!                                                                       
!     DO i = 1, num (1) * num (2) 
!     DO j = 1, nlook 
!     partial (i, j,0) = 0.0 
!     ENDDO 
!     rsf (i) = 0.0 
!     ENDDO 
!     DO i = 0, MAXHIST 
!     DO j = 1, nlook 
!     histogram (i, j,0) = 0 
!     ENDDO 
!     ENDDO 
!     DO i = 0, cr_nscat 
!     natom (i) = 0 
!     ENDDO 
      partial(:,:,:)   = 0.0D0
      rsf(:)           = 0.0D0
      histogram(:,:,:) = 0
      natom            = 0 
!DBG                                                                    
!DBG      write(*,*) ' del_hist ',del_hist                              
!DBG      write(*,*) ' MAXHIST  ',MAXHIST                               
!DBG      write(*,*) ' rmax     ',MAXHIST*del_hist                      
!                                                                       
!------ preset some tables, calculate average structure                 
!                                                                       
      pow_npkt = n_qxy    ! set actual number of powder data points
      CALL powder_sinet 
      IF(pow_axis == POW_AXIS_Q ) THEN
         xstart = pow_qmin  /zpi
         xdelta = pow_deltaq/zpi
         CALL powder_stltab(n_qxy, xstart  ,xdelta    )   ! Really only needed for <f^2> and <f>^2 for F(Q) and S(Q)
      ELSEIF (pow_axis.eq.POW_AXIS_TTH) then 
         CALL powder_stltab(n_qxy, xm(1)   ,uin(1)    )   ! Really only needed for <f^2> and <f>^2 for F(Q) and S(Q)
      ENDIF
      IF (ier_num.ne.0) THEN
         DEALLOCATE(look   )
         DEALLOCATE(partial)
         DEALLOCATE(histogram)
         RETURN
      ENDIF
      CALL four_formtab 
!DBG                                                                    
      WRITE (output_io, * ) ' Starting histogram' 
      ss = seknds (0.0) 
!DBG      sss = seknds (0.0) 
!                                                                       
!     loop over all atoms                                               
!                                                                       
!-----Optimization notes
!     Omitting the error checks saves about 1/4 time
!     Replaced NINT by INT( + shift) this cuts the time in half!!!!
!     Omitting the SQRT only saves a little, as do the local variables
!     The if(iscat) do not cause much compute time

      shift = 0.5*pow_del_hist   ! Shift in blen position to avoid NINT function
      DO j = 1, cr_natoms ! - 1
         jscat = cr_iscat (j) 
         IF (jscat.gt.0) then 
         u (1) = cr_pos (1, j) 
         u (2) = cr_pos (2, j) 
         u (3) = cr_pos (3, j) 
!                                                                       
!     --- get info on relative amount of atoms                          
!                                                                       
         natom (jscat) = natom (jscat) + 1 
!                                                                       
!------ --- loop over all different atom types                          
!                                                                       
         DO l = j + 1, cr_natoms 
            iscat = cr_iscat (l) 
            IF (iscat.gt.0) then 
              v (1) = cr_pos (1, l) - u (1) 
              v (2) = cr_pos (2, l) - u (2) 
              v (3) = cr_pos (3, l) - u (3) 

!              ibin = nint (sqrt (v (1) **2 + v (2) **2 + v (3) **2)/ pow_del_hist)
               ibin =   int((sqrt (v (1) **2 + v (2) **2 + v (3) **2)+shift)/ pow_del_hist)
               histogram (ibin, look (jscat, iscat),0 ) = &
               histogram (ibin, look (jscat, iscat),0 ) + 1
            ENDIF 
         ENDDO 
         ENDIF 
      ENDDO 
!
!     pow_nreal = SUM(natom)  ! Add real atom numbers 
      pow_nreal = 0
      DO j=1,cr_nscat         ! Add real atom numbers
         pow_nreal = pow_nreal + NINT(natom(j)*cr_occ(j))
      ENDDO
!DBG      sss = seknds (sss) 
!DBG      WRITE (output_io, 4000) sss 
!
!     Check for entries in histogram (0,*,*) ==> atoms at distance ZERO
!
      i= 0
      DO j=1,nlook
         i = MAX(i, histogram(0,j,0))
      ENDDO
      IF(i > 0) THEN    ! Entries in histogram(0,*) exist, flag Error
         ier_num = -123
         ier_typ = ER_APPL
         DEALLOCATE(look   )
         DEALLOCATE(partial)
         DEALLOCATE(histogram)
         RETURN
      ENDIF
!DBG_RBN                                                                
!DBG      write(*,*) ' Writing histogram'                               
!DBG      do i=1,nlook                                                  
!DBG        do j=1,MAXHIST                                              
!DBG          write(i+20,'(f8.3,2x,i15)') j*pow_del_hist,histogram(j,i) 
!DBG        ENDDO                                                       
!DBG      ENDDO                                                         
!                                                                       
!     --- Calculate the Fourier                                         
!                                                                       
!DBG_RBN                                                                
!DBG      write(*,*) ' Starting partial fourier'                        
!DBG      ss = seknds(0.0)                                              
      DO i = 1, nlook 
      DO j = 1, MAXHIST 
      IF (histogram (j, i,0) >  0) then 
         DO k = 1, num (1) * num (2) 
         arg = zpi * DBLE((j * pow_del_hist) * (xm (1) + (k - 1) * uin (1) ) )
!DBG              partial(k,i) = partial(k,i)+                          
!DBG     &                   histogram(j,i,0)*sin(arg)/arg                
         iarg = int( (j * pow_del_hist) * (xm (1) + (k - 1) * uin (1) ) * I2PI )
         iadd = IAND (iarg, MASK) 
         partial (k, i,0) = partial (k, i,0) + DBLE(histogram (j, i,0)) * sinetab ( &
         iadd) / arg                                                    
         ENDDO 
      ENDIF 
      ENDDO 
      ENDDO 
!                                                                       
!------ Multiply the partial structure factors with form factors,add    
!     to total sum                                                      
!                                                                       
!DBG_RBN                                                                
!DBG      write(*,*) ' Multiply by formfactors '                        
      DO i = 1, cr_nscat 
      DO j = i, cr_nscat 
      DO k = 1, num (1) * num (2) 
      rsf (k) = rsf (k) + 2.0D0 * partial (k, look (i, j),0 ) * ( &
         DBLE(cfact (powder_istl (k), i) ) * DBLE(cfact (powder_istl (k), j) ) + &
        aimag(cfact (powder_istl (k), i) ) * aimag (cfact (powder_istl (k), j) ) )            
      ENDDO 
      ENDDO 
      ENDDO 
!                                                                       
!                                                                       
!     add the f**2 weighted by relative amount to intensity             
!     store <f**2> and <f>**2
!                                                                       
!DBG_RBN                                                                
!DBG      write(*,*) ' Add f**2 '                                       
!     pow_u2aver = 0.0
      DO iscat = 1, cr_nscat 
      DO i = 1, num (1) * num (2) 
      rsf (i) = rsf (i) + DBLE (cfact (powder_istl (i), iscat) * &
                         conjg (cfact (powder_istl (i), iscat) ) ) * natom (iscat)
!     pow_f2aver (i) = pow_f2aver (i)  + &
!                      real (       cfact_pure(istl(i), iscat)  * &
!                            conjg (cfact_pure(istl(i), iscat)))  &
!                    * natom (iscat)/pow_nreal
!     pow_faver2 (i) = pow_faver2 (i) +  &
!                 SQRT(real (       cfact_pure(istl(i), iscat)  * &
!                            conjg (cfact_pure(istl(i), iscat)))) &
!                    * natom (iscat)/pow_nreal
      ENDDO 
!        pow_u2aver = pow_u2aver + cr_dw(iscat)
      ENDDO 
!     pow_u2aver = pow_u2aver /8./pi**2
!
!      CALL powder_f2aver ( cr_nscat , natom , cr_dw)
!
      DEALLOCATE(look   )
      DEALLOCATE(partial)
      DEALLOCATE(histogram)
      ss = seknds (ss) 
      WRITE (output_io, 4000) ss 

!OPEN(88,file='rsf.inte')
!do i=1,num(1)*num(2)
!write(88,*) i,rsf(i)
!enddo
!close(88)
!                                                                       
 4000 FORMAT     (/,' Elapsed time    : ',G12.6,' sec') 
      END SUBROUTINE powder_debye_hist_cart         
!*****7*****************************************************************
      SUBROUTINE powder_debye_hist_cart_mole(udist, cr_nscat_temp, &
                 do_mol, powder_nmol)
!-                                                                      
!     Calculate the powder pattern by using the Debye Formula according 
!     to Giacovacco                                                     
!     Histogram Version                                                 
!+                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE debye_mod 
      USE diffuse_mod 
      USE fourier_sup
      USE metric_mod
      USE molecule_mod
      USE output_mod 
      USE powder_mod 
      USE powder_tables_mod 
      USE wink_mod
!                                                                       
      USE prompt_mod 
      USE precision_mod 
      USE trig_degree_mod
      IMPLICIT none 
!                                                                       
      REAL,    INTENT(IN)  :: udist(3)
      INTEGER, INTENT(IN)  :: cr_nscat_temp
      LOGICAL, INTENT(IN)  :: do_mol      ! Molecules with Biso /= 0.0
      INTEGER, INTENT(IN)  :: powder_nmol ! Number of look up dimensions molecules
!                                                                       
      INTEGER, DIMENSION(0:cr_nscat_temp) :: natom ! (0:MAXSCAT) 
      INTEGER ibin 
      INTEGER j, k, l , il
      INTEGER i, iscat, jscat 
      INTEGER(KIND=PREC_INT_LARGE) :: iarg, iadd 
      INTEGER                :: n_hist
      INTEGER                :: n_qxy   = 1
      INTEGER                :: n_nscat = 1
      INTEGER                :: n_natom = 1
      INTEGER                :: nlook_mol   ! Number of look up dimensions molecules
      INTEGER                :: islook      ! Actual molecule look up number
      INTEGER, DIMENSION(:,:), ALLOCATABLE :: powder_look_mol
      REAL   , DIMENSION(:)  , ALLOCATABLE :: powder_bvalue_mole
      REAL   , DIMENSION(:,:), ALLOCATABLE :: pow_dw
      REAL   , DIMENSION(:,:,:), ALLOCATABLE :: partial
      INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: histogram
      INTEGER, DIMENSION(:,:  ), ALLOCATABLE :: look
      REAL                   :: distance
      REAL (PREC_DP) :: xstart, xdelta   ! start/step in dstar for sinthea/lambda table
      REAL ss, st
      REAL                   :: shift
      REAL u (3), v (3) 
      REAL (KIND=PREC_DP) :: arg 
!                                                                       
      INTEGER IAND 
!     REAL sind 
      REAL seknds 
!                                                                       
      n_qxy   = 1
      n_nscat = 1
      n_natom = 1
      ier_num = 0 
!                                                                       
!------ preset some values                                              
!                                                                       
      num (1) = 1021 
      num (2) = 1 
!------ Reset arrays
      u     = 0.0 
      v     = 0.0 
      xm    = 0.0 
      uin   = 0.0 
      vin   = 0.0 
!
      IF (pow_axis.eq.POW_AXIS_DSTAR) then 
         CONTINUE 
      ELSEIF (pow_axis.eq.POW_AXIS_Q) then 
         u (1) = 1.00 
         xm (1) = pow_qmin / REAL(zpi) 
         ss = pow_qmax / REAL(zpi) 
         st = (pow_qmax - pow_deltaq) / REAL(zpi) 
         uin (1) = pow_deltaq / REAL(zpi) 
         num (1) = nint ( (ss - xm (1) ) / uin (1) ) + 1 
      ELSEIF (pow_axis.eq.POW_AXIS_TTH) then 
         u (1) = 1.00 
         xm (1) = 2 * sind (0.5 * pow_tthmin) / rlambda 
         ss = 2 * sind (0.5 *  pow_tthmax                 ) / rlambda 
         st = 2 * sind (0.5 * (pow_tthmax - pow_deltatth) ) / rlambda 
         uin (1) = (ss - st) / 2. 
         num (1) = nint ( (ss - xm (1) ) / uin (1) ) + 1 
      ENDIF 
!
!     Lay out look_up table for molecule entries
!
      IF(ALLOCATED(powder_look_mol)) DEALLOCATE(powder_look_mol)
      ALLOCATE(powder_look_mol(0:mole_num_type,0:mole_num_type))
      IF(ALLOCATED(powder_bvalue_mole)) DEALLOCATE(powder_bvalue_mole)
      ALLOCATE(powder_bvalue_mole(0:powder_nmol))
      powder_look_mol    = 0
      powder_bvalue_mole = 0.0
      nlook_mol          = 0
      IF(powder_nmol>0) THEN    ! Non-zero molecular bvalues
         DO i=1,mole_num_type   ! First part biso for single molecule
            powder_look_mol(0,i) = i
            powder_look_mol(i,0) = i
            powder_bvalue_mole(i) = mole_biso(i)
         ENDDO
         nlook_mol = mole_num_type
         DO i=1,mole_num_type   !Second part biso for two molecules
            DO j = i,mole_num_type
               nlook_mol            = nlook_mol + 1
               powder_look_mol(i,j) = nlook_mol
               powder_look_mol(j,i) = nlook_mol
               powder_bvalue_mole(nlook_mol) = mole_biso(i) + mole_biso(j)
            ENDDO
         ENDDO
      ENDIF
!
!    Allocate arrays
!
      n_qxy    = num (1) * num (2) + 1
      distance = sqrt(udist(1)**2+udist(2)**2+udist(3)**2)
      n_hist   = nint(distance/pow_del_hist) + 2
      n_qxy   = MAX(n_qxy,num(1) * num(2),MAXQXY,MAXDQXY)
      n_nscat = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
      n_natom = MAX(n_natom,cr_natoms,DIF_MAXAT)
      IF (num (1) * num (2) .gt. MAXQXY  .OR.          &
          num (1) * num (2) .gt. MAXDQXY .OR.          &
          cr_nscat>DIF_MAXSCAT              ) THEN
         CALL alloc_diffuse (n_qxy,  n_nscat,  n_natom )
      ENDIF
      CALL alloc_debye  (cr_nscat, n_hist, n_qxy, MASK )
!
      CALL alloc_powder (n_qxy                   )
      IF(ALLOCATED(pow_dw)) DEALLOCATE(pow_dw)
      ALLOCATE(pow_dw(0:CFPKT, 0:nlook_mol))
      pow_dw = 1.0
      IF(do_mol) THEN   ! If necessary calc Debye Waller terms for molecules
        CALL powder_dwmoltab (nlook_mol, pow_dw, powder_bvalue_mole)
      ENDIF
!                                                                       
!     prepare loopuptable for atom types
!                                                                       
      ALLOCATE(look     (1:cr_nscat,1:cr_nscat))
      look  = 0
      nlook = 0 
      DO i = 1, cr_nscat 
      DO j = i, cr_nscat 
      nlook = nlook + 1 
      look (i, j) = nlook 
      look (j, i) = nlook 
      ENDDO 
      ENDDO 
!
      ALLOCATE(partial  (1:num(1)*num(2),1:nlook,0:nlook_mol))
      ALLOCATE(histogram(0:n_hist       ,1:nlook,0:nlook_mol))
!                                                                       
!------ zero some arrays                                                
!                                                                       
      partial   = 0.0D0
      rsf       = 0.0D0
      histogram = 0 
      natom     = 0 
!                                                                       
!------ preset some tables, calculate average structure                 
!                                                                       
      pow_npkt = n_qxy    ! set actual number of powder data points
      CALL powder_sinet 
      IF(pow_axis == POW_AXIS_Q ) THEN
         xstart = pow_qmin  /zpi
         xdelta = pow_deltaq/zpi
         CALL powder_stltab(n_qxy, xstart  ,xdelta    )   ! Really only needed for <f^2> and <f>^2 for F(Q) and S(Q)
      ELSEIF (pow_axis.eq.POW_AXIS_TTH) then 
         CALL powder_stltab(n_qxy, xm(1)   ,uin(1)    )   ! Really only needed for <f^2> and <f>^2 for F(Q) and S(Q)
      ENDIF
      IF (ier_num.ne.0) return 
      CALL four_formtab 
!
      WRITE (output_io, * ) ' Starting histogram'
      ss = seknds (0.0) 
!
!                                                                       
!     loop over all atoms                                               
!                                                                       
!-----Optimization notes
!     Omitting the error checks saves about 1/4 time
!     Replaced NINT by INT( + shift) this cuts the time in half!!!!
!     Omitting the SQRT only saves a little, as do the local variables
!     The if(iscat) do not cause much compute time

      shift = 0.5*pow_del_hist   ! Shift in blen position to avoid NINT function
      DO j = 1, cr_natoms - 1
         jscat = cr_iscat(j) 
         IF (jscat.gt.0) then 
            u(1) = cr_pos(1,j) 
            u(2) = cr_pos(2,j) 
            u(3) = cr_pos(3,j) 
!                                                                       
!     --- get info on relative amount of atoms                          
!                                                                       
         natom (jscat) = natom (jscat) + 1 
!                                                                       
!------ --- loop over all different atom types                          
!                                                                       
         DO l = j + 1, cr_natoms 
            iscat = cr_iscat (l) 
            IF (iscat.gt.0) then 
              IF(cr_mole(j )==cr_mole(l)) THEN
                 islook = 0   ! Atoms are within the same molecule
              ELSE
                 islook = powder_look_mol(mole_type(cr_mole(j)),mole_type(cr_mole(l)))
              ENDIF
              v (1) = cr_pos (1, l) - u (1) 
              v (2) = cr_pos (2, l) - u (2) 
              v (3) = cr_pos (3, l) - u (3) 

!              ibin = nint (sqrt (v (1) **2 + v (2) **2 + v (3) **2)/ pow_del_hist)
               ibin =   int((sqrt (v (1) **2 + v (2) **2 + v (3) **2)+shift)/ pow_del_hist)
               histogram (ibin, look (jscat, iscat),islook ) = &
               histogram (ibin, look (jscat, iscat),islook ) + 1                                
            ENDIF 
         ENDDO 
         ENDIF 
      ENDDO 
!
!     Check for entries in histogram (0,*,*) ==> atoms at distance ZERO
!
      i= 0
      DO j=1,nlook
         i = MAX(i, histogram(0,j,0))
      ENDDO
      IF(i > 0) THEN    ! Entries in histogram(0,*) exist, flag Error
         ier_num = -123
         ier_typ = ER_APPL
         DEALLOCATE(look)
         DEALLOCATE(partial)
         DEALLOCATE(histogram)
         RETURN
      ENDIF
!                                                                       
!     --- Calculate the Fourier                                         
!                                                                       
      DO i = 1, nlook 
      DO j = 1, MAXHIST 
         DO il=0,nlook_mol
         IF (histogram (j, i,il) .gt.0) then 
         DO k = 1, num (1) * num (2) 
         arg  = zpi *DBLE((j * pow_del_hist) * (xm (1) + (k - 1) * uin (1) ) )
         iarg = int( (j * pow_del_hist) * (xm (1) + (k - 1) * uin (1) ) * I2PI )
         iadd = IAND (iarg, MASK) 
         partial(k,i,il) = partial(k,i,il) + REAL(DBLE(histogram(j,i,il)) * sinetab(iadd)/arg)
         ENDDO 
         ENDIF 
         ENDDO 
      ENDDO 
      ENDDO 
!
!                                                                       
!------ Multiply the partial structure factors with form factors,add    
!     to total sum                                                      
!                                                                       
      DO i = 1, cr_nscat 
         DO j = i, cr_nscat 
            DO k = 1, num (1) * num (2) 
               DO il=0,powder_nmol
                  rsf(k) = rsf (k) + 2.0D0 * partial (k, look (i, j),il ) *       &
                           (DBLE(cfact(powder_istl(k),i)) * DBLE (cfact(powder_istl(k),j)) +  &
                           aimag(cfact(powder_istl(k),i)) * aimag(cfact(powder_istl(k),j)))*  &
                           pow_dw(powder_istl(k),il)
               ENDDO 
            ENDDO 
         ENDDO 
      ENDDO 
!                                                                       
!                                                                       
!     add the f**2 weighted by relative amount to intensity             
!                                                                       
      DO iscat = 1, cr_nscat 
         DO i = 1, num (1) * num (2) 
            rsf(i) = rsf(i) + DBLE(cfact(powder_istl(i),iscat) * &
                             conjg(cfact(powder_istl(i),iscat))) * natom(iscat)
         ENDDO 
      ENDDO 
!
      DEALLOCATE(look)
      DEALLOCATE(partial)
      DEALLOCATE(histogram)
      ss = seknds (ss) 
      WRITE (output_io, 4000) ss 
!                                                                       
 4000 FORMAT     (/,' Elapsed time    : ',G12.6,' sec') 
      END SUBROUTINE powder_debye_hist_cart_mole
!*****7*****************************************************************
      SUBROUTINE powder_strucf (iscat, lform) 
!+                                                                      
!     Here the complex structure factor of 'nxat' identical atoms       
!     from array 'xat' is computed.                                     
!-                                                                      
      USE discus_config_mod 
      USE diffuse_mod 
      USE precision_mod
      IMPLICIT none 
!                                                                       
!                                                                       
      REAL(PREC_DP) xarg0, xincu, twopi 
      INTEGER iscat 
      INTEGER i, ii, j, k 
      INTEGER(KIND=PREC_INT_LARGE) :: iarg, iarg0, iincu, iadd 
      LOGICAL lform 
!                                                                       
      INTEGER IAND, ISHFT 
!                                                                       
      twopi = 8.0d0 * datan (1.0d0) 
!                                                                       
!------ zero fourier array                                              
!                                                                       
      DO i = 1, num (1) * num (2) 
         tcsf (i) = cmplx (0.0D0, 0.0D0, KIND=KIND(0.0D0)) 
      ENDDO 
!                                                                       
!------ Loop over all atoms in 'xat'                                    
!                                                                       
      DO k = 1, nxat 
      xarg0 = xm (1) * xat (k, 1) + xm (2) * xat (k, 2) + xm (3)        &
      * xat (k, 3)                                                      
      xincu = uin (1) * xat (k, 1) + uin (2) * xat (k, 2) + uin (3)     &
      * xat (k, 3)                                                      
!DBG        xincv = vin(1)*xat(k,1)+vin(2)*xat(k,2)+vin(3)*xat(k,3)     
!                                                                       
      iarg0 = nint (64 * I2PI * (xarg0 - int (xarg0) + 1.0d0) ) 
      iincu = nint (64 * I2PI * (xincu - int (xincu) + 1.0d0) ) 
!DBG        iincv = nint( 64*I2PI*( xincv-int(xincv)+1.0d0))            
      iarg = iarg0 
!                                                                       
!------ - Loop over all points in Q. 'iadd' is the address of the       
!------ - complex exponent table. 'IADD' divides out the 64 and         
!------ - ISHFT acts as MOD so that the argument stays in the table     
!------ - boundaries.                                                   
!                                                                       
      ii = 0 
!                                                                       
      DO j = 1, num (1) 
!DBG          do i=1,num(2)                                             
      iadd = ISHFT (iarg, - 6) 
      iadd = IAND (iadd, MASK) 
      ii = ii + 1 
      tcsf (ii) = tcsf (ii) + cex (iadd) / DBLE ( (xarg0 + float (j - 1)&
      * xincu) * twopi)                                                 
!DBG            iarg = iarg + iincv                                     
!DBG          ENDDO                                                     
      iarg = iarg0 + iincu * j 
      ENDDO 
      ENDDO 
!                                                                       
!------ Now we multiply with formfactor                                 
!                                                                       
      IF (lform) then 
         DO i = 1, num (1) * num (2) 
         tcsf (i) = tcsf (i) * cfact (istl (i), iscat) 
         ENDDO 
      ENDIF 
!                                                                       
      END SUBROUTINE powder_strucf                  
!*****7*****************************************************************
      SUBROUTINE powder_cexpt 
!+                                                                      
!     This routine initialises the complex exponent table and           
!     is called only at the first Powder run.                           
!-                                                                      
      USE discus_config_mod 
      USE diffuse_mod 
!                                                                       
      USE prompt_mod 
      USE precision_mod
      IMPLICIT none 
!                                                                       
      REAL(PREC_DP) twopi, xmult, xarg, xt 
      INTEGER i 
!                                                                       
      WRITE (output_io, 1000) 
!                                                                       
      xt = 1.0d0 / REAL (I2PI, KIND=KIND(0.0D0)) 
      twopi = 8.0d0 * datan (1.0d0) 
!                                                                       
!DBG      open(9,file='CEX.DAT',status='unknown')                       
      DO i = 0, MASK 
      xmult = float (i) * xt 
      xarg = twopi * xmult 
      cex (i) = cmplx (int( sin (xarg) ), 0.0) 
!DBG      write(9,*) xarg,real(cex(i))                                  
      ENDDO 
      ffour = .false. 
!DBG      close(9)                                                      
!                                                                       
 1000 FORMAT     (' Computing complex exponent table ...') 
      END SUBROUTINE powder_cexpt                   
!*****7*****************************************************************
!!      SUBROUTINE powder_sine_f (iscat, jscat) 
!+                                                                      
!     Here the real structure factor of 'nxat' identical atoms          
!     from array 'xat' is computed.                                     
!-                                                                      
!!      USE discus_config_mod 
!!      USE debye_mod 
!!      USE diffuse_mod 
!!      IMPLICIT none 
!                                                                       
!                                                                       
!!      REAL(PREC_DP) xarg0, xincu, twopi 
!!      INTEGER iscat, jscat 
!!      INTEGER i, ii, j, k, iarg, iarg0, iincu, iadd 
!                                                                       
!!      INTEGER IAND, ISHFT 
!                                                                       
!!      twopi = 8.0d0 * datan (1.0d0) 
!                                                                       
!------ zero fourier array                                              
!                                                                       
!!      DO i = 1, num (1) * num (2) 
!!      tcsf (i) = cmplx (0.0, 0.0) 
!!      ENDDO 
!                                                                       
!------ Loop over all atoms in 'xat'                                    
!                                                                       
!!      DO k = 1, nxat 
!!      xarg0 = xm (1) * xat (k, 1) + xm (2) * xat (k, 2) + xm (3)        &
!!      * xat (k, 3)                                                      
!!      xincu = uin (1) * xat (k, 1) + uin (2) * xat (k, 2) + uin (3)     &
!!      * xat (k, 3)                                                      
!DBG        xincv = vin(1)*xat(k,1)+vin(2)*xat(k,2)+vin(3)*xat(k,3)     
!                                                                       
!!      iarg0 = nint (64 * I2PI * (xarg0 - int (xarg0) + 1.0d0) ) 
!!      iincu = nint (64 * I2PI * (xincu - int (xincu) + 1.0d0) ) 
!DBG        iincv = nint( 64*I2PI*( xincv-int(xincv)+1.0d0))            
!!      iarg = iarg0 
!                                                                       
!------ - Loop over all points in Q. 'iadd' is the address of the       
!------ - complex exponent table. 'IADD' divides out the 64 and         
!------ - ISHFT acts as MOD so that the argument stays in the table     
!------ - boundaries.                                                   
!                                                                       
!!      ii = 0 
!                                                                       
!!      DO j = 1, num (1) 
!DBG          do i=1,num(2)                                             
!!      iadd = ISHFT (iarg, - 6) 
!!      iadd = IAND (iadd, MASK) 
!!      ii = ii + 1 
!!      partial (ii, look (iscat, jscat),0 ) = partial (ii, look (iscat,    &
!!      jscat),0 ) + sinetab (iadd) / real ( (xarg0 + float (j - 1) * xincu)&
!!      * twopi)                                                          
!DBG            iarg = iarg + iincv                                     
!DBG          ENDDO                                                     
!!      iarg = iarg0 + iincu * j 
!!      ENDDO 
!!      ENDDO 
!                                                                       
!!      END SUBROUTINE powder_sine_f                  
!*****7*****************************************************************
      SUBROUTINE powder_getatm (iscat, i_start) 
!+                                                                      
!     This routine creates an atom list of atoms of type 'iscat'        
!     which are within the current lot.                                 
!-                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE diffuse_mod 
      USE metric_mod
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER iscat, i_start 
      INTEGER i, j 
      REAL u (3), v (3) 
!                                                                       
!     REAL do_blen 
!                                                                       
      nxat = 0 
!                                                                       
      DO i = i_start + 1, cr_natoms 
      IF (cr_iscat (i) .eq.iscat) then 
         nxat = nxat + 1 
         DO j = 1, 3 
         u (j) = cr_pos (j, i_start) 
         v (j) = cr_pos (j, i) 
         xat (nxat, j) = 0.0 
         ENDDO 
         xat (nxat, 1) = do_blen (.true., u, v) 
      ENDIF 
      ENDDO 
      END SUBROUTINE powder_getatm                  
!*****7*****************************************************************
      SUBROUTINE four_run_powder 
!+                                                                      
!     claculates the Fourier, complete mode                             
!-                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE diffuse_mod 
      USE four_strucf_mod
      USE fourier_sup
!                                                                       
      USE prompt_mod 
      IMPLICIT none 
       
!                                                                       
      INTEGER lbeg (3), csize (3) 
      INTEGER iscat, i 
!                                                                       
      ier_num = 0 
      csize (1) = cr_icc (1) 
      csize (2) = cr_icc (2) 
      csize (3) = cr_icc (3) 
!                                                                       
!------ preset some values                                              
!                                                                       
      CALL four_layer 
!                                                                       
!------ zero some arrays                                                
!                                                                       
      DO i = 1, num (1) * num (2) 
         csf (i) = cmplx (0.0D0, 0.0D0, KIND=KIND(0.0D0)) 
!DBG        acsf(i) = cmplx(0.0d0,0.0d0)                                
!DBG         dsi(i) = 0.0d0                                             
      ENDDO 
!                                                                       
!------ preset some tables, calculate average structure                 
!                                                                       
      CALL four_stltab 
!DBG      call four_formtab                                             
      IF (ier_num.ne.0) return 
      lbeg (1) = 1 
      lbeg (2) = 1 
      lbeg (3) = 1 
!                                                                       
!------ - loop over all different atom types                            
!                                                                       
      DO iscat = 1, cr_nscat 
!DBG        call four_getatm (iscat,ilots,lbeg,csize,ncell)             
!DBG        call four_strucf (iscat,.true.)                             
      CALL powder_strucfactor (iscat, .true.) 
!                                                                       
!------ --- Add this part of the structur factor to the total           
!                                                                       
      DO i = 1, num (1) * num (2) 
      csf (i) = csf (i) + tcsf (i) 
      ENDDO 
      ENDDO 
!                                                                       
      END SUBROUTINE four_run_powder                
!*****7*****************************************************************
      SUBROUTINE powder_getatoms 
!+                                                                      
!     sorts all atoms by scattering type                                
!                                                                       
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE powder_scat_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER i, j 
      INTEGER iscat 
!
      CALL alloc_powder_nmax(MAXSCAT, cr_natoms) ! will automatically be deallocated 
!
      DO j = 1, cr_nscat 
         pow_nscat (j) = 0 
      ENDDO 
      DO i = 1, cr_natoms 
         iscat = cr_iscat (i) 
         IF (iscat.gt.0) then 
            pow_nscat (iscat) = pow_nscat (iscat) + 1 
            pow_iatom (iscat, pow_nscat (iscat) ) = i 
         ENDIF 
      ENDDO 
!                                                                       
      END SUBROUTINE powder_getatoms                
!*****7*****************************************************************
      SUBROUTINE powder_strucfactor (iscat, lform) 
!+                                                                      
!     Here the complex structure factor of 'nxat' identical atoms       
!     from array 'xat' is computed.                                     
!-                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE diffuse_mod 
      USE powder_scat_mod 
      USE precision_mod
      IMPLICIT none 
!                                                                       
       
!                                                                       
      REAL(PREC_DP) xarg0, xincu, xincv 
      INTEGER iscat 
      INTEGER i, ii, j, k
      INTEGER(KIND=PREC_INT_LARGE) :: iarg, iarg0, iincu, iincv, iadd 
      LOGICAL lform 
!                                                                       
      INTEGER IAND, ISHFT 
!                                                                       
!------ zero fourier array                                              
!                                                                       
!DBGXXX      do i=1,num(1)*num(2)                                       
      DO i = 1, num (1) 
         tcsf (i) = cmplx (0.0D0, 0.0D0, KIND=KIND(0.0D0)) 
      ENDDO 
!                                                                       
!------ Loop over all atoms in 'xat'                                    
!                                                                       
      DO k = 1, pow_nscat (iscat) 
      xarg0 = xm (1) * cr_pos (1, pow_iatom (iscat, k) ) + xm (2)       &
      * cr_pos (2, pow_iatom (iscat, k) ) + xm (3) * cr_pos (3,         &
      pow_iatom (iscat, k) )                                            
      xincu = uin (1) * cr_pos (1, pow_iatom (iscat, k) ) + uin (2)     &
      * cr_pos (2, pow_iatom (iscat, k) ) + uin (3) * cr_pos (3,        &
      pow_iatom (iscat, k) )                                            
      xincv = vin (1) * cr_pos (1, pow_iatom (iscat, k) ) + vin (2)     &
      * cr_pos (2, pow_iatom (iscat, k) ) + vin (3) * cr_pos (3,        &
      pow_iatom (iscat, k) )                                            
!                                                                       
      iarg0 = nint (64 * I2PI * (xarg0 - int (xarg0) + 1.0d0) ) 
      iincu = nint (64 * I2PI * (xincu - int (xincu) + 1.0d0) ) 
      iincv = nint (64 * I2PI * (xincv - int (xincv) + 1.0d0) ) 
      iarg = iarg0 
!                                                                       
!------ - Loop over all points in Q. 'iadd' is the address of the       
!------ - complex exponent table. 'IADD' divides out the 64 and         
!------ - ISHFT acts as MOD so that the argument stays in the table     
!------ - boundaries.                                                   
!                                                                       
      ii = 0 
!                                                                       
      DO j = 1, num (1) 
!DBGXXX          do i=1,num(2)                                          
      iadd = ISHFT (iarg, - 6) 
      iadd = IAND (iadd, MASK) 
      ii = ii + 1 
      tcsf (ii) = tcsf (ii) + cex (iadd) 
      iarg = iarg + iincv 
!DBGXXX          ENDDO                                                  
      iarg = iarg0 + iincu * j 
      ENDDO 
      ENDDO 
!                                                                       
!------ Now we multiply with formfactor                                 
!                                                                       
      IF (lform) then 
!DBGXXX        do i=1,num(1)*num(2)                                     
         DO i = 1, num (1) 
         tcsf (i) = tcsf (i) * cfact (istl (i), iscat) 
         ENDDO 
      ENDIF 
!                                                                       
      END SUBROUTINE powder_strucfactor             
!*****7*****************************************************************
      REAL function calc_preferred (w, pow_pref_type, pow_pref_hkl,     &
      pow_pref_g1, pow_pref_g2, POW_PREF_RIET, POW_PREF_MARCH)          
!+                                                                      
!     Here the complex structure factor of 'nxat' identical atoms       
!     from array 'xat' is computed.                                     
!-                                                                      
      USE metric_mod
      USE trig_degree_mod
      IMPLICIT none 
!                                                                       
      REAL w (3) 
      INTEGER pow_pref_type 
      REAL pow_pref_hkl (3) 
      REAL pow_pref_g1 
      REAL pow_pref_g2 
      INTEGER POW_PREF_RIET 
      INTEGER POW_PREF_MARCH 
!                                                                       
      LOGICAL lspace 
      REAL null (3) 
      REAL :: alpha   = 0.0
      REAL :: alpha2  = 0.0
!     REAL do_bang 
!     REAL sind 
!     REAL cosd 
!                                                                       
      null (1) = 0.0 
      null (2) = 0.0 
      null (3) = 0.0 
      lspace = .true. 
!                                                                       
      calc_preferred = 1.0 
!                                                                       
      alpha = do_bang (lspace, w, null, pow_pref_hkl) 
      IF (pow_pref_type.eq.POW_PREF_RIET) then 
         IF (alpha.le.90.) then 
            alpha2 = alpha**2 
         ELSE 
            alpha2 = (180 - alpha) **2 
         ENDIF 
         calc_preferred = pow_pref_g2 + (1. - pow_pref_g2) * exp (      &
         pow_pref_g1 * alpha2)                                          
      ELSEIF (pow_pref_type.eq.POW_PREF_MARCH) then 
         calc_preferred = pow_pref_g2 + (1. - pow_pref_g2) * ( (        &
         pow_pref_g1 * cosd (alpha) ) **2 + (sind (alpha) ) **2 /       &
         pow_pref_g1) ** ( - 1.5)                                       
      ENDIF 
!     write(*,'(3f4.0,2x,f10.2,2x,f10.2,2x,f8.5)') w,alpha,alpha2,  &
!                calc_preferred                                     
      END FUNCTION calc_preferred                   
!*****7*****************************************************************
      SUBROUTINE proj_preferred (w, pow_pref_hkl) 
!+                                                                      
!                                                                       
!-                                                                      
      USE metric_mod
      USE discus_config_mod 
      USE crystal_mod 
      USE param_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      REAL w (3) 
      REAL pow_pref_hkl (3) 
!                                                                       
      INTEGER i 
      LOGICAL lspace 
      REAL null (3) 
      REAL uv, uu, vv 
!     REAL skalpro 
!                                                                       
      null (1) = 0.0 
      null (2) = 0.0 
      null (3) = 0.0 
      lspace = .true. 
!                                                                       
!                                                                       
!     ------Calculate projection onto second vector, always in          
!             direct space                                              
!                                                                       
      uv = skalpro (w, pow_pref_hkl, cr_gten) 
      uu = skalpro (w, pow_pref_hkl, cr_gten) 
      vv = skalpro (w, pow_pref_hkl, cr_gten) 
      IF (vv.eq.0.0) then 
         w (1) = 0.0 
         w (2) = 0.0 
         w (3) = 0.0 
         RETURN 
      ENDIF 
      DO i = 1, 3 
      w (i) = pow_pref_hkl (i) * uv / vv 
      ENDDO 
                                                                        
      RETURN 
      END SUBROUTINE proj_preferred                 
!*****7*****************************************************************
      SUBROUTINE powder_trans_atoms_tocart (uvw_out)
!-                                                                      
!     transforms atom coordinates into a cartesian space                
!     Warning, only the fractional coordinates are transformed,         
!     the unit cell and space group information is not touched.         
!+                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE discus_plot_mod 
      USE trans_sup_mod
      IMPLICIT none 
!                                                                       
      REAL ,DIMENSION(1:3), INTENT(OUT) :: uvw_out !(3)
!
      INTEGER              ::  i
      LOGICAL, PARAMETER   :: lscreen = .false. 
      REAL, DIMENSION(1:4) :: uvw
      REAL             :: xmin
      REAL             :: xmax
      REAL             :: ymin
      REAL             :: ymax
      REAL             :: zmin
      REAL             :: zmax
!                                                                       
      xmin = 0.0
      xmax = 0.0
      ymin = 0.0
      ymax = 0.0
      zmin = 0.0
      zmax = 0.0
      uvw(4) = 1.0
!         
      DO i = 1, cr_natoms 
         uvw (1) = cr_pos (1, i) 
         uvw (2) = cr_pos (2, i) 
         uvw (3) = cr_pos (3, i) 
         CALL tran_ca (uvw, pl_tran_f, lscreen) 
         cr_pos (1, i) = uvw (1) 
         cr_pos (2, i) = uvw (2) 
         cr_pos (3, i) = uvw (3) 
         xmin = MIN(xmin,uvw(1))
         xmax = MAX(xmax,uvw(1))
         ymin = MIN(ymin,uvw(2))
         ymax = MAX(ymax,uvw(2))
         zmin = MIN(zmin,uvw(3))
         zmax = MAX(zmax,uvw(3))
      ENDDO
      uvw_out (1) = ABS(xmax-xmin)
      uvw_out (2) = ABS(ymax-ymin)
      uvw_out (3) = ABS(zmax-zmin) 
!                                                                       
      END SUBROUTINE powder_trans_atoms_tocart      
!*****7*****************************************************************
      SUBROUTINE powder_trans_atoms_fromcart 
!-                                                                      
!     transforms atom coordinates from a cartesian space back           
!     to the original coordinates                                       
!     Warning, only the fractional coordinates are transformed,         
!     the unit cell and space group information is not touched.         
!+                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE discus_plot_mod 
      USE trans_sup_mod
      IMPLICIT none 
!                                                                       
      INTEGER              :: i 
      LOGICAL, PARAMETER   :: lscreen = .false.
!                                                                       
      REAL, DIMENSION(1:4) ::  uvw !(4) 
!                                                                       
!                                                                       
      uvw(4) = 1.0
      DO i = 1, cr_natoms 
         uvw (1) = cr_pos (1, i) 
         uvw (2) = cr_pos (2, i) 
         uvw (3) = cr_pos (3, i) 
         CALL tran_ca (uvw, pl_tran_fi, lscreen) 
         cr_pos (1, i) = uvw (1) 
         cr_pos (2, i) = uvw (2) 
         cr_pos (3, i) = uvw (3) 
      ENDDO 
!                                                                       
      END SUBROUTINE powder_trans_atoms_fromcart    
!*****7*****************************************************************
      SUBROUTINE powder_dwmoltab (nlook_mol, pow_dw, powder_bvalue_mole)
!+                                                                      
!     This routine sets up the complex formfactor lookup table          
!     for all atom types. The range in sin(theta)/lambda is             
!     0 -> 2 in steps of 0.001. These values can be changed             
!     in the 'diffuse_mod.f90' file.                                        
!-                                                                      
      USE discus_config_mod 
      USE crystal_mod 
      USE diffuse_mod 
!                                                                       
      USE prompt_mod 
      IMPLICIT none 
!
      INTEGER,                                 INTENT(IN)  :: nlook_mol
      REAL   , DIMENSION(0:CFPKT,0:nlook_mol), INTENT(OUT) :: pow_dw
      REAL   , DIMENSION(0:nlook_mol)        , INTENT(IN ) :: powder_bvalue_mole
!                                                                       
      REAL    :: q2
      INTEGER :: iq, iscat 
!
!      IF (four_log) then 
         WRITE (output_io, 1000) 
!      ENDIF 
!                                                                       
      DO iscat = 0, nlook_mol 
         DO iq = 0, CFPKT 
            q2 = (float (iq) * REAL(CFINC)) **2 
!
            IF (powder_bvalue_mole(iscat)>0.0) then 
               pow_dw (iq, iscat) = exp ( - powder_bvalue_mole ( iscat ) * q2) 
            ELSE 
               pow_dw (iq, iscat) = 1.0
            ENDIF 
!
         ENDDO 
      ENDDO 
!                                                                       
 1000 FORMAT     (' Computing Molecular DW lookup table ...') 
      END SUBROUTINE powder_dwmoltab                   
END MODULE powder
