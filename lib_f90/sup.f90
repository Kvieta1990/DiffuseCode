!****7***************************************************************** 
!                                                                       
!     This file contains several subroutines for command language       
!     handling and other common support routines.                       
!                                                                       
!*****7*****************************************************************
SUBROUTINE cmdline_args (local_mpi_myid)
!                                                                       
!     This routine checks for command line arguments and                
!     executes given macros ..                                          
!                                                                       
      USE prompt_mod 
      USE debug_mod 
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
      INTEGER, INTENT(IN) :: local_mpi_myid
!                                                                       
      INTEGER marg 
      PARAMETER (marg = 20) 
!                                                                       
      CHARACTER(1024) arg (marg) 
      CHARACTER(LEN=2048)  :: line = ' '
      CHARACTER(40) str 
      INTEGER iarg, i, ilen , ilena
      INTEGER len_str 
!                                                                       
      CALL do_getargs (iarg, arg, marg) 
      IF (iarg.gt.0) THEN 
         IF (index (arg (1) , '-macro') .ne. 0) THEN ! execute a macro with optional parameters
            IF (iarg.gt.1) THEN 
               ilena = len_str(arg(2)) ! arg2 is the actual macro name
               IF(iarg > 2) THEN       ! There are macro parameter(s)
                  line  = arg(2)(1:ilena) // ' '
                  ilen  = ilena + 1
               ELSE                    ! No macro parameters follow
                  line  = arg(2)(1:ilena)
                  ilen  = ilena
               ENDIF
               DO i = 3, iarg          ! all further args are macro parameters
                 ilena = len_str(arg(i))
                 line  = line(1:ilen) // arg(i)(1:ilena)
                 ilen  = ilen + ilena
                  IF ( i.lt. iarg) THEN ! seperate all but last by ','
                     line = line(1:ilen) // ','
                     ilen = ilen + 1
                  ENDIF
               ENDDO
               IF(local_mpi_myid==0) WRITE ( *, 1000) line (1:ilen)
               CALL file_kdo(line(1:ilen), ilen) ! Execute macro and return to normal prompt
            ENDIF
         ELSE ! all other command line arguments
            DO i = 1, iarg 
            IF (index (arg (i) , '-remote') .ne.0) THEN 
               lsocket = .true. 
            ELSEIF (index (arg (i) , '-port') .ne.0) THEN 
               str = arg (i) (index (arg (i) , '=') + 1:len_str (arg (i) ))
               READ (str, * ) s_port 
            ELSEIF (index (arg (i) , '-access') .ne.0) THEN 
               s_ipallowed = arg (i) (index (arg(i),'=')+1:len_str(arg(i)))
            ELSEIF (index (arg (i) , '-help') .ne.0) THEN 
               IF(local_mpi_myid==0) WRITE ( *, 2000) pname (1:len_str (pname) ) 
            ELSEIF (index (arg (i) , '-debug') .ne.0) THEN 
               IF(local_mpi_myid==0) WRITE ( *, 1500) 
               dbg = .true. 
            ELSE         ! several macros WITHOUT parameters
               ilen = len_str (arg (i) ) 
               IF(local_mpi_myid==0) WRITE ( *, 1000) arg (i) (1:ilen) 
               CALL file_kdo (arg (i) (1:ilen), ilen) 
            ENDIF 
            ENDDO 
         ENDIF
         IF (lsocket) call remote_init 
      ENDIF 
!                                                                       
 1000 FORMAT     (' ------ > Reading macro ',a) 
 1500 FORMAT     (' ------ > Running in debug mode ..') 
 2000 FORMAT     (' Usage: ',a,' [-remote] [-debug] [-port=p]',         &
     &                   ' [-access=ip]')                               
      END SUBROUTINE cmdline_args                   
!*****7*****************************************************************
      SUBROUTINE remote_init 
!                                                                       
!     This initializes the remote communication via SOCKETS             
!                                                                       
      USE debug_mod 
      USE envir_mod 
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      LOGICAL llocal 
      INTEGER socket_init
!                                                                       
      llocal = (s_ipallowed.eq.'localhost') 
      llocal = llocal.or. (s_ipallowed.eq.'127.0.0.1') 
!                                                                       
      WRITE (output_io, 2000) 
      ier_num = socket_init (s_sock, s_port, llocal) 
!     CALL socket_init (s_sock, s_port, llocal) 
      lconn = .false. 
!                                                                       
 2000 FORMAT     (' ------ > Running in SERVER mode') 
      END SUBROUTINE remote_init                    
!*****7*****************************************************************
      SUBROUTINE do_socket (zeile, lcomm) 
!                                                                       
!     This part contains all the program independent commands.          
!                                                                       
      USE debug_mod 
      USE envir_mod 
      USE errlist_mod 
      USE learn_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) zeile 
      INTEGER lcomm 
!                                                                       
      INTEGER MAXW 
      PARAMETER (MAXW = 20) 
!                                                                       
      CHARACTER(1024) string 
      CHARACTER(1024) line 
      CHARACTER(1024) cpara (MAXW) 
      INTEGER lpara (MAXW) 
      INTEGER ianz 
      INTEGER il, i, j 
      INTEGER port 
!                                                                       
      REAL wert 
!                                                                       
      LOGICAL str_comp 
      REAL berechne 
      INTEGER socket_connect
      INTEGER socket_get
      INTEGER socket_send
!                                                                       
!     Get parameters                                                    
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, - lcomm) 
      IF (ier_num.ne.0) THEN 
         RETURN 
      ENDIF 
!                                                                       
      IF (.not.str_comp (cpara (1) , 'open', 2, lpara (1) , 4)          &
          .and..not.lremote) THEN                                           
         ier_num = - 15 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
!     This initializes the remote communication via SOCKETS             
!                                                                       
      IF (str_comp (cpara (1) , 'open', 2, lpara (1) , 4) ) THEN 
         IF (ianz.eq.3) THEN 
            port = nint (berechne (cpara (3), lpara (3) ) ) 
            CALL rem_bl (cpara (2), lpara (2) ) 
            ier_num = socket_connect (s_remote, cpara (2), lpara (2), port)
            IF(ier_num /=  0 ) THEN
               ier_typ = ER_IO
               lremote = .false. 
               RETURN
            ENDIF
!           CALL socket_connect (s_remote, cpara (2), lpara (2),        &
!           port)                                                       
            ier_num = socket_get (s_remote, line, il) 
            IF(socket_status == PROMPT_ON) THEN
            IF(line/='ready') THEN
              WRITE (output_io, 3000) line (1:il)
            ENDIF 
            ENDIF 
            IF(ier_num /=  0 ) THEN
               ier_typ = ER_IO
               lremote = .false. 
               RETURN
            ENDIF
            lremote = .true. 
            WRITE (output_io, 2100) 
         ELSE 
            ier_typ = ER_COMM 
            ier_num = - 6 
         ENDIF 
!                                                                       
!       Close the socket connection. The server keeps running           
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'close', 2, lpara (1) , 5) ) THEN 
         ier_num = socket_send (s_remote, 'bye', 3) 
         IF(ier_num < 0) THEN
            ier_num = -19
            RETURN
         ELSE
            ier_num = 0
         ENDIF
         CALL socket_close (s_remote) 
         lremote = .false. 
         WRITE (output_io, 2120) 
!                                                                       
!       Shut down the server                                            
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'exit', 2, lpara (1) , 4) ) THEN 
         ier_num = socket_send (s_remote, cpara (1), lpara (1) ) 
         IF(ier_num < 0) THEN
            ier_num = -19
            RETURN
         ELSE
            ier_num = 0
         ENDIF
         CALL socket_close (s_remote) 
         lremote = .false. 
         WRITE (output_io, 2110) 
!                                                                       
!       Transfer the value of a client variable to the server variable  
!       the input parameter 3 is evaluated and a line with              
!       <cpara(2)> = <value> is send to the server                      
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'transfer', 2, lpara (1) , 8) )     &
      THEN                                                              
         IF (ianz.eq.3) THEN 
            i = lpara (3) 
            zeile = '('//cpara (3) (1:i) //')' 
            i = i + 2 
            wert = berechne (zeile, i) 
!                                                                       
            IF (ier_num.eq.0) THEN 
               zeile (1:lpara (2) ) = cpara (2) (1:lpara (2) ) 
               WRITE (zeile (lpara (2) + 1:lpara (2) + 16), 4000) wert 
               lcomm = lpara (2) + 16 
               ier_num = socket_send (s_remote, zeile, lcomm) 
               IF(ier_num < 0) THEN
                  ier_num = -19
                  RETURN
               ELSE
                  ier_num = 0
               ENDIF
               ier_num = socket_get (s_remote, line, il) 
               IF(socket_status == PROMPT_ON  ) THEN
               IF(line/='ready') THEN
                 WRITE (output_io, 3000) line (1:il)
               ENDIF 
               ENDIF 
               IF(ier_num /=  0 ) THEN
                  ier_typ = ER_IO
                  lremote = .false. 
                  RETURN
               ENDIF
            ENDIF 
!                                                                       
         ELSEIF (ianz.gt.3) THEN 
            IF (index (cpara (3) , '"') .gt.0) THEN 
               zeile = cpara (4) (1:lpara (4) ) //',' 
               i = lpara (4) + 1 
               DO j = 5, ianz 
               zeile = zeile (1:i) //cpara (j) (1:lpara (j) ) //',' 
               i = i + lpara (j) + 1 
               ENDDO 
               zeile (i:i) = ' ' 
               i = i - 1 
               CALL berechne_char (zeile, i) 
               string = cpara (2) (1:lpara (2) ) //'='//cpara (3)       &
               (1:lpara (3) ) //", "//zeile (1:i)                       
               lcomm = lpara (2) + 1 + lpara (3) + 1 + i 
               ier_num = socket_send (s_remote, string, lcomm) 
               IF(ier_num < 0) THEN
                  ier_num = -19
                  RETURN
               ELSE
                  ier_num = 0
               ENDIF
               ier_num = socket_get (s_remote, line, il) 
               IF(socket_status == PROMPT_ON) THEN
               IF(line/='ready') THEN
                 WRITE (output_io, 3000) line (1:il)
               ENDIF 
               ENDIF 
               IF(ier_num /=  0 ) THEN
                  ier_typ = ER_IO
                  lremote = .false. 
                  RETURN
               ENDIF
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
               RETURN 
            ENDIF 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
            RETURN 
         ENDIF 
!                                                                       
!     socket send subcommand, send the rest of the line as is           
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'send', 2, lpara (1) , 4) ) THEN 
         ier_num = socket_send (s_remote, cpara (2), lpara (2) ) 
         IF(ier_num < 0) THEN
            ier_num = -19
            lremote = .false. 
            RETURN
         ELSE
            ier_num = 0
         ENDIF
         CALL socket_wait 
         IF(ier_num < 0 ) THEN
            lremote = .false.
            RETURN
         ENDIF
!                                                                       
!     No socket command so send the line as is                          
!                                                                       
      ELSE 
         ier_num = socket_send (s_remote, zeile, lcomm) 
         IF(ier_num < 0) THEN
            ier_num = -19
            ier_typ = ER_IO
            lremote = .false. 
            RETURN
         ELSE
            ier_num = 0
         ENDIF
         CALL socket_wait 
         IF(ier_num < 0 ) THEN
            lremote = .false.
            RETURN
         ENDIF
      ENDIF 
!                                                                       
 2100 FORMAT    (1x,'Connected ..') 
 2110 FORMAT    (1x,'Terminated by client ..') 
 2120 FORMAT    (1x,'Connection closed by client ..') 
 3000 FORMAT    (1x,'Server : ',a) 
 4000 FORMAT    ('=',e15.8e2) 
      END SUBROUTINE do_socket                      
!*****7*****************************************************************
      SUBROUTINE socket_wait 
!                                                                       
!     Waits for 'ready' from server                                     
!                                                                       
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER(256) line, cstr 
      INTEGER i, il, icr 
!                                                                       
      LOGICAL str_comp 
      INTEGER len_str 
      INTEGER socket_get 
!                                                                       
      line = '' 
      il = 0 
      icr = 0 
