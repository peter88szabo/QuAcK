subroutine read_integrals_sph(nEl,nBas,S,T,V,Hc,G)

! Read one- and two-electron integrals from files

  implicit none
  include 'parameters.h'

! Input variables

  integer,intent(in)            :: nBas

! Local variables

  logical                       :: debug
  integer                       :: nEl(nspin)
  integer                       :: mu,nu,la,si
  double precision              :: Ov,Kin,Nuc,ERI
  double precision              :: rs,R,Rinv

! Output variables

  double precision,intent(out)  :: S(nBas,nBas),T(nBas,nBas),V(nBas,nBas),Hc(nBas,nBas),G(nBas,nBas,nBas,nBas)

! Open file with integrals

  debug = .false.

  open(unit=1,file='input/sph')
  read(1,*)
  read(1,*) rs

  R = sqrt(dble(sum(nEl(:))))/2d0*rs
  Rinv = 1d0/R

  print*, 'Scaling integrals by ',R

  open(unit=8 ,file='/Users/loos/Integrals/QuAcK_Sph/Ov.dat')
  open(unit=9 ,file='/Users/loos/Integrals/QuAcK_Sph/Kin.dat')
  open(unit=10,file='/Users/loos/Integrals/QuAcK_Sph/Nuc.dat')
  open(unit=11,file='/Users/loos/Integrals/QuAcK_Sph/ERI.dat')

! Read overlap integrals

  S(:,:) = 0d0
  do 
    read(8,*,end=8) mu,nu,Ov
    S(mu,nu) = Ov
  enddo
  8 close(unit=8)

! Read kinetic integrals

  T(:,:) = 0d0
  do 
    read(9,*,end=9) mu,nu,Kin
    T(mu,nu) = Rinv**2*Kin
  enddo
  9 close(unit=9)

! Read nuclear integrals

  V(:,:) = 0d0
  do 
    read(10,*,end=10) mu,nu,Nuc
    V(mu,nu) = Nuc
  enddo
  10 close(unit=10)

! Define core Hamiltonian

  Hc(:,:) = T(:,:) + V(:,:)

! Read nuclear integrals

  G(:,:,:,:) = 0d0
  do 
    read(11,*,end=11) mu,nu,la,si,ERI

    ERI = Rinv*ERI
!   <12|34>
    G(mu,nu,la,si) = ERI
!   <32|14>
    G(la,nu,mu,si) = ERI
!   <14|32>
    G(mu,si,la,nu) = ERI
!   <34|12>
    G(la,si,mu,nu) = ERI
!   <41|23>
    G(si,mu,nu,la) = ERI
!   <23|41>
    G(nu,la,si,mu) = ERI
!   <21|43>
    G(nu,mu,si,la) = ERI
!   <43|21>
    G(si,la,nu,mu) = ERI
  enddo
  11 close(unit=11)


! Print results
  if(debug) then
    write(*,'(A28)') '----------------------'
    write(*,'(A28)') 'Overlap integrals'
    write(*,'(A28)') '----------------------'
    call matout(nBas,nBas,S)
    write(*,*)
    write(*,'(A28)') '----------------------'
    write(*,'(A28)') 'Kinetic integrals'
    write(*,'(A28)') '----------------------'
    call matout(nBas,nBas,T)
    write(*,*)
    write(*,'(A28)') '----------------------'
    write(*,'(A28)') 'Nuclear integrals'
    write(*,'(A28)') '----------------------'
    call matout(nBas,nBas,V)
    write(*,*)
    write(*,'(A28)') '----------------------'
    write(*,'(A28)') 'Electron repulsion integrals'
    write(*,'(A28)') '----------------------'
    do la=1,nBas
      do si=1,nBas
        call matout(nBas,nBas,G(1,1,la,si))
      enddo
    enddo
    write(*,*)
  endif

end subroutine read_integrals_sph
