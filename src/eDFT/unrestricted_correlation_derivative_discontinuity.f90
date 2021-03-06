subroutine unrestricted_correlation_derivative_discontinuity(rung,DFA,nEns,wEns,nGrid,weight,rhow,drhow,Ec)

! Compute the correlation part of the derivative discontinuity

  implicit none
  include 'parameters.h'

! Input variables

  integer,intent(in)            :: rung
  character(len=12),intent(in)  :: DFA
  integer,intent(in)            :: nEns
  double precision,intent(in)   :: wEns(nEns)
  integer,intent(in)            :: nGrid
  double precision,intent(in)   :: weight(nGrid)
  double precision,intent(in)   :: rhow(nGrid,nspin)
  double precision,intent(in)   :: drhow(ncart,nGrid,nspin)

! Local variables

  double precision              :: aC

! Output variables

  double precision,intent(out)  :: Ec(nsp,nEns)

  select case (rung)

!   Hartree calculation

    case(0) 

      Ec(:,:) = 0d0

!   LDA functionals

    case(1) 

      call unrestricted_lda_correlation_derivative_discontinuity(DFA,nEns,wEns,nGrid,weight,rhow,Ec)

!   GGA functionals

    case(2) 

      call print_warning('!!! derivative discontinuity NYI for GGAs !!!')
      stop

!   Hybrid functionals

    case(4) 

      call print_warning('!!! derivative discontinuity NYI for hybrids !!!')
      stop

      aC = 0.81d0

!   Hartree-Fock calculation

    case(666) 

      Ec(:,:) = 0d0

  end select
 
end subroutine unrestricted_correlation_derivative_discontinuity
