subroutine linear_response_pp(ispin,ortho_eigvec,BSE,nBas,nC,nO,nV,nR,nOO,nVV, & 
                              e,ERI,Omega1,X1,Y1,Omega2,X2,Y2,EcRPA)

! Compute the p-p channel of the linear response: see Scuseria et al. JCP 139, 104113 (2013)

  implicit none
  include 'parameters.h'

! Input variables

  logical,intent(in)            :: ortho_eigvec
  logical,intent(in)            :: BSE
  integer,intent(in)            :: ispin,nBas,nC,nO,nV,nR
  integer,intent(in)            :: nOO
  integer,intent(in)            :: nVV
  double precision,intent(in)   :: e(nBas)
  double precision,intent(in)   :: ERI(nBas,nBas,nBas,nBas)
  
! Local variables

  logical                       :: dump_matrices = .false.
  integer                       :: ab,cd,ij,kl
  integer                       :: p,q,r,s
  double precision              :: trace_matrix
  double precision              :: EcRPA1
  double precision              :: EcRPA2
  double precision,allocatable  :: B(:,:)
  double precision,allocatable  :: C(:,:)
  double precision,allocatable  :: D(:,:)
  double precision,allocatable  :: M(:,:)
  double precision,allocatable  :: Z(:,:)
  double precision,allocatable  :: Omega(:)

! Output variables

  double precision,intent(out)  :: Omega1(nVV)
  double precision,intent(out)  :: X1(nVV,nVV)
  double precision,intent(out)  :: Y1(nOO,nVV)
  double precision,intent(out)  :: Omega2(nOO)
  double precision,intent(out)  :: X2(nVV,nOO)
  double precision,intent(out)  :: Y2(nOO,nOO)
  double precision,intent(out)  :: EcRPA

! Memory allocation

  allocate(B(nVV,nOO),C(nVV,nVV),D(nOO,nOO),M(nOO+nVV,nOO+nVV),Z(nOO+nVV,nOO+nVV),Omega(nOO+nVV))

! Build B, C and D matrices for the pp channel

  call linear_response_B_pp(ispin,nBas,nC,nO,nV,nR,nOO,nVV,e,ERI,B)
  call linear_response_C_pp(ispin,nBas,nC,nO,nV,nR,nOO,nVV,e,ERI,C)
  call linear_response_D_pp(ispin,nBas,nC,nO,nV,nR,nOO,nVV,e,ERI,D)

!------------------------------------------------------------------------
! Solve the p-p eigenproblem
!------------------------------------------------------------------------
!
!  | C   -B | | X1  X2 |   | w1  0  | | X1  X2 |
!  |        | |        | = |        | |        |
!  | Bt  -D | | Y1  Y2 |   | 0   w2 | | Y1  Y2 |
!

! Diagonal blocks 

  M(    1:nVV    ,    1:nVV)     = + C(1:nVV,1:nVV)
  M(nVV+1:nVV+nOO,nVV+1:nVV+nOO) = - D(1:nOO,1:nOO)

! Off-diagonal blocks

  M(    1:nVV    ,nVV+1:nOO+nVV) = -           B(1:nVV,1:nOO)
  M(nVV+1:nOO+nVV,    1:nVV)     = + transpose(B(1:nVV,1:nOO))

! Dump ppRPA matrices 

  if(dump_matrices) then 

    open(unit=42,file='B.dat')
    open(unit=43,file='C.dat')
    open(unit=44,file='D.dat')
    open(unit=45,file='ERI.dat')
    open(unit=46,file='eps.dat')
  
    do ab=1,nVV
      do ij=1,nOO
        if(abs(B(ab,ij)) > 1d-15) write(42,*) ab,ij,B(ab,ij)
      end do
    end do
  
    do ab=1,nVV
      do cd=1,nVV
        if(abs(C(ab,cd)) > 1d-15) write(43,*) ab,cd,C(ab,cd)
      end do
    end do
  
    do ij=1,nOO
      do kl=1,nOO
        if(abs(D(ij,kl)) > 1d-15) write(44,*) ij,kl,D(ij,kl)
      end do
    end do
  
    do p=1,nBas
      write(46,*) p,e(p)
      do q=1,nBas
        do r=1,nBas
          do s=1,nBas
        if(abs(ERI(p,q,r,s)) > 1d-15) write(45,*) p,q,r,s,ERI(p,q,r,s)
        end do
      end do
      end do
    end do
 
    close(42)
    close(43)
    close(44)
    close(45)
    close(46)

  end if

! Diagonalize the p-h matrix

  if(nOO+nVV > 0) call diagonalize_general_matrix(nOO+nVV,M,Omega,Z)

! allocate(order(nOO+nVV))
! call quick_sort(Omega(:),order(:),nOO+nVV)
! call matout(nOO+nVV,1,Omega(:)*HaToeV)

! Split the various quantities in p-p and h-h parts

  call sort_ppRPA(ortho_eigvec,nOO,nVV,Omega(:),Z(:,:),Omega1(:),X1(:,:),Y1(:,:),Omega2(:),X2(:,:),Y2(:,:))

! call matout(32,1,(Omega1(:) - Omega1(1))*HaToeV)

! Compute the RPA correlation energy

  EcRPA = 0.5d0*( sum(Omega1(:)) - sum(Omega2(:)) - trace_matrix(nVV,C(:,:)) - trace_matrix(nOO,D(:,:)) )
  EcRPA1 = +sum(Omega1(:)) - trace_matrix(nVV,C(:,:))
  EcRPA2 = -sum(Omega2(:)) - trace_matrix(nOO,D(:,:))
  if(abs(EcRPA - EcRPA1) > 1d-6 .or. abs(EcRPA - EcRPA2) > 1d-6) & 
    print*,'!!! Issue in pp-RPA linear reponse calculation RPA1 != RPA2 !!!'

end subroutine linear_response_pp
