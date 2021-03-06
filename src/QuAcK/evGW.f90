subroutine evGW(maxSCF,thresh,max_diis,doACFDT,exchange_kernel,doXBS,COHSEX,SOSEX,BSE,TDA_W,TDA,dBSE,dTDA,evDyn,G0W,GW0, & 
                singlet_manifold,triplet_manifold,eta,nBas,nC,nO,nV,nR,nS,ENuc,ERHF,Hc,H,ERI,PHF,cHF,eHF,eG0W0)

! Perform self-consistent eigenvalue-only GW calculation

  implicit none
  include 'parameters.h'

! Input variables

  integer,intent(in)            :: maxSCF
  integer,intent(in)            :: max_diis
  double precision,intent(in)   :: thresh
  double precision,intent(in)   :: ENuc
  double precision,intent(in)   :: ERHF
  logical,intent(in)            :: doACFDT
  logical,intent(in)            :: exchange_kernel
  logical,intent(in)            :: doXBS
  logical,intent(in)            :: COHSEX
  logical,intent(in)            :: SOSEX
  logical,intent(in)            :: BSE
  logical,intent(in)            :: TDA_W
  logical,intent(in)            :: TDA
  logical,intent(in)            :: dBSE
  logical,intent(in)            :: dTDA
  logical,intent(in)            :: evDyn
  logical,intent(in)            :: G0W
  logical,intent(in)            :: GW0
  logical,intent(in)            :: singlet_manifold
  logical,intent(in)            :: triplet_manifold
  double precision,intent(in)   :: eta
  integer,intent(in)            :: nBas,nC,nO,nV,nR,nS
  double precision,intent(in)   :: eHF(nBas)
  double precision,intent(in)   :: cHF(nBas,nBas)
  double precision,intent(in)   :: PHF(nBas,nBas) 
  double precision,intent(in)   :: eG0W0(nBas)
  double precision,intent(in)   :: Hc(nBas,nBas)
  double precision,intent(in)   :: H(nBas,nBas)
  double precision,intent(in)   :: ERI(nBas,nBas,nBas,nBas)

! Local variables

  logical                       :: linear_mixing
  integer                       :: ispin
  integer                       :: nSCF
  integer                       :: n_diis
  double precision              :: rcond
  double precision              :: Conv
  double precision              :: EcRPA(nspin)
  double precision              :: EcBSE(nspin)
  double precision              :: EcAC(nspin)
  double precision              :: EcGM
  double precision              :: alpha
  double precision,allocatable  :: error_diis(:,:)
  double precision,allocatable  :: e_diis(:,:)
  double precision,allocatable  :: eGW(:)
  double precision,allocatable  :: eOld(:)
  double precision,allocatable  :: Z(:)
  double precision,allocatable  :: SigC(:)
  double precision,allocatable  :: Omega(:,:)
  double precision,allocatable  :: XpY(:,:,:)
  double precision,allocatable  :: XmY(:,:,:)
  double precision,allocatable  :: rho(:,:,:,:)
  double precision,allocatable  :: rhox(:,:,:,:)

! Hello world

  write(*,*)
  write(*,*)'************************************************'
  write(*,*)'|       Self-consistent evGW calculation       |'
  write(*,*)'************************************************'
  write(*,*)

! SOSEX correction

  if(SOSEX) write(*,*) 'SOSEX correction activated!'
  write(*,*)

! COHSEX approximation

  if(COHSEX) write(*,*) 'COHSEX approximation activated!'
  write(*,*)

! TDA for W

  if(TDA_W) write(*,*) 'Tamm-Dancoff approximation for dynamic screening!'
  write(*,*)

! TDA 

  if(TDA) write(*,*) 'Tamm-Dancoff approximation activated!'
  write(*,*)

! Linear mixing

  linear_mixing = .false.
  alpha = 0.2d0

! Memory allocation

  allocate(eGW(nBas),eOld(nBas),Z(nBas),SigC(nBas),Omega(nS,nspin), & 
           XpY(nS,nS,nspin),XmY(nS,nS,nspin),                       & 
           rho(nBas,nBas,nS,nspin),rhox(nBas,nBas,nS,nspin),        &
           error_diis(nBas,max_diis),e_diis(nBas,max_diis))

! Initialization

  nSCF            = 0
  ispin           = 1
  n_diis          = 0
  Conv            = 1d0
  e_diis(:,:)     = 0d0
  error_diis(:,:) = 0d0
  eGW(:)          = eG0W0(:)
  eOld(:)         = eGW(:)
  Z(:)            = 1d0

!------------------------------------------------------------------------
! Main loop
!------------------------------------------------------------------------

  do while(Conv > thresh .and. nSCF <= maxSCF)

   ! Compute linear response

    if(.not. GW0 .or. nSCF == 0) then

      call linear_response(ispin,.true.,TDA_W,.false.,eta,nBas,nC,nO,nV,nR,nS,1d0,eGW,ERI, & 
                           rho(:,:,:,ispin),EcRPA(ispin),Omega(:,ispin),XpY(:,:,ispin),XmY(:,:,ispin))

    endif