!                                                                       
      DO WHILE (.not.str_comp (line, 'ready', 5, il, 5) ) 
         ier_num = socket_get (s_remote, line, il) 
         IF( ier_num /= 0 ) THEN
            ier_typ = ER_IO
            RETURN
         ENDIF
         DO i = 1, il 
            IF (iachar (line (i:i) ) .eq.10.or.iachar (line (i:i) ) .eq.13) icr=i
         ENDDO 
         IF (icr.ne.0) THEN 
            IF(socket_status == PROMPT_ON) THEN
               IF(line/='ready') THEN
                 WRITE (output_io, 3000) line (1:icr - 1)
               ENDIF 
            ENDIF 
            cstr = line (icr + 1:il) 
            line = '' 
            il = len_str (cstr) 
            line = cstr (1:il) 
         ELSE 
            IF(socket_status == PROMPT_ON) THEN
               IF(line/='ready') THEN
                 WRITE (output_io, 3000) line (1:il)
               ENDIF 
            ENDIF 
         ENDIF 
      ENDDO 
!                                                                       
 3000 FORMAT    (1x,'Server : ',a) 
      END SUBROUTINE socket_wait                    
!*****7*****************************************************************
      SUBROUTINE exit_all 
!                                                                       
!     This part contains all the program independent commands.          
!                                                                       
      USE errlist_mod 
      USE prompt_mod 
      USE operating_mod
      USE terminal_mod
      IMPLICIT none 
!                                                                       
!
      INTEGER socket_send
!                                                                       
      IF (ier_num.ne.0) THEN 
         CALL errlist 
      ENDIF 
!                                                                       
!------ Close output file                                               
!                                                                       
      IF (output_status.ne.OUTPUT_SCREEN) THEN 
         CLOSE (output_io) 
      ENDIF 
!                                                                       
!------ Close sockets                                                   
!                                                                       
      IF (lremote) THEN 
         ier_num =  socket_send (s_remote, 'bye', 3) 
         CALL socket_close (s_remote) 
      ENDIF 
!                                                                       
      IF (lsocket) THEN 
         CALL socket_close (s_conid) 
         CALL socket_close (s_sock) 
      ENDIF 
!
!       For library procedure style set setup_done to false
!
      lsetup_done = .false.
!
      CALL operating_exit   ! Exit for operating system
      write(*,'(a,a)') COLOR_BG_DEFAULT, COLOR_FG_DEFAULT
!                                                                       
      END SUBROUTINE exit_all                       
!*****7*****************************************************************
      SUBROUTINE kdo_all (bef, lbef, zei, lc) 
!                                                                       
!     This part contains all the program independent commands.          
!                                                                       
      USE errlist_mod 
      USE learn_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      LOGICAL, PARAMETER :: NO_DIFFEV = .FALSE.
      INTEGER maxpar 
      PARAMETER (maxpar = 2) 
!                                                                       
      CHARACTER (LEN=*) , INTENT(IN)    :: bef 
      INTEGER           , INTENT(IN)    :: lbef 
      CHARACTER (LEN=*) , INTENT(INOUT) :: zei 
      INTEGER           , INTENT(INOUT) :: lc
      CHARACTER(1024) command 
      CHARACTER(1024) cpara (maxpar) 
      INTEGER lpara (maxpar) 
      INTEGER ianz 
      REAL werte (maxpar) 
!                                                                       
      LOGICAL str_comp 
!                                                                       
!     change working directory                                          
!                                                                       
      IF (str_comp (bef, 'cd', 2, lbef, 2) ) THEN 
         CALL do_chdir (zei, lc, .true.) 
!                                                                       
!     continues a macro 'continue'                                      
!                                                                       
      ELSEIF (str_comp (bef, 'continue', 2, lbef, 8) ) THEN 
         CALL macro_continue (zei, lc) 
!                                                                       
!------ Echo a string, just for interactive check in a macro 'echo'     
!                                                                       
      ELSEIF (str_comp (bef, 'echo', 2, lbef, 4) ) THEN 
         CALL echo (zei, lc) 
!                                                                       
!     Evaluate an expression, just for interactive check 'eval'         
!                                                                       
      ELSEIF (str_comp (bef, 'eval', 2, lbef, 4) ) THEN 
         CALL do_eval (zei, lc) 
!                                                                       
!------ IO commands                                                     
!                                                                       
      ELSEIF (str_comp (bef, 'bye', 2, lbef, 3) .and.lconn) THEN 
         CALL socket_close (s_conid) 
         lconn = .false. 
!                                                                       
      ELSEIF (str_comp (bef, 'fopen', 2, lbef, 5) ) THEN 
         CALL do_fopen (zei, lc) 
      ELSEIF (str_comp (bef, 'fclose', 2, lbef, 6) ) THEN 
         CALL do_fclose (zei, lc) 
      ELSEIF (str_comp (bef, 'fend', 2, lbef, 4) ) THEN 
         CALL do_fend (zei, lc) 
      ELSEIF (str_comp (bef, 'fexist', 2, lbef, 6) ) THEN 
         CALL do_fexist (zei, lc,.TRUE.) 
      ELSEIF (str_comp (bef, 'fget', 2, lbef, 4) ) THEN 
         CALL do_fget (zei, lc) 
      ELSEIF (str_comp (bef, 'fput', 2, lbef, 4) ) THEN 
         CALL do_fput (zei, lc) 
      ELSEIF (str_comp (bef, 'fsub', 2, lbef, 4) ) THEN 
         CALL do_fgetsub (zei, lc) 
      ELSEIF (str_comp (bef, 'fformat', 2, lbef, 7) ) THEN 
         CALL do_fformat (zei, lc) 
!                                                                       
!------ Online help                                                     
!                                                                       
      ELSEIF (linteractive .AND. str_comp (bef, 'help', 2, lbef, 4) .OR.   &
                                 str_comp (bef, '?   ', 1, lbef, 4) ) THEN                                            
         IF (lc.gt.0) THEN 
            lc = lc + 7 
            WRITE (command, '(a6,1x,a)') pname, zei (1:lc) 
         ELSE 
            lc = 7 
            command = pname 
         ENDIF 
         CALL do_hel (command, lc) 
!                                                                       
!------ Online manual                                                     
!
      ELSEIF (linteractive .AND. str_comp (bef, 'manual', 2, lbef, 6) ) THEN
        IF (lc.gt.0) THEN
           WRITE (command, '(a)') zei (1:lc)
        ELSE
           WRITE (command, '(a)') pname
           lc = LEN_TRIM(pname)
        ENDIF
        CALL do_manual(zei, lc)
!                                                                       
!------ start learning a macro 'learn'                                  
!                                                                       
      ELSEIF (str_comp (bef, 'lear', 3, lbef, 4) ) THEN 
         CALL start_learn (zei, lc) 
!                                                                       
!------ end learning a macro 'lend'                                     
!                                                                       
      ELSEIF (str_comp (bef, 'lend', 3, lbef, 4) ) THEN 
         CALL ende_learn 
!                                                                       
!     Reset the seed for the random number generator 'seed'             
!                                                                       
      ELSEIF (str_comp (bef, 'seed', 3, lbef, 4) ) THEN 
         CALL do_seed (zei, lc) 
!                                                                       
!                                                                       
!------ Various settings 'set'                                          
!                                                                       
      ELSEIF (str_comp (bef, 'set', 3, lbef, 3) ) THEN 
         CALL do_set (zei, lc) 
!     elseif(str_comp(bef,'memory',3,lbef,6)) THEN
!        CALL get_params (zei, ianz, cpara, lpara, maxpar, lc) 
!        CALL ber_params (ianz, cpara, lpara, werte, maxpar) 
!        if(ier_num == 0) THEN
!        write(cpara(1),'(I10)') NINT(werte(1))
!        ENDIF
!        call memory_message(cpara(1)(1:20))
!                                                                       
!------ Sleep fo a while 'sleep'                                        
!                                                                       
      ELSEIF (str_comp (bef, 'sleep', 2, lbef, 4) ) THEN 
         CALL get_params (zei, ianz, cpara, lpara, maxpar, lc) 
         IF (ier_num.eq.0) THEN 
            CALL ber_params (ianz, cpara, lpara, werte, maxpar) 
            IF (ier_num.eq.0) THEN 
               IF (nint (werte (1) ) .gt.0) THEN 
                  CALL do_sleep (nint (werte (1) ) ) 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ENDIF 
         ENDIF 
!                                                                       
!------ Handling a scocket connection                                   
!                                                                       
      ELSEIF (str_comp (bef, 'socket', 3, lbef, 6) ) THEN 
         CALL do_socket (zei, lc) 
!                                                                       
!------ Operating System Kommandos 'syst'                               
!                                                                       
      ELSEIF (str_comp (bef, 'syst', 2, lbef, 4) ) THEN 
         command = ' ' 
         IF (zei.ne.' ') THEN 
            command (1:lc) = zei (1:lc) 
            CALL do_operating (command, lc) 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
         ENDIF 
!                                                                       
!------ definition of variables                                         
!                                                                       
      ELSEIF (str_comp (bef, 'var', 3, lbef, 3) ) THEN 
         CALL define_variable (zei, lc, NO_DIFFEV) 
!                                                                       
!------ Wait for user input 'wait'                                      
!                                                                       
      ELSEIF (str_comp (bef, 'wait', 3, lbef, 4) ) THEN 
         CALL do_input (zei, lc) 
!                                                                       
!------ Unknown command                                                 
!                                                                       
      ELSE 
         ier_num = - 8 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE kdo_all                        
!*****7*****************************************************************
      SUBROUTINE do_cap (str) 
!+                                                                      
!       Converts string 'str' to upper letters                          
!-                                                                      
      IMPLICIT none 
!                                                                       
      CHARACTER (LEN=* ), INTENT(INOUT) :: str 
      INTEGER  :: i 
      INTEGER  :: len 
!                                                                       
      DO i = 1, len (str) 
         IF (iachar (str (i:i) ) .ge.iachar ('a') .and. &
             iachar (str (i:i) ) .le.iachar ('z')       ) THEN                                            
            str(i:i) = achar(iachar(str(i:i)) - iachar('a') + iachar('A'))                                                         
         ENDIF 
      ENDDO 
      END SUBROUTINE do_cap                         
!*****7*****************************************************************
      SUBROUTINE do_low (str) 
!+                                                                      
!       Converts string 'str' to lower case letters                          
!-                                                                      
      IMPLICIT none 
!                                                                       
      CHARACTER (LEN=* ), INTENT(INOUT) :: str 
      INTEGER  :: i 
      INTEGER  :: len 
!                                                                       
      DO i = 1, len (str) 
         IF (iachar (str (i:i) ) .ge.iachar ('A') .and. &
             iachar (str (i:i) ) .le.iachar ('Z')       ) THEN                                            
            str(i:i) = achar(iachar(str(i:i)) - iachar('A') + iachar('a'))                                                         
         ENDIF 
      ENDDO 
      END SUBROUTINE do_low
!*****7***********************************************************      
      SUBROUTINE ini_ran (np, werte) 
!                                                                       
      USE random_mod
      USE random_state_mod
      USE times_mod
      IMPLICIT none 
!                                                                       
!                                                                       
!     INTEGER, INTENT(IN) :: iflag 
!
      INTEGER            , INTENT(IN) :: np
      REAL, DIMENSION(np), INTENT(IN) :: werte
      INTEGER, DIMENSION(NP) :: iwerte
!                                                                       
!     IF (iflag.ge.0) THEN 
!        CALL datum_intrinsic () 
!        idum = - midnight 
!     ELSE 
!        idum = iflag 
!     ENDIF 
!     iset = 0 
!     np = 1
!     werte(1) = IABS(iflag)
      iwerte(:) = NINT(werte(:))
      CALL ini_ran_ix(np, iwerte)
      END SUBROUTINE ini_ran                        
!*****7***********************************************************      
      SUBROUTINE get_cmd (line, ll, befehl, lbef, zeile, lp, prom) 
!+                                                                      
!     This subroutine gets a command for processing. If it              
!     is keyboard input and the program was compiled with               
!     READLINE defined, you will have basic line editing                
!     functions.                                                        
!-                                                                      
      USE charact_mod
      USE debug_mod 
      USE doact_mod 
      USE errlist_mod 
      USE jsu_readline
      USE learn_mod 
      USE class_macro_internal 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER (LEN=*), INTENT(INOUT) :: line
      INTEGER          , INTENT(OUT)   :: ll
      CHARACTER (LEN=*), INTENT(OUT)   :: befehl
      CHARACTER (LEN=*), INTENT(OUT)   :: zeile
      INTEGER          , INTENT(OUT)   :: lp
      CHARACTER (LEN=*), INTENT(OUT)   :: prom 
