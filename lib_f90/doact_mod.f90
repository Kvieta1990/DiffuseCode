MODULE doact_mod
!+
!     Variables used to indicate whether do-loop 
!     of if block is active.
!-
   IMPLICIT NONE
   PUBLIC
   SAVE
!
   LOGICAL  ::  lblock
   LOGICAL  ::  lblock_dbg
   LOGICAL  ::  lblock_read
   LOGICAL  ::  lmacro_close      = .TRUE.
!
!
END MODULE doact_mod
