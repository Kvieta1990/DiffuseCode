MODULE spcgr_mod
!+
!     Variables needed for the spacegroups
!-
PUBLIC
SAVE
!
INTEGER, PARAMETER  ::  SPCGR_MAX  =  314
!
CHARACTER(LEN=16), DIMENSION(SPCGR_MAX)     ::  spcgr_name
INTEGER          , DIMENSION(SPCGR_MAX,2)   ::  spcgr_num 
INTEGER          , DIMENSION(SPCGR_MAX)     ::  spcgr_syst
!
!
END MODULE spcgr_mod