!
      CHARACTER(1024) input
      CHARACTER(60) bprom 
      CHARACTER(10) cready 
      INTEGER lbef, indxb 
      INTEGER il, jl, lcready 
      LOGICAL lreg 
      LOGICAL str_comp 
!                                                                       
      INTEGER len_str 
      INTEGER socket_accept 
      INTEGER socket_get 
      INTEGER socket_send 
!                                                                       
      input  = ' ' 
      line   = ' ' 
      zeile  = ' ' 
      befehl = ' ' 
!                                                                       
      ll   = 0 
      lp   = 0 
      lbef = 0
      ier_num = 0
      ier_typ = ER_NONE 
!                                                                       
      IF (lblock) THEN 
         CALL do_execute (lreg, input, ll) 
         IF (ier_num.ne.0.or..not.lreg) RETURN 
!                                                                       
      ELSEIF (lmakro.and..not.lblock_dbg) THEN 
         CALL do_prompt (prom) 
         CALL macro_read (input, ll) 
         IF (ier_num.ne.0) RETURN 
!                                                                       
      ELSEIF (lsocket) THEN 
!                                                                       
!------ -- Here we get commands via a SOCKET for remote control         
!------ -- Send ready message first                                     
!                                                                       
         IF (.not.lconn) THEN 
            il = len_str (s_ipallowed) 
            ier_num = socket_accept (s_sock, s_conid, s_ipallowed, il,       &
            s_port)                                                     
            IF(ier_num < 0) THEN
               ier_typ = ER_IO
               STOP
            ENDIF 
            lconn = .true. 
         ENDIF 
         cready = 'ready' 
         lcready = len_str (cready) 
         ier_num = socket_send (s_conid, cready, lcready) 
         IF(ier_num < 0) THEN
            ier_num = -19
            RETURN
         ELSE
            ier_num = 0
         ENDIF
         first_input = .false. 
         ier_num = socket_get (s_conid, input, ll) 
         IF(ier_num == -21 ) THEN
            input = 'exit'
            ll    = 4
            ier_num = 0
            ier_typ = ER_NONE 
         ELSEIF(ier_num /=  0 ) THEN
            ier_typ = ER_IO
            lremote = .false. 
            RETURN
         ENDIF
      ELSE 
!                                                                       
!     --Normal mode, if status is PROMPT_OFF or PROMPT_REDIRECT         
!---- --we assume non interactive input and use 'normal' FORTRAN      
!---- --READ to avoid EOF problems.                                   
!                                                                       
!        On old Red Hat systems uses of readline for the first input
!        line caused problems. Seems not to be an issue any longer
         IF(linteractive) THEN
            first_input = .false.
            IF (prompt_status.eq.PROMPT_ON.and..not.first_input) THEN 
               bprom = ' '//prom (1:len_str(prom)) //' > ' 
!                                                                       
!     ----call the c-routine that enables command history & line editing
!                                                                       
               CALL iso_readline (input,bprom) 
               ll=len_str(input)
!                                                                       
!------ --otherwise use normal READ                                     
!                                                                       
            ELSE 
               CALL do_prompt (prom) 
               READ ( *, 2000, end = 990, err = 995) input 
               first_input = .FALSE. 
            ENDIF 
         ELSE 
            input = input_gui
         ENDIF 
!                                                                       
         ll = len_str (input) 
         IF (prompt_status.eq.PROMPT_REDIRECT) THEN 
            IF (ll.gt.0) THEN 
               WRITE (output_io, 2000) input (1:ll) 
            ELSE 
               WRITE (output_io, 2000) 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
!     For commands of significant length, remove leading 'white'        
!     blanks, get the command.                                          
!     Return comment lines "# ..." unchanged.                           
!                                                                       
      IF (ll.ne.0) THEN 
         IF (input (1:1) .ne.'#'.and.input (1:1) .ne.'!') THEN 
            ll = len_str (input) 
            CALL remove_comment (input, ll) 
!                                                                       
!------ --- Remove leading blanks from 'line'                           
!                                                                       
            il = 1 
            jl = len_str (input) 
            DO while ( (input (il:il) .eq.' '.or.input (il:il) .eq.TAB) &
                       .and.il.le.jl)                                              
               il = il + 1 
            ENDDO 
            line = input (il:jl) 
            ll = len_str (line) 
!                                                                       
!     - The maximum number of significant characters depends on the     
!     - length of the character constant befehl.                        
!                                                                       
            lbef = len (befehl) 
            indxb = index (line, ' ') 
            lbef = min (indxb - 1, lbef) 
            befehl = line (1:lbef) 
!                                                                       
!     - command parameters start at the first character following       
!------ - the blank                                                     
!                                                                       
            IF (indxb + 1.le.ll) THEN 
               zeile = line (indxb + 1:ll) 
               lp = ll - indxb 
            ENDIF 
!                                                                       
!     - Learn command for learn sequence                                
!                                                                       
            IF (llearn.and..not.str_comp (befehl, 'lend', 3, lbef, 4)   &
                      .and..not.str_comp (befehl, 'mouse', 3, lbef, 5)  &
                      .and..not.lmakro) THEN
               IF (ll.gt.0) THEN 
                  WRITE (33, 2000) input (1:len_str (input) ) 
               ELSE 
                  WRITE (33, 2000) 
               ENDIF 
            ENDIF 
         ELSE 
            line = input 
         ENDIF 
      ENDIF 
!                                                                       
!     Normal return                                                     
!                                                                       
      RETURN 
!                                                                       
!     EOF in input                                                      
!                                                                       
  990 CONTINUE 
      line = 'exit' 
      ll = 4 
      befehl = 'exit' 
      lbef = 4 
      zeile = ' ' 
      lp = 0 
      RETURN 
!                                                                       
!     Error in input                                                    
!                                                                       
  995 CONTINUE 
      ier_num = - 9 
      ier_typ = ER_IO 
      RETURN 
!                                                                       
 2000 FORMAT     (a) 
      END SUBROUTINE get_cmd                        
!*****7*****************************************************************
      SUBROUTINE remove_comment (line, ll) 
!                                                                       
!     removes trailing in line comments                                 
!                                                                       
      USE charact_mod
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) line 
      INTEGER ll 
!                                                                       
      INTEGER i 
      LOGICAL quote 
      LOGICAL search 
