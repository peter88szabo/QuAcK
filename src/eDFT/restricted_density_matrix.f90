subroutine restricted_density_matrix(nBas,nEns,nO,c,P)

! Calculate density matrices

  implicit none

  include 'parameters.h'

! Input variables

  integer,intent(in)            :: nBas
  integer,intent(in)            :: nEns
  integer,intent(in)            :: nO
  double precision,intent(in)   :: c(nBas,nBas)

! Local variables

  integer                       :: iEns

! Output variables

  double precision,intent(out)  :: P(nBas,nBas,nEns)

! Ground state density matrix

  iEns = 1

  P(:,:,iEns) = 2d0*matmul(c(:,1:nO),transpose(c(:,1:nO)))

! Doubly-excited state density matrix

  iEns = 2 
  
  if(nO > 1) then 
    P(:,:,iEns) = 2d0*matmul(c(:,1:nO-1),transpose(c(:,1:nO-1))) 
  else
    P(:,:,iEns) = 0d0
  end if

  P(:,:,iEns) = P(:,:,iEns) + 1d0*matmul(c(:,nO  :nO  ),transpose(c(:,nO  :nO  ))) &
                            + 1d0*matmul(c(:,nO+2:nO+2),transpose(c(:,nO+2:nO+2)))

! Doubly-excited state density matrix

  iEns = 3 
  
  if(nO > 1) then 
    P(:,:,iEns) = 2d0*matmul(c(:,1:nO-1),transpose(c(:,1:nO-1))) 
  else
    P(:,:,iEns) = 0d0
  end if

  P(:,:,iEns) = P(:,:,iEns) + 2d0*matmul(c(:,nO+1:nO+1),transpose(c(:,nO+1:nO+1)))

end subroutine restricted_density_matrix
