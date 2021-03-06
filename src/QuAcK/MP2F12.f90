subroutine MP2F12(nBas,nC,nO,nV,ERI,F12,Yuk,FC,EHF,e,c)

! Perform MP2-F12 calculation

  implicit none

! Input variables

  integer,intent(in)            :: nBas,nC,nO,nV
  double precision,intent(in)   :: EHF
  double precision,intent(in)   :: e(nBas)
  double precision,intent(in)   :: c(nBas,nBas)
  double precision,intent(in)   :: ERI(nBas,nBas,nBas,nBas)
  double precision,intent(in)   :: F12(nBas,nBas,nBas,nBas)
  double precision,intent(in)   :: Yuk(nBas,nBas,nBas,nBas)
  double precision,intent(in)   :: FC(nBas,nBas,nBas,nBas,nBas,nBas)

! Local variables

  double precision,allocatable  :: ooCoo(:,:,:,:)
  double precision,allocatable  :: ooFoo(:,:,:,:)
  double precision,allocatable  :: ooYoo(:,:,:,:)
  double precision,allocatable  :: ooCvv(:,:,:,:)
  double precision,allocatable  :: ooFvv(:,:,:,:)
  double precision,allocatable  :: oooFCooo(:,:,:,:,:,:)
  double precision,allocatable  :: eO(:),eV(:)
  double precision,allocatable  :: cO(:,:),cV(:,:)
  double precision              :: E2a,E2b,E3a,E3b,E4a,E4b,E4c,E4d
  integer                       :: i,j,k,l,a,b
  double precision              :: EcMP2F12(4)

  double precision              :: EcMP2a
  double precision              :: EcMP2b
  double precision              :: EcMP2
  double precision              :: eps
  

! Split MOs into occupied and virtual sets

  allocate(eO(nO),eV(nV))

  eO(1:nO) = e(nC+1:nC+nO)
  eV(1:nV) = e(nC+nO+1:nBas)

  allocate(cO(nBas,nO),cV(nBas,nV))

  cO(1:nBas,1:nO) = c(1:nBas,nC+1:nC+nO)
  cV(1:nBas,1:nV) = c(1:nBas,nC+nO+1:nBas)

! Compute conventional MP2 energy

  allocate(ooCvv(nO,nO,nV,nV))
  call AOtoMO_oovv(nBas,nO,nV,cO,cV,ERI,ooCvv)

  EcMP2a = 0d0
  EcMP2b = 0d0

  do i=1,nO
    do j=1,nO
      do a=1,nV
        do b=1,nV
          eps = eO(i) + eO(j) - eV(a) - eV(b)
          EcMP2a = EcMP2a + ooCvv(i,j,a,b)/eps
          EcMP2b = EcMP2b + ooCvv(i,j,b,a)/eps
        enddo
      enddo
    enddo
  enddo

  EcMP2 = EcMP2a + EcMP2b

! Compute the two-electron part of the MP2-F12 energy

  allocate(ooYoo(nO,nO,nO,nO))
  call AOtoMO_oooo(nBas,nO,cO,Yuk,ooYoo)

  E2a = 0d0
  E2b = 0d0
  do i=1,nO
    do j=1,nO
      E2a = E2a + ooYoo(i,j,i,j)
      E2b = E2b + ooYoo(i,j,j,i)
    enddo
  enddo

  deallocate(ooYoo)

! Compute the three-electron part of the MP2-F12 energy

  allocate(oooFCooo(nO,nO,nO,nO,nO,nO))
  call AOtoMO_oooooo(nBas,nO,cO,FC,oooFCooo)

  E3a = 0d0
  E3b = 0d0
  do i=1,nO
    do j=1,nO
      do k=1,nO
        E3a = E3a + oooFCooo(i,j,k,k,j,i)
        E3b = E3b + oooFCooo(i,j,k,k,i,j)
      enddo
    enddo
  enddo

  deallocate(oooFCooo)

! Compute the four-electron part of the MP2-F12 energy

  allocate(ooCoo(nO,nO,nO,nO),ooFoo(nO,nO,nO,nO))
  call AOtoMO_oooo(nBas,nO,cO,ERI,ooCoo)
  call AOtoMO_oooo(nBas,nO,cO,F12,ooFoo)

  E4a = 0d0
  E4b = 0d0
  do i=1,nO
    do j=1,nO
      do k=1,nO
        do l=1,nO
          E4a = E4a + ooCoo(i,j,k,l)*ooFoo(i,j,k,l)
          E4b = E4b + ooCoo(i,j,k,l)*ooFoo(j,i,k,l)
        enddo
      enddo
    enddo
  enddo

  deallocate(ooCoo,ooFoo)

  allocate(ooCvv(nO,nO,nV,nV),ooFvv(nO,nO,nV,nV))
  call AOtoMO_oovv(nBas,nO,nV,cO,cV,ERI,ooCvv)
  call AOtoMO_oovv(nBas,nO,nV,cO,cV,F12,ooFvv)

  E4c = 0d0
  E4d = 0d0
  do i=1,nO
    do j=1,nO
      do a=1,nV
        do b=1,nV
          E4c = E4c + ooCvv(i,j,a,b)*ooFvv(i,j,a,b)
          E4d = E4d + ooCvv(i,j,a,b)*ooFvv(j,i,a,b)
        enddo
      enddo
    enddo
  enddo

  deallocate(ooCvv,ooFvv)

! Final scaling of the various components

  EcMP2F12(1) = +0.625d0*E2a - 0.125d0*E2b
  EcMP2F12(2) = -1.250d0*E3a + 0.250d0*E3b
  EcMP2F12(3) = +0.625d0*E4a - 0.125d0*E4b - 0.625d0*E4c + 0.125d0*E4d

  write(*,*)
  write(*,'(A32)')           '-----------------------'
  write(*,'(A32)')           ' MP2-F12 calculation   '
  write(*,'(A32)')           '-----------------------'
  write(*,'(A32,1X,F16.10)') ' MP2                   ',+EcMP2
  write(*,'(A32,1X,F16.10)') ' MP2-F12 E(2)          ',-EcMP2F12(1)
  write(*,'(A32,1X,F16.10)') ' MP2-F12 E(3)          ',-EcMP2F12(2)
  write(*,'(A32,1X,F16.10)') ' MP2-F12 E(4)          ',-EcMP2F12(3)
  write(*,'(A32)')           '-----------------------'
  write(*,'(A32,1X,F16.10)') ' Total                 ',EcMP2-EcMP2F12(1)-EcMP2F12(2)-EcMP2F12(3)
  write(*,'(A32)')           '-----------------------'
  write(*,*)

  deallocate(cO,cV)

end subroutine MP2F12