!                                                                       
      search = .true. 
      DO i = 1, ll 
         quote = line (i:i) .eq.'"'.or.line (i:i) .eq.'''' 
         IF (quote) THEN 
            search = .not.search 
         ENDIF 
         IF (search) THEN 
            IF (line (i:i) .eq.'#'.or.line (i:i) .eq.'!') THEN 
               line (i:ll) = ' ' 
               ll = i - 1 
               RETURN 
            ENDIF 
         ENDIF 
      ENDDO 
!                                                                       
      RETURN 
      END SUBROUTINE remove_comment                 
!*****7*****************************************************************
      SUBROUTINE do_operating (zeile, lp) 
!-                                                                      
!     writes an echo to the screen                                      
!+                                                                      
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxp 
      PARAMETER (maxp = 12) 
      CHARACTER ( * ) zeile 
      CHARACTER(1024) string 
      CHARACTER(1024) cpara (maxp) 
      INTEGER lpara (maxp) 
      INTEGER ianz 
      INTEGER lp, i 
      INTEGER iko, iqo, iqo2, lstring 
      REAL werte (maxp) 
!                                                                       
!     Find any "" which would mean that we need parameter substitution  
!                                                                       
      iqo = index (zeile (1:lp) , '"') 
      IF (iqo.eq.0) THEN 
!                                                                       
!     --None foud, harmless echo                                        
!                                                                       
         CALL do_operating_comm (zeile (1:lp) ) 
      ELSE 
!                                                                       
!     --Look for matching ""                                            
!                                                                       
         iqo2 = index (zeile (iqo + 1:lp) , '"') 
         IF (iqo2.eq.0) THEN 
            ier_num = -  4 
            ier_typ = ER_COMM 
            RETURN 
         ENDIF 
!                                                                       
!     --save the string in quotation marks for later use as             
!       first parameter                                                 
!                                                                       
         iqo2 = iqo2 + iqo 
         iko = index (zeile (iqo2 + 1:lp) , ',') 
         IF (iko.ne.0) THEN 
            string = zeile (iqo2 + iko + 1:lp) 
            lstring = - (lp - iqo2 - iko) 
         ELSE 
            string = ' ' 
            lstring = 1 
         ENDIF 
!                                                                       
!     --get all other parameters                                        
!                                                                       
         CALL get_params (string, ianz, cpara, lpara, maxp, lstring) 
         IF (ier_num.eq.0) THEN 
            DO i = ianz, 1, - 1 
            cpara (i + 1) = cpara (i) 
            lpara (i + 1) = lpara (i) 
            ENDDO 
            cpara (1) = zeile (1:iqo2) 
            lpara (1) = iqo2 
            ianz = ianz + 1 
            CALL do_build_name (ianz, cpara, lpara, werte, maxp, 1) 
            IF (ier_num.eq.0) THEN 
!                                                                       
!     ------The first comma that follows the quotation marks must be    
!           omitted, all others retained as part of the echo            
!                                                                       
               IF (ianz.eq.1) THEN 
                  string = cpara (ianz) (1:lpara (ianz) ) 
                  lstring = lpara (ianz) 
               ELSEIF (ianz.eq.2) THEN 
                  string = cpara (1) (1:lpara (1) ) //cpara (ianz)      &
                  (1:lpara (ianz) )                                     
                  lstring = lpara (1) + lpara (2) 
               ELSE 
                  string = cpara (1) (1:lpara (1) ) 
                  lstring = lpara (1) 
                  DO i = 1, ianz 
                  zeile = string (1:lstring) //cpara (i) (1:lpara (i) ) 
                  lstring = lstring + lpara (i) 
                  string = zeile 
                  ENDDO 
               ENDIF 
               CALL do_operating_comm (string) 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
      END SUBROUTINE do_operating                   
!*****7***********************************************************      
      SUBROUTINE do_fopen (zeile, lp) 
!                                                                       
      USE errlist_mod 
      USE macro_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 10) 
!                                                                       
      CHARACTER (LEN=*), INTENT(IN) ::  zeile 
      INTEGER          , INTENT(IN) :: lp 
!
      CHARACTER(1024) cpara (maxw) 
      CHARACTER(LEN=1024) :: message
      REAL werte (maxw) 
      INTEGER lpara (maxw)
      INTEGER :: ios
      INTEGER ianz, ianzz 
      INTEGER ii 
      LOGICAL lappend 
      LOGICAL one_open 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      ianzz = 1 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (ianz.ge.1) THEN 
         CALL ber_params (ianzz, cpara, lpara, werte, maxw) 
         IF (ier_num.ne.0) RETURN 
         IF (ianz.eq.1) THEN 
            ianz = 0 
         ELSE 
            CALL del_params (1, ianz, cpara, lpara, maxw) 
         ENDIF 
         IF (ier_num.ne.0) RETURN 
         ii = nint (werte (1) ) 
         IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
            ier_num = - 13 
            ier_typ = ER_IO 
            RETURN 
         ENDIF 
!                                                                       
         IF (ianz.ge.1) THEN 
            IF (io_open (ii) ) THEN 
               ier_num = - 10 
               ier_typ = ER_IO 
               RETURN 
            ENDIF 
            CALL do_build_name (ianz, cpara, lpara, werte, maxw, 1) 
            IF (ianz.eq.2) THEN 
               lappend = str_comp (cpara (2) , 'append', 1, lpara (2) , &
               6)                                                       
            ELSE 
               lappend = .false. 
            ENDIF 
            IF (lappend) THEN 
               CALL oeffne_append (io_unit (ii) , cpara (1) , 'unknown')
               IF (ier_num.ne.0) RETURN 
!DBG            open (unit=io_unit(ii),file=cpara(1),status='unknown',  
!DBG     &                       access='append',err=999)               
!DBG95     &                       access='sequential',err=999)         
               WRITE (output_io, 1000) cpara (1) (1:lpara (1) ) 
            ELSE 
               OPEN (unit = io_unit (ii) , file = cpara (1) , &
                     status = 'unknown', IOSTAT=ios,IOMSG=message)                                    
               IF(ios/=0) THEN
                  ier_num = -2
                  ier_typ = ER_IO
                  ier_msg(1) ='Could not open the NULL file'
                  ier_msg(2) = message(1:MAX(1,MIN(80,LEN_TRIM(message))))
                  RETURN
               ENDIF
               WRITE (output_io, 1100) cpara (1) (1:lpara (1) ) 
            ENDIF 
            io_open (ii) = .true. 
            io_file (ii) = cpara (1) (1:lpara (1) ) 
         ELSE 
            IF (io_open (ii) ) THEN 
               WRITE (output_io, 2000) ii, io_file (ii) 
            ELSE 
               WRITE (output_io, 2010) 
            ENDIF 
         ENDIF 
      ELSE 
         one_open = .false. 
         DO ii = 1, MAC_MAX_IO 
         IF (io_open (ii) ) THEN 
            WRITE (output_io, 2000) ii, io_file (ii) 
            one_open = .true. 
         ENDIF 
         ENDDO 
         IF (.not.one_open) THEN 
            WRITE (output_io, 2010) 
         ENDIF 
      ENDIF 
      RETURN 
!                                                                       
! 999 CONTINUE 
      ier_num = - 2 
      ier_typ = ER_IO 
!                                                                       
 1000 FORMAT     (' ------ > File ',a,' opened (appending) ...') 
 1100 FORMAT     (' ------ > File ',a,' opened (overwriting) ...') 
 2000 FORMAT     (' ------ > IO stream Nr. ',i2,' open, file : ',a) 
 2010 FORMAT     (' ------ > No IO stream open') 
      END SUBROUTINE do_fopen                       
!*****7***********************************************************      
      SUBROUTINE do_fclose (zeile, lp) 
!                                                                       
      USE errlist_mod 
      USE macro_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 25) 
!                                                                       
      CHARACTER (LEN=*), INTENT(IN) ::  zeile 
      INTEGER          , INTENT(IN) :: lp 
!
      CHARACTER(1024) cpara (maxw)
      REAL werte (maxw) 
      INTEGER lpara (maxw)
      INTEGER ianz, ii 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (ianz.eq.1) THEN 
         IF (str_comp (cpara (1) , 'all', 2, lpara (1) , 3) ) THEN 
            DO ii = 1, MAC_MAX_IO 
            IF (io_open (ii) ) THEN 
               CLOSE (io_unit (ii) ) 
               io_open (ii) = .false. 
            ENDIF 
            ENDDO 
         ELSE 
            CALL ber_params (ianz, cpara, lpara, werte, maxw) 
            IF (ier_num.ne.0) RETURN 
!                                                                       
            ii = nint (werte (1) ) 
            IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
               ier_num = - 13 
               ier_typ = ER_IO 
               RETURN 
            ENDIF 
            IF (io_open (ii) ) THEN 
               CLOSE (io_unit (ii) ) 
               io_open (ii) = .false. 
            ELSE 
               ier_num = - 11 
               ier_typ = ER_IO 
            ENDIF 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
      END SUBROUTINE do_fclose                      
!*****7***********************************************************      
      SUBROUTINE do_fend (zeile, lp) 
!                                                                       
      USE errlist_mod 
      USE macro_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER, PARAMETER :: maxw = 10 
!                                                                       
      CHARACTER (LEN=*), INTENT(IN) ::  zeile 
      INTEGER          , INTENT(IN) :: lp 
!
      CHARACTER(LEN=1024), DIMENSION(maxw) :: cpara
      REAL werte (maxw) 
      INTEGER lpara (maxw)
      INTEGER ianz, ianzz 
      INTEGER ii 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      ianzz = 1 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (ianz.ge.1) THEN 
         CALL ber_params (ianzz, cpara, lpara, werte, maxw) 
         IF (ier_num.ne.0) RETURN 
         IF (ianz.eq.1) THEN 
            ianz = 0 
         ELSE 
            CALL del_params (1, ianz, cpara, lpara, maxw) 
         ENDIF 
         IF (ier_num.ne.0) RETURN 
         ii = nint (werte (1) ) 
         IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
            ier_num = - 13 
            ier_typ = ER_IO 
            RETURN 
         ENDIF 
!                                                                       
         IF (ianz.ge.1) THEN 
            IF (str_comp (cpara (1) , 'error', 2, lpara (1) , 5) ) THEN
               io_eof (ii) = .false. 
            ELSEIF (str_comp(cpara(1), 'continue', 2, lpara(1), 8)) THEN
               io_eof (ii) = .true. 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE do_fend                        
!*****7***********************************************************      
      SUBROUTINE do_fget (zeile, lp) 
!                                                                       
      USE charact_mod
      USE errlist_mod 
      USE macro_mod 
      USE param_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 25) 
!                                                                       
      CHARACTER (LEN=*), INTENT(IN) ::  zeile 
      INTEGER          , INTENT(INOUT) :: lp 
!
      CHARACTER(1024) cpara (maxw), line, cstr , bstr
      CHARACTER(2048) string 
      REAL werte (maxw) 
      INTEGER lpara (maxw), lstr
      INTEGER ianz, i, igl, ii, ianzz 
      INTEGER ia, ie, itab , ll
!                                                                       
      INTEGER len_str 
!                                                                       
      ianzz = 1 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      CALL ber_params (ianzz, cpara, lpara, werte, maxw) 
      IF (ier_num.ne.0) RETURN 
      IF (ianz.eq.1) THEN 
         ianz = 0 
      ELSE 
         CALL del_params (1, ianz, cpara, lpara, maxw) 
      ENDIF 
      ii = nint (werte (1) ) 
      IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
         ier_num = - 13 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
      IF (.not.io_open (ii) ) THEN 
         ier_num = - 11 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
      IF (ianz.gt.0) THEN 
         READ (io_unit (ii) , '(a)', err = 998, end = 999) string 
         DO while (string (1:1) .eq.'#') 
            READ (io_unit (ii) , '(a)', err = 998, end = 999) string 
         ENDDO 
         lstr = len_str (string) 
         itab = index (string, TAB) 
         DO while (itab.gt.0) 
            string (itab:itab) = ' ' 
            itab = index (string, TAB) 
         ENDDO 
         ia = max (1, io_get_sub (ii, 1) ) 
         IF (io_get_sub (ii, 2) .eq. - 1) THEN 
            ie = lstr 
         ELSE 
            ie = min (lstr, io_get_sub (ii, 2) ) 
         ENDIF 
!RBN        read(string(ia:ie),*,err=998,end=999) (werte(i),i=1,ianz)   
!RBN        res_para(0) = 0                                             
!RBN        do i=1,ianz                                                 
!RBN          write(cstr,*) werte(i)                                    
!RBN          lstr = len_str(cstr)                                      
!RBN          line = cpara(i)(1:lpara(i))//'='//cstr(1:lstr)            
!RBN          lp   = len_str(line)                                      
!RBN          igl  = index(line,'=')                                    
!RBN          call do_math(line,igl,lp)                                 
!RBN          if (ier_num.ne.0) return                                  
!RBN        ENDDO                                                       
         loop_para: DO i = 1, ianz 
            line = cpara (i) (1:lpara (i) ) //'=' 
            lp = lpara (i) + 1 
            igl = index (line, '=') 
            cstr (1:1) = string (ia:ia) 
!                                                                       
!     ---Remove leading blanks or leading ","                           
!                                                                       
            DO while (cstr (1:1) .eq.' '.or.cstr (1:1) .eq.',') 
               ia = ia + 1 
               IF (ia.gt.ie) THEN 
                  GOTO 998 
               ENDIF 
               cstr (1:1) = string (ia:ia) 
            ENDDO 
!                                                                       
!     ---Copy the characters into the line, until a blank or ","        
!                                                                       
            ll = 0
            bstr = ' '
            DO while (.not. (cstr (1:1) .eq.' '.or.cstr (1:1) .eq.',') ) 
               ll = ll + 1
               lp = lp + 1 
               line (lp:lp) = cstr (1:1) 
               bstr (ll:ll) = cstr (1:1)   ! make copy for character evaluation
               ia = ia + 1 
               IF (ia.gt.ie) THEN 
                  GOTO 997 
               ENDIF 
               cstr (1:1) = string (ia:ia) 
            ENDDO 
  997       CONTINUE 
            CALL do_math (line, igl, lp) 
            IF(ier_num /= 0) THEN    ! Error in math assum string 
               line = cpara(i)(1:lpara(i)) //' = '''// bstr(1:LEN_TRIM(bstr))//''''  
               igl = lpara(i) + 2
               lp  = LEN_TRIM(line)
               CALL do_math (line, igl, lp)
            ENDIF
         ENDDO loop_para
      ELSE 
         READ (io_unit (ii), *, err = 998, end = 999) 
         res_para (0) = 0 
      ENDIF 
!                                                                       
      RETURN 
!                                                                       
  998 CONTINUE 
      ier_num = - 3 
      ier_typ = ER_IO 
      RETURN 
!                                                                       
  999 CONTINUE 
      IF (io_eof (ii) ) THEN 
         res_para (0) = - 1 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_IO 
      ENDIF 
      RETURN 
!                                                                       
      END SUBROUTINE do_fget                        
!*****7***********************************************************      
      SUBROUTINE do_fformat (zeile, lp) 
!                                                                       
      USE debug_mod 
      USE errlist_mod 
      USE macro_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 2) 
!                                                                       
      CHARACTER ( * ) zeile 
      CHARACTER(1024) cpara (maxw) 
      INTEGER lpara (maxw), lp 
      INTEGER ii, iii, ianz 
      REAL werte (maxw) 
!                                                                       
      INTEGER len_str 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (ianz.eq.0) THEN 
         WRITE (output_io, 1000) 
         DO ii = 1, MAC_MAX_FORM, 6 
            WRITE (output_io, 1100) (ii + iii, iii = 0, MIN (5, MAC_MAX_FORM - ii) )
            WRITE (output_io, 1200) (io_out_format (ii + iii)          &
                  (2:MIN(len_str(io_out_format(ii+iii))-1, 8)), iii=0, &
                  MIN (5, MAC_MAX_FORM - ii) )                                           
         ENDDO 
      ELSEIF (ianz.eq.2) THEN 
         CALL ber_params (1, cpara, lpara, werte, maxw) 
         IF (ier_num.ne.0) RETURN 
         ii = NINT (werte (1) ) 
         IF (ii.gt.0.and.ii.le.MAC_MAX_FORM) THEN 
            io_out_format (ii) = '('//cpara (2) (1:lpara (2) ) //')' 
         ELSE 
            ier_num = - 28
            ier_typ = ER_IO 
            WRITE(ier_msg(3),9000) MAC_MAX_FORM
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
 1000 FORMAT     (' Current format setting for file output :',/) 
 1100 FORMAT     ('   Column : ',6(i8,2x)) 
 1200 FORMAT     ('   Format : ',6(a8,2x),/) 
 9000 FORMAT ( 'The first parameter must be in range 0 to',i3)

      END SUBROUTINE do_fformat                     
!*****7***********************************************************      
      SUBROUTINE do_fgetsub (zeile, lp) 
!                                                                       
      USE debug_mod 
      USE errlist_mod 
      USE macro_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 3) 
!                                                                       
      CHARACTER ( * ) zeile 
      CHARACTER(1024) cpara (maxw) 
      INTEGER lpara (maxw), lp 
      INTEGER ii, iii, ianz 
      REAL werte (maxw) 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      iii = 1 
      CALL ber_params (iii, cpara, lpara, werte, maxw) 
      IF (ianz.eq.1) THEN 
         ianz = 0 
      ELSE 
         CALL del_params (1, ianz, cpara, lpara, maxw) 
      ENDIF 
      ii = nint (werte (1) ) 
      IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
         ier_num = - 13 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
      IF (ianz.eq.0) THEN 
         io_get_sub (ii, 1) = 1 
         io_get_sub (ii, 2) = - 1 
      ELSEIF (ianz.eq.2) THEN 
         CALL ber_params (ianz, cpara, lpara, werte, maxw) 
         IF (ier_num.ne.0) RETURN 
         io_get_sub (ii, 1) = nint (werte (1) ) 
         io_get_sub (ii, 2) = nint (werte (2) ) 
         IF (io_get_sub (ii, 2) .ne. - 1.and.io_get_sub (ii, 1)         &
         .gt.io_get_sub (ii, 2) ) THEN                                  
            ier_num = - 26 
            ier_typ = ER_IO 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!DBG                                                                    
