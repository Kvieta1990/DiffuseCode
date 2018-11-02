MODULE DIFFEV_MPI_MOD
!
CONTAINS
!*****7***************************************************************
SUBROUTINE RUN_MPI_INIT 
!
! NO MPI Version for standalone
!
USE run_mpi_mod
USE errlist_mod
USE variable_mod
!
IMPLICIT none
!
!
run_mpi_myid     = 0
run_mpi_numprocs = 1
run_mpi_active   = .false.
ier_num  = 0
ier_typ  = ER_NONE
var_val(VAR_NUM_NODES) = 0
!
!write(*,*) 'MPI is not active '
!
END SUBROUTINE RUN_MPI_INIT
!
!*****7***************************************************************
SUBROUTINE RUN_MPI_MASTER 
!
USE run_mpi_mod
USE errlist_mod
!
IMPLICIT none
!
ier_num = -21
ier_typ = ER_APPL
!
!
END SUBROUTINE RUN_MPI_MASTER
!
!*****7***************************************************************
SUBROUTINE RUN_MPI_SLAVE
!
USE run_mpi_mod
USE errlist_mod
!
IMPLICIT none
!
!
ier_num = -21
ier_typ = ER_APPL
!
END SUBROUTINE RUN_MPI_SLAVE
!
!*****7***************************************************************
SUBROUTINE run_mpi_finalize
!
IMPLICIT none
!
END SUBROUTINE run_mpi_finalize
END MODULE DIFFEV_MPI_MOD
