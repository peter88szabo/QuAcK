subroutine Bethe_Salpeter(TDA_W,TDA,dBSE,dTDA,evDyn,singlet_manifold,triplet_manifold,eta, & 
                          nBas,nC,nO,nV,nR,nS,ERI,eW,eGW,OmRPA,XpY_RPA,XmY_RPA,rho_RPA,EcRPA,EcBSE)

! Compute the Bethe-Salpeter excitation energies

  implicit none
  include 'parameters.h'

! Input variables

  logical,intent(in)            :: TDA_W
  logical,intent(in)            :: TDA
  logical,intent(in)            :: dBSE
  logical,intent(in)            :: dTDA
  logical,intent(in)            :: evDyn
  logical,intent(in)            :: singlet_manifold
  logical,intent(in)            :: triplet_manifold

  double precision,intent(in)   :: eta
  integer,intent(in)            :: nBas,nC,nO,nV,nR,nS
  double precision,intent(in)   :: eW(nBas)
  double precision,intent(in)   :: eGW(nBas)
  double precision,intent(in)   :: ERI(nBas,nBas,nBas,nBas)

  double precision              :: OmRPA(nS,nspin)
  double precision              :: XpY_RPA(nS,nS,nspin)
  double precision              :: XmY_RPA(nS,nS,nspin)
  double precision              :: rho_RPA(nBas,nBas,nS,nspin)

! Local variables

  integer                       :: ispin
  integer                       :: isp_W
  double precision,allocatable  :: OmBSE(:,:)
  double precision,allocatable  :: XpY_BSE(:,:,:)
  double precision,allocatable  :: XmY_BSE(:,:,:)

! Output variables

  double precision,intent(out)  :: EcRPA(nspin)
  double precision,intent(out)  :: EcBSE(nspin)

! Memory allocation

  allocate(OmBSE(nS,nspin),XpY_BSE(nS,nS,nspin),XmY_BSE(nS,nS,nspin))

!-------------------
! Singlet manifold
!-------------------

 if(singlet_manifold) then

    ispin = 1
    isp_W = 1
    EcBSE(ispin) = 0d0

   ! Compute (singlet) RPA screening 

    call linear_response(isp_W,.true.,TDA_W,.false.,eta,nBas,nC,nO,nV,nR,nS,1d0,eW,ERI, &
                         rho_RPA(:,:,:,ispin),EcRPA(ispin),OmRPA(:,ispin),XpY_RPA(:,:,ispin),XmY_RPA(:,:,ispin))
    call excitation_density(nBas,nC,nO,nR,nS,ERI,XpY_RPA(:,:,ispin),rho_RPA(:,:,:,ispin))

    ! Compute BSE excitation energies

    OmBSE(:,ispin) = OmRPA(:,ispin)

    call linear_response(ispin,.true.,TDA,.true.,eta,nBas,nC,nO,nV,nR,nS,1d0,eGW,ERI, &
                         rho_RPA(:,:,:,ispin),EcBSE(ispin),OmBSE(:,ispin),XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin))
    call print_excitation('BSE         ',ispin,nS,OmBSE(:,ispin))

    !-------------------------------------------------
    ! Compute the dynamical screening at the BSE level
    !-------------------------------------------------

    if(dBSE) then

      ! Compute dynamic correction for BSE via perturbation theory (iterative or renormalized)
 
      if(evDyn) then
 
        call Bethe_Salpeter_dynamic_perturbation_iterative(dTDA,eta,nBas,nC,nO,nV,nR,nS,eGW(:),OmRPA(:,ispin),OmBSE(:,ispin), & 
                                                           XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin),rho_RPA(:,:,:,ispin))
      else
 
        call Bethe_Salpeter_dynamic_perturbation(dTDA,eta,nBas,nC,nO,nV,nR,nS,eGW(:),OmRPA(:,ispin),OmBSE(:,ispin), & 
                                                 XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin),rho_RPA(:,:,:,ispin))
      end if

    end if
 
  end if

!-------------------
! Triplet manifold
!-------------------

 if(triplet_manifold) then

    ispin = 2
    isp_W = 1
    EcBSE(ispin) = 0d0

   ! Compute (singlet) RPA screening 

    call linear_response(isp_W,.true.,TDA_W,.false.,eta,nBas,nC,nO,nV,nR,nS,1d0,eW,ERI, &
                         rho_RPA(:,:,:,ispin),EcRPA(ispin),OmRPA(:,ispin),XpY_RPA(:,:,ispin),XmY_RPA(:,:,ispin))
    call excitation_density(nBas,nC,nO,nR,nS,ERI,XpY_RPA(:,:,ispin),rho_RPA(:,:,:,ispin))

    ! Compute BSE excitation energies

    OmBSE(:,ispin) = OmRPA(:,ispin)

    call linear_response(ispin,.true.,TDA,.true.,eta,nBas,nC,nO,nV,nR,nS,1d0,eGW,ERI, &
                         rho_RPA(:,:,:,ispin),EcBSE(ispin),OmBSE(:,ispin),XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin))
    call print_excitation('BSE         ',ispin,nS,OmBSE(:,ispin))

    !-------------------------------------------------
    ! Compute the dynamical screening at the BSE level
    !-------------------------------------------------

    if(dBSE) then

      ! Compute dynamic correction for BSE via perturbation theory (iterative or renormalized)

      if(evDyn) then
     
        call Bethe_Salpeter_dynamic_perturbation_iterative(dTDA,eta,nBas,nC,nO,nV,nR,nS,eGW,OmRPA(:,ispin),OmBSE(:,ispin), & 
                                                           XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin),rho_RPA(:,:,:,ispin))
      else
     
        call Bethe_Salpeter_dynamic_perturbation(dTDA,eta,nBas,nC,nO,nV,nR,nS,eGW,OmRPA(:,ispin),OmBSE(:,ispin), & 
                                                 XpY_BSE(:,:,ispin),XmY_BSE(:,:,ispin),rho_RPA(:,:,:,ispin))
      end if

    end if

  end if

end subroutine Bethe_Salpeter