!DBG      write(*,*) 'cpara      ',cpara                                
!DBG      write(*,*) 'werte      ',werte                                
!DBG      write(*,*) 'io_get_sub ',io_get_sub                           
!                                                                       
      END SUBROUTINE do_fgetsub                     
!*****7***********************************************************      
      SUBROUTINE do_fput (zeile, lp) 
!                                                                       
      USE debug_mod 
      USE errlist_mod 
      USE macro_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = MAC_MAX_FORM) 
!                                                                       
      CHARACTER ( * ) zeile 
      CHARACTER(1024) cpara (maxw), cstr, line 
      CHARACTER(1) quote 
      REAL wert 
      INTEGER lpara (maxw), lp 
      INTEGER ianz, lstr, i, ie, ianzz, ii 
      REAL werte (maxw) 
!                                                                       
      INTEGER len_str 
      REAL berechne 
!                                                                       
      quote = achar (39) 
      ianzz = 1 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, - lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      CALL ber_params (ianzz, cpara, lpara, werte, maxw) 
      IF (ier_num.ne.0) RETURN 
      IF (ianz.eq.1) THEN 
         ianz = 0 
      ELSE 
         CALL del_params (1, ianz, cpara, lpara, maxw) 
      ENDIF 
      ii = nint (werte (1) ) 
      IF (ii.lt.0.or.MAC_MAX_IO.lt.ii) THEN 
         ier_num = - 13 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
      IF (.not.io_open (ii) ) THEN 
         ier_num = - 11 
         ier_typ = ER_IO 
         RETURN 
      ENDIF 
!                                                                       
      IF (ianz.ge.1) THEN 
         ie = 0 
         CALL rem_leading_bl(cpara(1),lpara(1))
         IF (cpara (1) (1:1) .eq.'"') THEN 
            CALL do_build_name (ianz, cpara, lpara, werte, maxw, 1) 
            line = cpara (1) 
            ie = lpara (1) 
         ELSE 
            DO i = 1, ianz 
            IF (index (cpara (i) (1:lpara (i) ), quote) .ne.0) THEN 
               line (ie+1:ie+lpara (i) - 2) = cpara (i) (2:lpara (i)    &
               - 1)                                                     
               ie = ie+lpara (i) - 2 
            ELSE 
               cstr = '('//cpara (i) (1:lpara (i) ) //')' 
               lstr = lpara (i) + 2 
               CALL rem_bl (cstr, lstr) 
               wert = berechne (cstr, lstr) 
               IF (ier_num.ne.0) RETURN 
               IF (io_out_format (i) .eq.'(*)') THEN 
                  WRITE (cstr, *, err = 999) wert 
               ELSE 
                  IF (index (io_out_format (i) , 'i') .ne.0.or.index (  &
                  io_out_format (i) , 'I') .ne.0.or.index (             &
                  io_out_format (i) , 'z') .ne.0.or.index (             &
                  io_out_format (i) , 'Z') .ne.0) THEN                  
                     WRITE (cstr, io_out_format (i), err = 999) nint (  &
                     wert)                                              
                  ELSE 
                     WRITE (cstr, io_out_format (i), err = 999) wert 
                  ENDIF 
               ENDIF 
               lstr = len_str (cstr) 
               line (ie+1:ie+lstr) = cstr (1:lstr) 
               ie = ie+lstr 
            ENDIF 
            ENDDO 
         ENDIF 
         WRITE (io_unit (ii), 9999, err = 999) line (1:ie) 
         IF (dbg) WRITE ( *, 1000) line (1:ie) 
      ELSE 
         WRITE (io_unit (ii), *, err = 999) 
      ENDIF 
      RETURN 
!                                                                       
  999 ier_num = - 12 
      ier_typ = ER_IO 
      RETURN 
!                                                                       
 1000 FORMAT    ( ' debug  > Written: ',a) 
 9999 FORMAT    (a) 
      END SUBROUTINE do_fput                        
!*****7***********************************************************      
      SUBROUTINE do_input (zeile, lp) 
!                                                                       
      USE errlist_mod 
      USE param_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 12) 
!                                                                       
      CHARACTER ( LEN=* ), INTENT(INOUT)   ::  zeile 
      INTEGER            , INTENT(INOUT)   ::  lp 
      CHARACTER(1024) cpara (maxw) 
      CHARACTER(1024) line 
      CHARACTER(1) cdummy 
      REAL werte (maxw) 
      INTEGER i 
      INTEGER lpara (maxw)
      INTEGER ianz 
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
      lp = - lp 
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (ianz.eq.0) THEN 
         WRITE ( *, 1000,advance='no') 
         READ ( *, 5000, err = 50, end = 50) cdummy 
      ELSEIF (ianz.eq.1.or.ianz.eq.2) THEN 
         IF (str_comp (cpara (1) , 'return', 1, lpara (1) , 6) ) THEN 
            WRITE ( *, 1000,advance='no') 
            READ ( *, 5000, err = 50, end = 50) cdummy 
         ELSEIF (str_comp (cpara (1) , 'input', 1, lpara (1) , 5) )     &
         THEN                                                           
            IF (ianz.eq.1) THEN 
               WRITE ( *, 1500,advance='no') 
            ELSEIF (ianz.eq.2) THEN 
               WRITE ( *, 1600,advance='no') cpara (2) (1:lpara (2) ) 
            ENDIF 
            READ ( *, 5000, err = 50, end = 50) line 
            lp = len_str (line) 
            CALL get_params (line, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) THEN 
               IF (ianz.le.maxw) THEN 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) THEN 
                     res_para (0) = float (ianz) 
                     DO i = 1, ianz 
                     res_para (i) = werte (i) 
                     ENDDO 
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
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
      RETURN 
!                                                                       
   50 CONTINUE 
      ier_num = - 9 
      ier_typ = ER_IO 
!                                                                       
 1000 FORMAT     (' ------ > Waiting for <RETURN> : ') 
 1500 FORMAT     (' ------ > Waiting for input : ') 
 1600 FORMAT     (a,' ') 
 5000 FORMAT     (a) 
      END SUBROUTINE do_input                       
!*****7***********************************************************      
      SUBROUTINE do_seed (zeile, lp) 
!                                                                       
      USE errlist_mod 
      USE random_state_mod
      USE take_param_mod
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER, PARAMETER :: maxw = 65 
!                                                                       
      CHARACTER (LEN=*), INTENT(INOUT) :: zeile 
      INTEGER          , INTENT(INOUT) :: lp
!
      CHARACTER(LEN=1024), DIMENSION(MAXW) ::  cpara !(maxw) 
      INTEGER            , DIMENSION(MAXW) ::  lpara !(maxw)
      INTEGER  :: ianz, np
      REAL               , DIMENSION(MAXW) ::  werte !(maxw) 
      INTEGER            , DIMENSION(MAXW-1) :: iwerte !(maxw) 
      INTEGER, PARAMETER :: NOPTIONAL = 1
      CHARACTER(LEN=1024), DIMENSION(NOPTIONAL) :: oname   !Optional parameter names
      CHARACTER(LEN=1024), DIMENSION(NOPTIONAL) :: opara   !Optional parameter strings returned
      INTEGER            , DIMENSION(NOPTIONAL) :: loname  !Lenght opt. para name
      INTEGER            , DIMENSION(NOPTIONAL) :: lopara  !Lenght opt. para name returned
      REAL               , DIMENSION(NOPTIONAL) :: owerte   ! Calculated values
      INTEGER, PARAMETER                        :: ncalc = 1 ! Number of values to calculate 
      INTEGER :: igroup
      INTEGER :: i,ind, ip
!
      DATA oname  / 'group'  /
      DATA loname /  5       /
      opara  =  (/ '1.0000'  /)   ! Always provide fresh default values
      lopara =  (/  6        /)
      owerte =  (/  1.0      /)
!
!                                                                       
      werte(:)  = 0.0
      iwerte(:) = 0
      IF (zeile.ne.' ') THEN 
         CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
         CALL get_optional(ianz, MAXW, cpara, lpara, NOPTIONAL,  ncalc, &
                           oname, loname, opara, lopara, owerte)
         igroup = NINT(owerte(1))
!
         IF (ier_num == 0) THEN 
            IF (ianz <= MAXW) THEN 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num == 0) THEN 
                  IF(MOD(ianz,igroup)==0) THEN
                     np = ianz/igroup
                     DO i = 1, ianz   ! loop over the current number of parameters
                        ind = (i-1)/igroup+1   ! New parameter index
                        ip  = igroup - MOD(i-1,igroup) - 1   ! Power for 10**ip
                        iwerte(ind) = iwerte(ind) + NINT(werte(i))*10000**ip
                     ENDDO
                     CALL ini_ran_ix(np, iwerte)
                  ELSE
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                     ier_msg(1) = 'Nonmatching modulo'
                  ENDIF 
               ENDIF 
!           IF (ianz.eq.1) THEN 
!              CALL ber_params (ianz, cpara, lpara, werte, maxw) 
!              IF (ier_num.eq.0) THEN 
!                 iflag = - iabs (nint (werte (1) ) ) 
!                 CALL ini_ran (iflag) 
!              ENDIF 
!           ELSEIF (ianz.eq.3) THEN 
!              CALL ber_params (ianz, cpara, lpara, werte, maxw) 
!              IF (ier_num.eq.0) THEN 
!                 CALL ini_ran_ix(3, iwerte)
!              ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ENDIF 
      ELSE 
         np = 1
         iwerte(1) = 0
         CALL ini_ran_ix(np, iwerte)
!        CALL ini_ran (0) 
      ENDIF 
      END SUBROUTINE do_seed                        
!*****7***********************************************************      
      SUBROUTINE do_prompt (prom) 
!*                                                                      
!     This routine prints the prompt on the screen                      
!-                                                                      
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) prom 
      INTEGER len_str 
!                                                                       
      IF (                                                              &
      prompt_status.eq.PROMPT_ON.or.prompt_status.eq.PROMPT_REDIRECT)   &
      THEN                                                              
         WRITE (output_io, '(1X,A,'' > '')',advance='no') prom (1:len_str (prom) ) 
      ENDIF 
!                                                                       
      END SUBROUTINE do_prompt                      
!*****7***********************************************************      
      LOGICAL FUNCTION str_comp (a, b, j, la, lb) 
!-                                                                      
!     compares the first non blank characters of the two strings        
!     for equality. At least j characters must be identical.            
!+                                                                      
      IMPLICIT none 
!                                                                       
      CHARACTER ( * ) a, b 
      INTEGER i, j, la, lb, ia, ib 
!                                                                       
      IF (la.eq.0.or.lb.eq.0) THEN 
         str_comp = .false. 
      ELSE 
         ia = min (index (a, ' ') , la) 
         ib = min (index (b, ' ') , lb) 
         IF (ia.eq.0) THEN 
            ia = la 
         ENDIF 
         IF (ib.eq.0) THEN 
            ib = lb 
         ENDIF 
         i = min (ia, ib) 
         i = min (i, la) 
         i = min (i, lb) 
         IF (i.lt.j) THEN 
            str_comp = .false. 
         ELSE 
            str_comp = a (1:i) .eq.b (1:i) 
         ENDIF 
      ENDIF 
!                                                                       
      END FUNCTION str_comp                         
!*****7***********************************************************      
      SUBROUTINE do_set (zeile, lp) 
!-                                                                      
!     Sets the value of status variables                                
!+                                                                      
      USE debug_mod 
      USE envir_mod 
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 5) 
!                                                                       
      CHARACTER ( * ) zeile 
      CHARACTER(1024) cpara (maxw) 
      CHARACTER(LEN=1024) :: message
      CHARACTER(80) logfile 
      INTEGER lpara (maxw), lp 
      INTEGER :: ios
      INTEGER ianz 
      LOGICAL llog 
