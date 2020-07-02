subroutine UCC_lda_exchange_potential(nEns,wEns,nGrid,weight,nBas,AO,rho,Fx)

! Compute the unrestricted version of the curvature-corrected exchange potential

  implicit none
  include 'parameters.h'

! Input variables

  integer,intent(in)            :: nEns
  double precision,intent(in)   :: wEns(nEns)
  integer,intent(in)            :: nGrid
  double precision,intent(in)   :: weight(nGrid)
  integer,intent(in)            :: nBas
  double precision,intent(in)   :: AO(nBas,nGrid)
  double precision,intent(in)   :: rho(nGrid)

! Local variables

  integer                       :: mu,nu,iG
  double precision              :: r,vAO,alpha

  double precision              :: a1,b1,c1,w1
  double precision              :: a2,b2,c2,w2
  double precision              :: Fx1,Fx2,Cx

! Output variables

  double precision,intent(out)  :: Fx(nBas,nBas)

! Single excitation parameter

!  a1 = 0.0d0
!  b1 = 0.0d0
!  c1 = 0.0d0

! Parameters for H2 at equilibrium

! a2 = +0.5751782560799208d0
! b2 = -0.021108186591137282d0
! c2 = -0.36718902716347124d0

! Parameters for stretch H2

!  a2 = + 0.01922622507087411d0
!  b2 = - 0.01799647558018601d0
!  c2 = - 0.022945430666782573d0

! Parameters for He

! a2 = 1.9125735895875828d0
! b2 = 2.715266992840757d0
! c2 = 2.1634223380633086d0

! Parameters for He N -> N-1

  a1 = 0.420243d0
  b1 = 0.0700561d0
  c1 = -0.288301d0

! Parameters for He N -> N+1

  a2 = 0.135068d0
  b2 = -0.00774769d0
  c2 = -0.0278205d0

! Cx coefficient for unrestricted Slater LDA exchange

  alpha = -(3d0/2d0)*(3d0/(4d0*pi))**(1d0/3d0)

! Fx1 for states N and N-1
! Fx2 for states N and N+1

  w1 = wEns(2)
  Fx1 = 1d0 - w1*(1d0 - w1)*(a1 + b1*(w1 - 0.5d0) + c1*(w1 - 0.5d0)**2)

  w2 = wEns(3)
  Fx2 = 1d0 - w2*(1d0 - w2)*(a2 + b2*(w2 - 0.5d0) + c2*(w2 - 0.5d0)**2)

  Cx = alpha*Fx2*Fx1

! Compute LDA exchange matrix in the AO basis

  Fx(:,:) = 0d0

  do mu=1,nBas
    do nu=1,nBas
      do iG=1,nGrid

        r = max(0d0,rho(iG))

        if(r > threshold) then

          vAO = weight(iG)*AO(mu,iG)*AO(nu,iG)
          Fx(mu,nu) = Fx(mu,nu) + vAO*4d0/3d0*Cx*r**(1d0/3d0)

        endif

      enddo
    enddo
  enddo

end subroutine UCC_lda_exchange_potential