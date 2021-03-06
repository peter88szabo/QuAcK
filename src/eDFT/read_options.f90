subroutine read_options(method,x_rung,x_DFA,c_rung,c_DFA,SGn,nEns,wEns,aCC_w1,aCC_w2, & 
                        maxSCF,thresh,DIIS,max_diis,guess_type,ortho_type)

! Read DFT options

  implicit none

  include 'parameters.h'

! Local variables

  integer                       :: I

! Output variables

  character(len=8),intent(out)  :: method
  integer,intent(out)           :: x_rung,c_rung
  character(len=12),intent(out) :: x_DFA, c_DFA
  integer,intent(out)           :: SGn
  integer,intent(out)           :: nEns
  double precision,intent(out)  :: wEns(maxEns)
  double precision,intent(out)  :: aCC_w1(3)
  double precision,intent(out)  :: aCC_w2(3)

  integer,intent(out)           :: maxSCF
  double precision,intent(out)  :: thresh
  logical,intent(out)           :: DIIS
  integer,intent(out)           :: max_diis
  integer,intent(out)           :: guess_type
  integer,intent(out)           :: ortho_type

! Local variables

  character(len=1)              :: answer

! Open file with method specification

  open(unit=1,file='input/dft')

! Default values

  method  = 'GOK-RKS'
  x_rung  = 1
  c_rung  = 1
  x_DFA   = 'RS51'
  c_DFA   = 'RVWN5'
  SGn     = 0
  wEns(:) = 0d0

! Restricted or unrestricted calculation

  read(1,*)
  read(1,*) method

! EXCHANGE: read rung of Jacob's ladder

  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*) x_rung,x_DFA

! CORRELATION: read rung of Jacob's ladder

  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*)
  read(1,*) c_rung,c_DFA

! Read SG-n grid

  read(1,*)
  read(1,*) SGn

! Read number of states in ensemble

  read(1,*)
  read(1,*) nEns

  if(nEns.gt.maxEns) then
    write(*,*) ' Number of states in ensemble too big!! ' 
    stop
  endif

  write(*,*)'----------------------------------------------------------'
  write(*,'(A33,I3)')'  Number of states in ensemble = ',nEns
  write(*,*)'----------------------------------------------------------'
  write(*,*) 
  
! Read ensemble weights
  read(1,*)
  read(1,*) (wEns(I),I=2,nEns)
  wEns(1) = 1d0 - sum(wEns)

  write(*,*)'----------------------------------------------------------'
  write(*,*)' Ensemble weights '
  write(*,*)'----------------------------------------------------------'
  call matout(nEns,1,wEns)
  write(*,*) 
  
! Read parameters for weight-dependent functional
  read(1,*)
  read(1,*) (aCC_w1(I),I=1,3)
  read(1,*) (aCC_w2(I),I=1,3)

  write(*,*)'----------------------------------------------------------'
  write(*,*)' parameters for w1-dependant exchange functional coefficient '
  write(*,*)'----------------------------------------------------------'
  call matout(3,1,aCC_w1)
  write(*,*)

  write(*,*)'----------------------------------------------------------'
  write(*,*)' parameters for w2-dependant exchange functional coefficient '
  write(*,*)'----------------------------------------------------------'
  call matout(3,1,aCC_w2)
  write(*,*) 

! Read KS options

  maxSCF     = 64
  thresh     = 1d-6
  DIIS       = .false.
  max_diis   = 5
  guess_type = 1
  ortho_type = 1

  read(1,*)
  read(1,*) maxSCF,thresh,answer,max_diis,guess_type,ortho_type

  if(answer == 'T') DIIS = .true.

  if(.not.DIIS) max_diis = 1

! Close file with options

  close(unit=1)

end subroutine read_options