!                                                                       
      LOGICAL str_comp 
      INTEGER len_str 
!                                                                       
      IF (zeile.ne.' ') THEN 
         CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
         IF (ier_num.eq.0) THEN 
!                                                                       
!----- ---- set error                                                   
!                                                                       
            IF (str_comp (cpara (1) , 'error', 1, lpara (1) , 5) ) THEN 
               IF (ianz.eq.2) THEN 
                  IF (str_comp (cpara (2) , 'cont', 2, lpara (2) , 4) ) &
                  THEN                                                  
                     ier_sta = ER_S_CONT 
                  ELSEIF (str_comp (cpara (2) , 'exit', 2, lpara (2) ,  &
                  4) ) THEN                                             
                     ier_sta = ER_S_EXIT 
                  ELSEIF (str_comp (cpara (2) , 'live', 2, lpara (2) ,  &
                  4) ) THEN                                             
                     ier_sta = ER_S_LIVE 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!----- ---- set prompt                                                  
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'prompt', 1, lpara (1) , 6) ) &
            THEN                                                        
               IF (ianz.ge.2) THEN 
!                                                                       
!------ ------- Third+1  optional parameter: save previous setting      
!                                                                       
                  IF (ianz.eq.4) THEN 
                     prompt_status_old = prompt_status 
                     output_status_old = output_status 
                  ENDIF 
!                                                                       
!------ ------- First+1 parameter PROMPT                                
!                                                                       
                  IF (str_comp (cpara (2) , 'on', 2, lpara (2) , 2) )   &
                  THEN                                                  
                     prompt_status = PROMPT_ON 
                     socket_status = PROMPT_ON 
!                                                                       
                  ELSEIF (str_comp (cpara (2) , 'off', 2, lpara (2) , 2)&
                  ) THEN                                                
                     prompt_status = PROMPT_OFF 
                     socket_status = PROMPT_OFF 
!                                                                       
                  ELSEIF (str_comp (cpara (2) , 'redirect', 1, lpara (2)&
                  , 8) ) THEN                                           
                     prompt_status = PROMPT_REDIRECT 
                     socket_status = PROMPT_REDIRECT 
!                                                                       
                  ELSEIF (str_comp (cpara (2) , 'old', 1, lpara (2) , 3)&
                  ) THEN                                                
                     IF (output_status.ne.OUTPUT_SCREEN) THEN 
                        CLOSE (output_io) 
                     ENDIF 
                     output_status = output_status_old 
                     prompt_status = prompt_status_old 
                     socket_status = socket_status_old 
                     IF (output_status.eq.OUTPUT_SCREEN) THEN 
                        output_io = 6 
                     ELSEIF (output_status.eq.OUTPUT_NONE) THEN 
                        output_io = 37 
                        OPEN (unit = output_io, file = nullfile, status &
                        = 'unknown',IOSTAT=ios,IOMSG=message)                                    
                        IF(ios/=0) THEN
                           ier_num = -2
                           ier_typ = ER_IO
                           ier_msg(1) ='Could not open the NULL file'
                           ier_msg(2) = message(1:MAX(1,MIN(80,LEN_TRIM(message))))
                           RETURN
                        ENDIF
                     ELSEIF (output_status.eq.OUTPUT_FILE) THEN 
                        output_io = 37 
                        logfile = pname (1:len_str (pname) ) //'.log' 
                        INQUIRE (file = logfile, exist = llog) 
                        IF (llog) THEN 
                           CALL oeffne_append (output_io, logfile, 'old')
                           IF (ier_num.ne.0) RETURN 
!DBG                    open(unit=output_io,file=logfile,               
!DBG     &                   status='old',access='append')              
!DBG95     &                 status='old',access='sequential')          
                        ELSE 
                           OPEN (unit = output_io, file = logfile,      &
                           status = 'new',IOSTAT=ios,IOMSG=message)                                    
                           IF(ios/=0) THEN
                              ier_num = -2
                              ier_typ = ER_IO
                              ier_msg(1) ='Could not open the logfile'
                              ier_msg(2) = logfile
                              ier_msg(3) = message(1:MAX(1,MIN(80,LEN_TRIM(message))))
                              RETURN
                           ENDIF
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!------ ------- Second+1 optional parameter general output              
!                                                                       
                  IF (ianz.ge.3) THEN 
                     IF (str_comp (cpara (3) , 'on', 2, lpara (3) , 2) )&
                     THEN                                               
                        IF (output_status.ne.OUTPUT_SCREEN) THEN 
                           CLOSE (output_io) 
                        ENDIF 
                        output_status = OUTPUT_SCREEN 
                        output_io = 6 
!                                                                       
                     ELSEIF (str_comp (cpara (3) , 'off', 2, lpara (3) ,&
                     3) ) THEN                                          
                        IF (output_status.ne.OUTPUT_SCREEN) THEN 
                           CLOSE (output_io) 
                        ENDIF 
                        output_status = OUTPUT_NONE 
                        output_io = 37 
                        OPEN (unit = output_io, file = nullfile, status &
                        = 'unknown',IOSTAT=ios,IOMSG=message)                                    
                        IF(ios/=0) THEN
                           ier_num = -2
                           ier_typ = ER_IO
                           ier_msg(1) ='Could not open the logfile'
                           ier_msg(2) = logfile
                           ier_msg(3) = message(1:MAX(1,MIN(80,LEN_TRIM(message))))
                           RETURN
                        ENDIF
!                                                                       
                     ELSEIF (str_comp (cpara (3) , 'file', 2, lpara (3) &
                     , 4) ) THEN                                        
                        IF (output_status.ne.OUTPUT_SCREEN) THEN 
                           CLOSE (output_io) 
                        ENDIF 
                        output_status = OUTPUT_FILE 
                        output_io = 37 
                        logfile = pname (1:len_str (pname) ) //'.log' 
                        INQUIRE (file = logfile, exist = llog) 
                        IF (llog) THEN 
                           CALL oeffne_append (output_io, logfile, 'old')
                           IF (ier_num.ne.0) RETURN 
!DBG                    open(unit=output_io,file=logfile,               
!DBG     &                   status='old',access='append')              
!DBG95     &                 status='old',access='sequential')          
                        ELSE 
                           OPEN (unit = output_io, file = logfile,      &
                           status = 'new',IOSTAT=ios,IOMSG=message)                              
                           IF(ios/=0) THEN
                              ier_num = -2
                              ier_typ = ER_IO
                              ier_msg(1) ='Could not open the logfile'
                              ier_msg(2) = logfile
                              ier_msg(3) = message(1:MAX(1,MIN(80,LEN_TRIM(message))))
                              RETURN
                           ENDIF
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ENDIF 
                  WRITE (output_io, * ) 
!                                                                       
                  IF (dbg) THEN 
                     WRITE ( *, 5000) prompt_status, prompt_status_old 
                     WRITE ( *, 5010) output_status, output_status_old 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!----- ---- set debug                                                   
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'debug', 2, lpara (1) , 5) )  &
            THEN                                                        
               IF (ianz.eq.2) THEN 
                  dbg = (cpara (2) (1:2) .eq.'on') 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
 5000 FORMAT    (' debug  > Prompt (current, old) : ',2I3) 
 5010 FORMAT    (' debug  > Output (current, old) : ',2I3) 
!                                                                       
      END SUBROUTINE do_set                         
!*****7*****************************************************************
      SUBROUTINE echo (zeile, lp) 
!-                                                                      
!     writes an echo to the screen                                      
!+                                                                      
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxp 
      PARAMETER (maxp = 12) 
      CHARACTER ( * ) zeile 
      CHARACTER(1024) string 
      CHARACTER(1024) cpara (maxp) 
      CHARACTER(1024) cstr 
      INTEGER lpara (maxp) 
      INTEGER ianz 
      INTEGER lp, i, il 
      INTEGER iko, iqo, iqo2, lstring 
      REAL werte (maxp) 
!                                                                       
      INTEGER len_str 
      INTEGER socket_send 
!                                                                       
!     Find any "" which would mean that we need parameter substitution  
!                                                                       
      iqo = index (zeile (1:lp) , '"') 
      IF (iqo.eq.0) THEN 
!                                                                       
!     --None foud, harmless echo                                        
!                                                                       
         WRITE (output_io, 2010) zeile (1:lp) 
         WRITE (cstr, 2010) zeile (1:lp) 
         IF (lconn.and.lsocket) THEN 
            il = len_str (cstr) 
            ier_num = socket_send (s_conid, cstr, il) 
            IF(ier_num < 0) THEN
               ier_num = -19
               RETURN
            ELSE
               ier_num = 0
            ENDIF
         ENDIF 
!                                                                       
!        IF (output_status.eq.OUTPUT_FILE) THEN 
!           WRITE (output_io, 2010) zeile (1:lp) 
!        ENDIF 
      ELSE 
!                                                                       
!     --Look for matching ""                                            
!                                                                       
         iqo2 = index (zeile (iqo + 1:lp) , '"') 
         IF (iqo2.eq.0) THEN 
            ier_num = -  4 
            ier_typ = ER_COMM 
            RETURN 
         ENDIF 
!                                                                       
!     --save the string in quotation marks for later use as             
!       first parameter                                                 
!                                                                       
         iqo2 = iqo2 + iqo 
         iko = index (zeile (iqo2 + 1:lp) , ',') 
         IF (iko.ne.0) THEN 
            string = zeile (iqo2 + iko + 1:lp) 
            lstring = - (lp - iqo2 - iko) 
!                                                                       
!     --get all other parameters                                        
!                                                                       
            CALL get_params (string, ianz, cpara, lpara, maxp, lstring) 
         ELSE 
            string = ' ' 
            lstring = 1 
            ianz = 0 
         ENDIF 
!                                                                       
         IF (ier_num.eq.0) THEN 
            DO i = ianz, 1, - 1 
            cpara (i + 1) = cpara (i) 
            lpara (i + 1) = lpara (i) 
            ENDDO 
            cpara (1) = zeile (1:iqo2) 
            lpara (1) = iqo2 
            ianz = ianz + 1 
            CALL do_build_name (ianz, cpara, lpara, werte, maxp, 1) 
            IF (ier_num.eq.0) THEN 
!                                                                       
!     ------The first comma that follows the quotation marks must be    
!           omitted, all others retained as part of the echo            
!                                                                       
               IF (ianz.eq.1) THEN 
                  WRITE (output_io, 2000) cpara (ianz) (1:lpara (ianz) ) 
                  WRITE (cstr, 2000) cpara (ianz) (1:lpara (ianz) ) 
!                 IF (output_status.eq.OUTPUT_FILE) THEN 
!                    WRITE (output_io, 2000) cpara (ianz) (1:lpara (    &
!                    ianz) )                                            
!                 ENDIF 
               ELSEIF (ianz.eq.2) THEN 
                  WRITE (output_io, 2000) cpara (1) (1:lpara (1) ), cpara (    &
                  ianz) (1:lpara (ianz) )                               
                  WRITE (cstr, 2000) cpara (1) (1:lpara (1) ), cpara (  &
                  ianz) (1:lpara (ianz) )                               
!                 IF (output_status.eq.OUTPUT_FILE) THEN 
!                    WRITE (output_io, 2000) cpara (1) (1:lpara (1) ),  &
!                    cpara (ianz) (1:lpara (ianz) )                     
!                 ENDIF 
               ELSE 
                  WRITE (output_io, 2000) cpara (1) (1:lpara (1) ) , (cpara ( &
                  i) (1:lpara (i) ) , ',', i = 2, ianz - 1) , cpara (   &
                  ianz) (1:lpara (ianz) )                               
                  WRITE (cstr, 2000) cpara (1) (1:lpara (1) ) , (cpara (&
                  i) (1:lpara (i) ) , ',', i = 2, ianz - 1) , cpara (   &
                  ianz) (1:lpara (ianz) )                               
!                 IF (output_status.eq.OUTPUT_FILE) THEN 
!                    WRITE (output_io, 2000) cpara (1) (1:lpara (1) ) , &
!                    (cpara (i) (1:lpara (i) ) , ',', i = 2, ianz - 1) ,&
!                    cpara (ianz) (1:lpara (ianz) )                     
!                 ENDIF 
               ENDIF 
               IF (lconn.and.lsocket) THEN 
                  il = len_str (cstr) 
                  ier_num = socket_send (s_conid, cstr, il) 
                  IF(ier_num < 0) THEN
                     ier_num = -19
                     RETURN
                  ELSE
                     ier_num = 0
                  ENDIF
               ENDIF 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
 2000 FORMAT    (1x,21a) 
 2010 FORMAT    (1x,  a) 