!   Compute correlation part of the self-energy 

    call excitation_density(nBas,nC,nO,nR,nS,ERI,XpY(:,:,ispin),rho(:,:,:,ispin))

    if(SOSEX) call excitation_density_SOSEX(nBas,nC,nO,nR,nS,ERI,XpY(:,:,ispin),rhox(:,:,:,ispin))

    ! Correlation self-energy

    if(G0W) then

      call self_energy_correlation_diag(COHSEX,SOSEX,eta,nBas,nC,nO,nV,nR,nS,eHF, & 
                                        Omega(:,ispin),rho(:,:,:,ispin),rhox(:,:,:,ispin),EcGM,SigC)
      call renormalization_factor(COHSEX,SOSEX,eta,nBas,nC,nO,nV,nR,nS,eHF, & 
                                  Omega(:,ispin),rho(:,:,:,ispin),rhox(:,:,:,ispin),Z(:))

    else 

      call self_energy_correlation_diag(COHSEX,SOSEX,eta,nBas,nC,nO,nV,nR,nS,eGW, & 
                                        Omega(:,ispin),rho(:,:,:,ispin),rhox(:,:,:,ispin),EcGM,SigC)
      call renormalization_factor(COHSEX,SOSEX,eta,nBas,nC,nO,nV,nR,nS,eGW, & 
                                  Omega(:,ispin),rho(:,:,:,ispin),rhox(:,:,:,ispin),Z(:))

    endif

    ! Solve the quasi-particle equation

    eGW(:) = eHF(:) + SigC(:)

    ! Convergence criteria

    Conv = maxval(abs(eGW - eOld))

    ! Print results

!   call print_excitation('RPA   ',ispin,nS,Omega(:,ispin))
    call print_evGW(nBas,nO,nSCF,Conv,eHF,ENuc,ERHF,SigC,Z,eGW)

    ! Linear mixing or DIIS extrapolation

    if(linear_mixing) then
 
      eGW(:) = alpha*eGW(:) + (1d0 - alpha)*eOld(:)
 
    else

      n_diis = min(n_diis+1,max_diis)
      call DIIS_extrapolation(rcond,nBas,nBas,n_diis,error_diis,e_diis,eGW-eOld,eGW)

!    Reset DIIS if required

      if(abs(rcond) < 1d-15) n_diis = 0

    endif

    ! Save quasiparticles energy for next cycle

    eOld(:) = eGW(:)

    ! Increment

    nSCF = nSCF + 1

  enddo
!------------------------------------------------------------------------
! End main loop
!------------------------------------------------------------------------

! Plot stuff

! call plot_GW(nBas,nC,nO,nV,nR,nS,eHF,eGW,Omega(:,ispin),rho(:,:,:,ispin),rhox(:,:,:,ispin))

! Did it actually converge?

  if(nSCF == maxSCF+1) then

    write(*,*)
    write(*,*)'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    write(*,*)'                 Convergence failed                 '
    write(*,*)'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    write(*,*)

    stop

  endif

! Dump the RPA correlation energy

  write(*,*)
  write(*,*)'-------------------------------------------------------------------------------'
  write(*,'(2X,A50,F20.10)') 'Tr@RPA@evGW correlation energy (singlet) =',EcRPA(1)
  write(*,'(2X,A50,F20.10)') 'Tr@RPA@evGW correlation energy (triplet) =',EcRPA(2)
  write(*,'(2X,A50,F20.10)') 'Tr@RPA@evGW correlation energy           =',EcRPA(1) + EcRPA(2)
  write(*,'(2X,A50,F20.10)') 'Tr@RPA@evGW total energy                 =',ENuc + ERHF + EcRPA(1) + EcRPA(2)
  write(*,*)'-------------------------------------------------------------------------------'
  write(*,*)

! Perform BSE calculation

  if(BSE) then

    call Bethe_Salpeter(TDA_W,TDA,dBSE,dTDA,evDyn,singlet_manifold,triplet_manifold,eta, &
                        nBas,nC,nO,nV,nR,nS,ERI,eGW,eGW,Omega,XpY,XmY,rho,EcRPA,EcBSE)

    write(*,*)
    write(*,*)'-------------------------------------------------------------------------------'
    write(*,'(2X,A50,F20.10)') 'Tr@BSE@evGW correlation energy (singlet) =',EcBSE(1)
    write(*,'(2X,A50,F20.10)') 'Tr@BSE@evGW correlation energy (triplet) =',EcBSE(2)
    write(*,'(2X,A50,F20.10)') 'Tr@BSE@evGW correlation energy           =',EcBSE(1) + EcBSE(2)
    write(*,'(2X,A50,F20.10)') 'Tr@BSE@evGW total energy                 =',ENuc + ERHF + EcBSE(1) + EcBSE(2)
    write(*,*)'-------------------------------------------------------------------------------'
    write(*,*)

!   Compute the BSE correlation energy via the adiabatic connection 

    if(doACFDT) then

      write(*,*) '------------------------------------------------------'
      write(*,*) 'Adiabatic connection version of BSE correlation energy'
      write(*,*) '------------------------------------------------------'
      write(*,*)

      if(doXBS) then

        write(*,*) '*** scaled screening version (XBS) ***'
        write(*,*)

      end if

      call ACFDT(exchange_kernel,doXBS,.true.,TDA_W,TDA,BSE,singlet_manifold,triplet_manifold,eta, &
                 nBas,nC,nO,nV,nR,nS,ERI,eGW,eGW,Omega,XpY,XmY,rho,EcAC)

      write(*,*)
      write(*,*)'-------------------------------------------------------------------------------'
      write(*,'(2X,A50,F20.10)') 'AC@BSE@evGW correlation energy (singlet) =',EcAC(1)
      write(*,'(2X,A50,F20.10)') 'AC@BSE@evGW correlation energy (triplet) =',EcAC(2)
      write(*,'(2X,A50,F20.10)') 'AC@BSE@evGW correlation energy           =',EcAC(1) + EcAC(2)
      write(*,'(2X,A50,F20.10)') 'AC@BSE@evGW total energy                 =',ENuc + ERHF + EcAC(1) + EcAC(2)
      write(*,*)'-------------------------------------------------------------------------------'
      write(*,*)

    end if

  endif

end subroutine evGW
