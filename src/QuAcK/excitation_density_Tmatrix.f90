subroutine excitation_density_Tmatrix(ispin,nBas,nC,nO,nR,nOO,nVV,ERI,X1,Y1,rho1,X2,Y2,rho2)

! Compute excitation densities for T-matrix self-energy

  implicit none

! Input variables

  integer,intent(in)            :: ispin
  integer,intent(in)            :: nBas,nC,nO,nR,nOO,nVV
  double precision,intent(in)   :: ERI(nBas,nBas,nBas,nBas)
  double precision,intent(out)  :: X1(nVV,nVV)
  double precision,intent(out)  :: Y1(nOO,nVV)
  double precision,intent(out)  :: X2(nVV,nOO)
  double precision,intent(out)  :: Y2(nOO,nOO)

! Local variables

  integer                       :: i,j,k,l
  integer                       :: a,b,c,d
  integer                       :: p
  integer                       :: ab,cd,ij,kl
  double precision,external     :: Kronecker_delta

! Output variables

  double precision,intent(out)  :: rho1(nBas,nBas,nVV)
  double precision,intent(out)  :: rho2(nBas,nBas,nOO)

  rho1(:,:,:) = 0d0   
  rho2(:,:,:) = 0d0   

!----------------------------------------------
! Singlet manifold
!----------------------------------------------

  if(ispin == 1) then

    do p=nC+1,nBas-nR

      do i=nC+1,nO
        do ab=1,nVV

          cd = 0
          do c=nO+1,nBas-nR
           do d=nO+1,c
              cd = cd + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
!                          + ERI(p,i,c,d)*X1(cd,ab) 
                           + (ERI(p,i,c,d) + ERI(p,i,d,c))*X1(cd,ab) &
                           /sqrt((1d0 + Kronecker_delta(p,i))*(1d0 + Kronecker_delta(c,d)))
            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=nC+1,k
              kl = kl + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
!                          + ERI(p,i,k,l)*Y1(kl,ab)
                           + (ERI(p,i,k,l) + ERI(p,i,l,k))*Y1(kl,ab) &
                           /sqrt((1d0 + Kronecker_delta(p,i))*(1d0 + Kronecker_delta(k,l)))
            end do
          end do

        end do
      end do

      do a=nO+1,nBas-nR
        do ij=1,nOO

          cd = 0
          do c=nO+1,nBas-nR
           do d=nO+1,c
              cd = cd + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
!                          + ERI(p,a,c,d)*X2(cd,ij)
                           + (ERI(p,a,c,d) + ERI(p,a,d,c))*X2(cd,ij) &
                           /sqrt((1d0 + Kronecker_delta(p,a))*(1d0 + Kronecker_delta(c,d)))

            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=nC+1,k
              kl = kl + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
!                          + ERI(p,a,k,l)*Y2(kl,ij)  
                           + (ERI(p,a,k,l) + ERI(p,a,l,k))*Y2(kl,ij) &
                           /sqrt((1d0 + Kronecker_delta(p,a))*(1d0 + Kronecker_delta(k,l)))

            end do
          end do

        end do
      end do
    end do

  end if

!----------------------------------------------
! Triplet manifold
!----------------------------------------------

  if(ispin == 2) then

    do p=nC+1,nBas-nR

      do i=nC+1,nO
        do ab=1,nVV

          cd = 0
          do c=nO+1,nBas-nR
           do d=nO+1,c-1
              cd = cd + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
                           + (ERI(p,i,c,d) - ERI(p,i,d,c))*X1(cd,ab)
            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=nC+1,k-1
              kl = kl + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
                           + (ERI(p,i,k,l) - ERI(p,i,l,k))*Y1(kl,ab)
            end do
          end do

        end do
      end do

      do a=nO+1,nBas-nR
        do ij=1,nOO

          cd = 0
          do c=nO+1,nBas-nR
           do d=nO+1,c-1
              cd = cd + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
                           + (ERI(p,a,c,d) - ERI(p,a,d,c))*X2(cd,ij)
            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=nC+1,k-1
              kl = kl + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
                           + (ERI(p,a,k,l) - ERI(p,a,l,k))*Y2(kl,ij)
            end do
          end do

        end do
      end do
    end do

  end if

!----------------------------------------------
! Spinorbital basis
!----------------------------------------------

  if(ispin == 3) then

    do p=nC+1,nBas-nR

      do i=nC+1,nO
        do ab=1,nVV

          cd = 0
          do c=nO+1,nBas-nR
           do d=c+1,nBas-nR
              cd = cd + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
                           + (ERI(p,i,c,d) - ERI(p,i,d,c))*X1(cd,ab)
            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=k+1,nO
              kl = kl + 1
              rho1(p,i,ab) = rho1(p,i,ab) & 
                           + (ERI(p,i,k,l) - ERI(p,i,l,k))*Y1(kl,ab)
            end do
          end do

        end do
      end do

      do a=nO+1,nBas-nR
        do ij=1,nOO

          cd = 0
          do c=nO+1,nBas-nR
           do d=c+1,nBas-nR
              cd = cd + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
                           + (ERI(p,a,c,d) - ERI(p,a,d,c))*X2(cd,ij)
            end do
          end do

          kl = 0
          do k=nC+1,nO
           do l=k+1,nO
              kl = kl + 1
              rho2(p,a,ij) = rho2(p,a,ij) & 
                           + (ERI(p,a,k,l) - ERI(p,a,l,k))*Y2(kl,ij)
            end do
          end do

        end do
      end do
    end do

  end if

end subroutine excitation_density_Tmatrix