!                                                                       
      END SUBROUTINE echo                           
!*****7**************************************************************** 
      SUBROUTINE ersetz_variable (string, laenge) 
!-                                                                      
!       replaces a substring in an expression by the value of the       
!       appropriate user defined variable.                              
!     This is needed if the parameter is read.                          
!                                                                       
!       Version : 1.0                                                   
!       Date    : 22 Oct 03                                             
!                                                                       
!       Author  : R.B. Neder  (reinhard.neder@mail.uni-wuerzburg.de)    
!+                                                                      
      USE errlist_mod 
      USE variable_mod
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) string 
      CHARACTER(1024) zeile 
      CHARACTER(1024) dummy 
!                                                                       
      INTEGER laenge 
      INTEGER i, ianf, iend, ll 
      INTEGER linsert 
!                                                                       
      INTEGER len_str 
!                                                                       
      linsert = 0
      ll = laenge 
!                                                                       
!     Loop over all defined variables and search for coincidences       
!     of the variable name. Works since names like "cos" etc are        
!     forbidden, and the names have been sorted in alphabitcally        
!     descending order.                                                 
!                                                                       
!                                                                       
!     --If an apostrophe is found, ignore the string                    
!                                                                       
      IF (max (index (string, '''') , index (string, '"') ) .gt.0) THEN 
         RETURN 
      ENDIF 
      DO i = 1, var_num 
      ianf = index (string, var_name (i) (1:var_l (i) ) ) 
      DO while (ianf.ne.0) 
      zeile = ' ' 
      iend = ianf + var_l (i) - 1 
      IF (ianf.gt.1) zeile (1:ianf - 1) = string (1:ianf - 1) 
      IF (var_type (i) .eq.VAR_TYPE_REAL) THEN 
                                                                        
         WRITE (dummy (1:15) , '(e15.8e2)') var_val (i) 
         dummy (12:12) = 'e' 
         ll = 15 
         CALL rem_bl (dummy, ll) 
         zeile (ianf:ianf + ll - 1) = dummy (1:ll) 
         linsert = ll 
      ELSEIF (var_type (i) .eq.VAR_TYPE_INTE) THEN 
         WRITE (dummy (1:15) , '(i15)') nint (var_val (i) ) 
         ll = 15 
         CALL rem_bl (dummy, ll) 
         zeile (ianf:ianf + ll - 1) = dummy (1:ll) 
         linsert = ll 
      ELSEIF (var_type (i) .eq.VAR_TYPE_CHAR) THEN 
!DBG_RBN            ll = len_str(var_char(i))                           
!DBG_RBN            zeile(ianf:ianf+ll-1)= var_char(i)(1:ll)            
!DBG_RBN            linsert = ll                                        
         ll = len_str (var_char (i) ) 
         zeile (ianf:ianf) = '''' 
         zeile (ianf + 1:ianf + ll) = var_char (i) (1:ll) 
         zeile (ianf + ll + 1:ianf + ll + 1) = '''' 
         linsert = ll + 2 
!DBG_RBN      write(*,*) 'in ERSETZ'                                    
!DBG_RBN      write(*,*) ' ll,ianf,ianf+ll-1 ',ll,ianf,ianf+ll-1        
!DBG_RBN      write(*,*) ' ZEILE >',zeile(1:ianf+ll+1),'<'              
      ENDIF 
      ll = laenge+linsert - (iend-ianf + 1) 
      IF (iend.lt.laenge) zeile (ianf + linsert:ll) = string (iend+1:   &
      laenge)                                                           
      string = zeile 
      laenge = ll 
!DBG_RBN      write(*,*) ' ZEILE >',zeile(1:ll)                         
      IF (max (index (string, '''') , index (string, '"') ) .gt.0) THEN 
         RETURN 
      ENDIF 
      ianf = index (string, var_name (i) (1:var_l (i) ) ) 
      ENDDO 
      ENDDO 
      END SUBROUTINE ersetz_variable                
!*****7**************************************************************** 
      SUBROUTINE upd_variable (string, laenge, wert, dummy, length) 
!-                                                                      
!       updates the user defined variable by the value wert             
!                                                                       
!       Version : 1.0                                                   
!       Date    : 22 Oct 03                                             
!                                                                       
!       Author  : R.B. Neder  (reinhard.neder@mail.uni-wuerzburg.de)    
!+                                                                      
      USE lib_f90_allocate_mod
      USE errlist_mod 
      USE param_mod
      USE variable_mod
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) string 
      CHARACTER ( * ) dummy 
!                                                                       
      INTEGER laenge 
      REAL wert 
      INTEGER i 
      INTEGER length 
!                                                                       
      ier_num = - 24 
      ier_typ = ER_FORT 
!                                                                       
!     loop over all variable names. Strict equality is required         
!                                                                       
      DO i = 1, var_num 
      IF (string (1:laenge) .eq.var_name (i) (1:var_l (i) ) ) THEN 
         IF (var_type (i) .eq.VAR_TYPE_REAL) THEN 
            var_val (i) = wert 
         ELSEIF (var_type (i) .eq.VAR_TYPE_INTE) THEN 
            var_val (i) = nint (wert) 
         ELSEIF (var_type (i) .eq.VAR_TYPE_CHAR) THEN 
            var_char (i) = dummy (1:length) 
         ENDIF 
         IF(string (1:laenge) == 'REF_DIMENSION') THEN
            IF(var_val (i)>UBOUND(ref_para,1)) THEN
               CALL alloc_ref_para(NINT(wert))
            ENDIF
         ENDIF
         ier_num = 0 
         ier_typ = ER_NONE 
      ENDIF 
      ENDDO 
      END SUBROUTINE upd_variable                   
!*****7**************************************************************** 
      SUBROUTINE define_variable (zeile, lp, is_diffev) 
!-                                                                      
!       Allows the user to define variables                             
!                                                                       
!       Version : 1.0                                                   
!       Date    : 22 Oct 03                                             
!                                                                       
!       Author  : R.B. Neder  (reinhard.neder@mail.uni-wuerzburg.de)    
!+                                                                      
      USE errlist_mod 
      USE prompt_mod 
      USE variable_mod
      IMPLICIT none 
!                                                                       
      INTERFACE
         SUBROUTINE validate_variable (zeile, lp)
         IMPLICIT none 
         CHARACTER (LEN=*), INTENT(IN) :: zeile 
         INTEGER,           INTENT(IN) :: lp 
         END SUBROUTINE validate_variable
      END INTERFACE
!
CHARACTER (LEN=* ), INTENT(INOUT) :: zeile 
INTEGER           , INTENT(INOUT) :: lp 
LOGICAL           , INTENT(IN)    :: is_diffev
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 3) 
      LOGICAL , PARAMETER :: no_diffev = .FALSE.
                                                                        
      INTEGER ianz 
!                                                                       
      CHARACTER(1024) cpara (maxw) 
      INTEGER lpara (maxw) 
      REAL werte (maxw) 
!                                                                       
      CHARACTER(1024) c_type, c_temp, c_init 
      INTEGER l_type, l_temp 
      INTEGER ccc_type 
      INTEGER i, j 
      LOGICAL l_init 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      ccc_type = 0
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
      IF (ier_num.ne.0) RETURN 
!                                                                       
      IF (str_comp (cpara (1) , 'real', 3, lpara (1) , 4) .or.str_comp (&
      cpara (1) , 'inte', 2, lpara (1) , 4) .or.str_comp (cpara (1) ,   &
      'char', 2, lpara (1) , 4) ) THEN                                  
!                                                                       
!     --A new variable is being defined                                 
!                                                                       
         IF (ianz.eq.2.or.ianz.eq.3) THEN 
            IF (var_num.lt.VAR_MAX) THEN 
!                                                                       
!     ----- If a free slot is available validate the name against       
!     ----- illegal names like "cos", "sin" etc.                        
!                                                                       
               CALL validate_variable (cpara (2), lpara (2) ) 
               IF (ier_num.ne.0) RETURN 
!                                                                       
!     ----- temporarily store the variable type and name and evaluate   
!     ----- the optional initialising parameter                         
!                                                                       
               c_type = cpara (1) 
               l_type = lpara (1) 
               c_temp (1:lpara (2) ) = cpara (2) (1:lpara (2) ) 
               l_temp = lpara (2) 
               werte (1) = 0.0 
               IF (str_comp (c_type, 'real', 3, l_type, 4) ) THEN 
                  ccc_type = VAR_TYPE_REAL 
               ELSEIF (str_comp (c_type, 'inte', 2, l_type, 4) ) THEN 
                  ccc_type = VAR_TYPE_INTE 
               ELSEIF (str_comp (c_type, 'char', 2, l_type, 4) ) THEN 
                  ccc_type = VAR_TYPE_CHAR 
               ENDIF 
               l_init = .false. 
               c_init = ' ' 
               IF (ianz.eq.3) THEN 
                  CALL del_params (2, ianz, cpara, lpara, maxw) 
                  IF (ier_num.ne.0) RETURN 
                  IF (ccc_type.eq.VAR_TYPE_CHAR) THEN 
                     CALL do_build_name (ianz, cpara, lpara, werte,     &
                     maxw, 1)                                           
                     c_init = cpara (1) (1:lpara (1) ) 
                  ELSE 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  ENDIF 
                  l_init = .true. 
                  IF (ier_num.ne.0) RETURN 
               ENDIF 
!                                                                       
!     ----- Make sure the variable name has not yet been defined as     
!           other variable type.                                        
!           And initialisation value is not used on old variables       
!                                                                       
               ier_num = 0 
               ier_typ = ER_NONE 
               DO i = 1, var_num 
               IF (c_temp (1:l_temp) .eq.var_name (i) ) THEN 
                  IF (ccc_type.ne.var_type (i) ) THEN 
                     ier_num = - 32 
                     ier_typ = ER_FORT 
                  ELSE 
                     IF (l_init) THEN 
                        ier_num = - 33 
                        ier_typ = ER_FORT 
                     ELSE 
                        RETURN 
                     ENDIF 
                  ENDIF 
               ENDIF 
               ENDDO 
               IF (ier_num.ne.0) THEN 
                  CALL errlist 
                  RETURN 
               ENDIF 
!                                                                       
!     ----- sort the new variable name in descending length and         
!           descending alphabetical order                               
!                                                                       
               i = var_sys + 1 
               DO while (l_temp.lt.var_l (i) .and.i.le.var_num) 
               i = i + 1 
               ENDDO 
               DO while (l_temp.eq.var_l (i) .and.llt (c_temp, var_name &
               (i) ) .and.i.le.var_num)                                 
               i = i + 1 
               ENDDO 
               DO j = var_num, i, - 1 
                  var_name (j + 1) = var_name (j) 
                  var_l    (j + 1) = var_l    (j) 
                  var_type (j + 1) = var_type (j) 
                  var_val  (j + 1) = var_val  (j) 
                  var_char (j + 1) = var_char (j) 
                  var_diff (j + 1) = var_diff (j)    ! true if refine paaram from diffev
               ENDDO 
!                                                                       
!     ----- found the proper slot, store value, name and type           
!                                                                       
               var_num = var_num + 1 
               var_name (i) (1:l_temp) = c_temp 
               var_l (i) = l_temp 
               IF (str_comp (c_type, 'real', 3, l_type, 4) ) THEN 
                  var_type (i) = VAR_TYPE_REAL 
                  var_val (i) = werte (1) 
                  var_diff (i) = is_diffev      ! true if refine param from diffev
               ELSEIF (str_comp (c_type, 'inte', 2, l_type, 4) ) THEN 
                  var_type (i) = VAR_TYPE_INTE 
                  var_val (i) = nint (werte (1) ) 
                  var_diff (i) = is_diffev      ! true if refine param from diffev
               ELSEIF (str_comp (c_type, 'char', 2, l_type, 4) ) THEN 
                  var_type (i) = VAR_TYPE_CHAR 
                  var_val (i) = 0.0 
                  var_char (i) = c_init (1:len(var_char))
                  var_diff (i) = is_diffev      ! true if refine param from diffev
               ENDIF 
            ELSE 
               ier_num = - 23 
               ier_typ = ER_FORT 
            ENDIF 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
         ENDIF 
      ELSEIF (str_comp (cpara (1) , 'show', 2, lpara (1) , 4) ) THEN 
         CALL show_variables 
      ELSEIF (str_comp (cpara (1) , 'reset', 5, lpara (1) , 5) ) THEN 
         CALL rese_variables (no_diffev)
      ELSEIF (str_comp (cpara (1) , 'delete', 3, lpara (1) , 6) ) THEN 
         CALL del_variables(MAXW, ianz, cpara, lpara, no_diffev)
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE define_variable                
!*****7**************************************************************** 
SUBROUTINE rese_variables(is_diffev)
!-
!     Removes all user variables
!+
USE variable_mod
IMPLICIT none 
!
LOGICAL, INTENT(IN)    :: is_diffev
!
INTEGER :: i, j
INTEGER :: ndel
!
DO i=var_sys+1, var_num
   IF(var_diff(i) .EQV. is_diffev) THEN
      var_name( i) = ' '
      var_char( i) = ' '
      var_l   ( i) = 1
      var_type( i) = 0
      var_diff( i) = .FALSE.
      var_val ( i) = 0
   ENDIF
ENDDO
ndel = 0
i = var_sys+1
remove: DO 
   IF(var_name(i) == ' ') THEN
      ndel = ndel +1
      IF(i>var_num-ndel) EXIT remove
      DO j=i, var_num-ndel
         var_name(j) = var_name(j+1)
         var_char(j) = var_char(j+1)
         var_l   (j) = var_l   (j+1)
         var_type(j) = var_type(j+1)
         var_diff(j) = var_diff(j+1)
         var_val (j) = var_val (j+1)
      ENDDO
   ELSE
      i=i+1
   ENDIF
ENDDO remove
var_num = var_num - ndel
!
END SUBROUTINE rese_variables 
!
!*****7**************************************************************** 
 SUBROUTINE del_variables (MAXW, ianz, cpara, lpara, is_diffev)
!-
!     Removes all or specified user variables
!+
USE errlist_mod
USE variable_mod
!
IMPLICIT none 
!
INTEGER                               , INTENT(IN)    :: MAXW
INTEGER                               , INTENT(IN)    :: ianz
CHARACTER(LEN=1024), DIMENSION(1:MAXW), INTENT(INOUT) :: cpara
INTEGER            , DIMENSION(1:MAXW), INTENT(INOUT) :: lpara
LOGICAL                               , INTENT(IN)    :: is_diffev
!
INTEGER :: i, j, k, upper
!
LOGICAL :: str_comp
!
IF(ianz==1) THEN
   CALL rese_variables (is_diffev)
ELSEIF(str_comp (cpara (2) , 'all', 3, lpara(1), 3) ) THEN 
   CALL rese_variables (is_diffev)
ELSE
   main: DO i=2, ianz
      upper = var_num
      loop: DO j=var_sys+1, upper
         IF(cpara(i) == var_name(j)) THEN 
            IF(var_diff(j) .EQV. is_diffev) THEN
               DO k=j+1, var_num
                  var_name(k-1) = var_name(k)
                  var_char(k-1) = var_char(k)
                  var_l   (k-1) = var_l(k)
                  var_type(k-1) = var_type(k)
                  var_diff(k-1) = var_diff(k)
                  var_val (k-1) = var_val(k)
               ENDDO
               var_num = var_num - 1
               CYCLE main
            ELSE
               ier_num =  -39
               ier_typ = ER_FORT
               ier_msg(1) = 'Offending variable: '//cpara(i)(1:LEN_TRIM(cpara(i)))
               RETURN
            ENDIF
         ENDIF
      ENDDO loop
      ier_num = -24
      ier_typ = ER_FORT
      ier_msg(1) = 'Offending variable: '//cpara(i)(1:LEN_TRIM(cpara(i)))
      RETURN
   ENDDO main
ENDIF
!
END SUBROUTINE del_variables 
!*****7**************************************************************** 
SUBROUTINE show_variables 
!-                                                                      
!     shows the variable definitions                                    
!+                                                                      
USE prompt_mod 
USE variable_mod
IMPLICIT none 
!
!
CHARACTER(LEN=6), DIMENSION(0:1) :: cdiffev
INTEGER :: i , j
!
INTEGER :: len_str 
DATA cdiffev/'DIFFEV','      '/
!
IF (var_num.gt.0) THEN 
   WRITE (output_io, 2000) var_num, VAR_MAX 
   DO i = 1, var_num 
      j=1
      IF(var_diff(i)) j=0
      IF (var_type (i) .eq.VAR_TYPE_REAL) THEN 
         IF (ABS(var_val(i)) .lt.1e-5.or. ABS(var_val(i)).ge.1e6) THEN
            WRITE(output_io, 2100) var_name (i), var_val (i) , cdiffev(j)
         ELSE 
            WRITE(output_io, 2150) var_name (i), var_val (i) , cdiffev(j)
         ENDIF 
      ELSEIF (var_type (i) .eq.VAR_TYPE_INTE) THEN 
         WRITE(output_io, 2200) var_name (i), nint (var_val (i) ) , cdiffev(j)
      ELSEIF (var_type (i) .eq.VAR_TYPE_CHAR) THEN 
         WRITE(output_io, 2300) var_name(i), var_char(i)(1:len_str(var_char(i))), cdiffev(j)
      ENDIF 
   ENDDO 
ELSE 
   WRITE (output_io, 2050) VAR_MAX 
ENDIF 
WRITE (output_io, * ) 
 2000 FORMAT    (' User defined variables',i3,                          &
     &                  ' Maximum number: ',i3/)                        
 2050 FORMAT    (' No user defined variables',                          &
     &                  ' Maximum number: ',i3/)                        
 2100 FORMAT    (' Name: ',a30,' = ',8x,e20.8e2,' Real      ',a) 
 2150 FORMAT    (' Name: ',a30,' = ',8x,f16.8  ,'     Real      ',a) 
 2200 FORMAT    (' Name: ',a30,' = ',i15,13x,   ' Integer   ',a) 
 2300 FORMAT    (' Name: ',a30,' = ''',a,     ''' Character ',a) 
END SUBROUTINE show_variables                 
!*****7**************************************************************** 
      SUBROUTINE validate_variable (zeile, lp) 
!-                                                                      
!       Checks whether the variable name is legal                       
!     All intrinsic function names, variable names and parts of         
!     these names are illegal                                           
!                                                                       
!       Version : 1.0                                                   
!       Date    : 22 Oct 03                                             
!                                                                       
!       Author  : R.B. Neder  (reinhard.neder@mail.uni-wuerzburg.de)    
!+                                                                      
      USE charact_mod
      USE errlist_mod 
      USE set_sub_generic_mod
      IMPLICIT none 
!                                                                       
      CHARACTER (LEN=*), INTENT(IN) :: zeile 
      INTEGER,           INTENT(IN) :: lp 
!                                                                       
      INTEGER, PARAMETER :: reserved_n = 92
!
      CHARACTER(LEN=14), DIMENSION(reserved_n) :: reserved
      INTEGER i, ii 
      LOGICAL lok 
!                                                                       
      DATA reserved / 'asin', 'acos', 'atan', 'asind', 'acosd', 'atand',    &
      'sin', 'cos', 'tan', 'sind', 'cosd', 'tand', 'sinh', 'cosh',          &
      'tanh', 'sqrt', 'exp', 'ln', 'abs', 'mod', 'max', 'min', 'int',       &
      'nint', 'frac', 'ran', 'gran', 'logn', 'do', 'enddo', 'if', 'elseif', &
      'endif', 'else', 'then', 'while', 'until', 'lt', 'le', 'gt', 'ge',    &
      'eq', 'and', 'or', 'xor', 'break', 'by', 'continue', 'stop', 'exit',  &
      'echo', 'eval', 'fopen', 'fclose', 'fformat', 'fexist', 'fend',       &
      'fput', 'fget', 'fsub', 'help', 'learn', 'lend', 'seed', 'set',       &
      'show', 'sleep', 'socket', 'system', 'wait', 'variable', 'cd',        &
      'getcwd', 'geetenv',                                                  &
      'i', 'r', 'res' , 'gskew', 'pois', 'gbox', 'date', 'fdate', 'fmodt',  &
      'REF_GENERATION',                                                     &
      'REF_MEMBER', 'REF_CHILDREN', 'REF_DIMENSION', 'REF_KID',             &
      'REF_INDIV', 'REF_NINDIV', 'REF_COMPUTE','PI'/
!                                                                       
      ier_num = 0 
      ier_typ = ER_NONE 
!                                                                       
      DO i = 1, reserved_n 
         IF (index (reserved (i), zeile (1:lp) ) .NE.0) THEN 
            ier_num = - 25 
            ier_typ = ER_FORT 
         ENDIF 
      ENDDO 
!                                                                       
!     Check against variables/functions of the main program             
!                                                                       
      IF (ier_num.eq.0) THEN 
         CALL p_validate_var_spec (zeile, lp) 
      ENDIF 
!                                                                       
!     Check that the name contains only letters, Numbers and the "_"    
!                                                                       
      IF (ier_num.eq.0) THEN 
         lok = .true. 
         DO i = 1, lp 
            ii = iachar (zeile (i:i) ) 
            lok = lok.and. (zero.le.ii.and.ii.le.nine.or.aa.le.ii.and. & 
                            ii.le.zz .or.u.eq.ii.or.a.le.ii.and.ii.le.z)                               
         ENDDO 
         IF (.not.lok) THEN 
            ier_num = - 26 
            ier_typ = ER_FORT 
         ENDIF 
      ENDIF 
!                                                                       
      END SUBROUTINE validate_variable              
!*****7**************************************************************** 
      SUBROUTINE do_show_generic (cpara, lpara, maxw) 
!-                                                                      
!     shows something related to the general command language           
!+                                                                      
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
      INTEGER maxw 
      CHARACTER ( * ) cpara (maxw) 
      INTEGER lpara (maxw) 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      IF (str_comp (cpara (1) , 'error', 2, lpara (1) , 5) ) THEN 
         CALL do_show_error 
!                                                                       
!     ----Show result array                'result'                     
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'res', 1, lpara (1) , 3) ) THEN 
         CALL do_show_res 
!                                                                       
!     ----Show variables                   'variables'                  
!                                                                       
      ELSEIF (str_comp (cpara (1) , 'variables', 1, lpara (1) , 9) )    &
      THEN                                                              
         CALL show_variables 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE do_show_generic                
!*****7*****************************************************************
      SUBROUTINE do_show_res 
!-                                                                      
!     Shows the result array                                            
!+                                                                      
      USE errlist_mod 
      USE param_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER i, j, k, k1, k2 
!                                                                       
      IF (nint (res_para (0) ) .eq.0) THEN 
         WRITE (output_io, * ) 'Result array is empty' 
      ELSE 
         WRITE (output_io, 2000) nint (res_para (0) ) 
         j = nint (res_para (0) ) / 5 
         IF (mod (nint (res_para (0) ), 5) .eq.0) THEN 
            j = j - 1 
         ENDIF 
         DO i = 0, j 
         k1 = 5 * i + 1 
         k2 = min (5 * i + 5, nint (res_para (0) ) ) 
         WRITE (output_io, 2001) (res_para (k), k = k1, k2) 
         ENDDO 
      ENDIF 
!                                                                       
 2000 FORMAT    ( i8,' Values in the result array') 
 2001 FORMAT    (5(2x,g13.7)) 
      END SUBROUTINE do_show_res                    
!*****7*****************************************************************
      SUBROUTINE do_show_error 
!-                                                                      
!     Shows the result array                                            
!+                                                                      
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
!------ - Error status setting                                          
!                                                                       
      IF (ier_sta.eq.ER_S_CONT) THEN 
         WRITE (output_io, 2100) 
      ELSE 
         WRITE (output_io, 2105) 
      ENDIF 
!                                                                       
      RETURN 
!                                                                       
 2100 FORMAT  (' Program continues after display of error message') 
 2105 FORMAT  (' Program terminates after display of error message') 
      END SUBROUTINE do_show_error                  
