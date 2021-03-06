!   
!                Parallel Sparse BLAS  version 3.5
!      (C) Copyright 2006, 2010, 2015, 2017
!        Salvatore Filippone    Cranfield University
!        Alfredo Buttari        CNRS-IRIT, Toulouse
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the PSBLAS group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!    
! File:  psb_zspspmm.f90 
! Subroutine: 
! Arguments:
!
!
!
subroutine psb_zspspmm(a,b,c,info)
  use psb_base_mod, psb_protect_name => psb_zspspmm
  implicit none 

  type(psb_zspmat_type), intent(in)    :: a,b
  type(psb_zspmat_type), intent(out)   :: c
  integer(psb_ipk_), intent(out)                  :: info
  type(psb_z_csr_sparse_mat), allocatable :: ccsr
  type(psb_z_csc_sparse_mat), allocatable :: ccsc
  integer(psb_ipk_) :: err_act
  character(len=*), parameter ::  name='psb_spspmm'
  logical :: done_spmm
  call psb_erractionsave(err_act)
  info = psb_success_

  if ((a%is_null()) .or.(b%is_null())) then
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif


  ! 
  ! Shortcuts for special cases
  !
  done_spmm = .false. 
  select type(aa=>a%a)
  class is (psb_z_csr_sparse_mat) 
    select type(ba=>b%a)
    class is (psb_z_csr_sparse_mat) 
      
      allocate(ccsr,stat=info)    
      if (info == psb_success_) then 
        call psb_zcsrspspmm(aa,ba,ccsr,info)
      else
        info = psb_err_alloc_dealloc_
      end if
      if (info == psb_success_) call move_alloc(ccsr,c%a)
      done_spmm = .true. 

    end select

  class is (psb_z_csc_sparse_mat) 
    select type(ba=>b%a)
    class is (psb_z_csc_sparse_mat) 
      
      allocate(ccsc,stat=info)    
      if (info == psb_success_) then 
        call psb_zcscspspmm(aa,ba,ccsc,info)
      else
        info = psb_err_alloc_dealloc_
      end if
      if (info == psb_success_) call move_alloc(ccsc,c%a)
      done_spmm = .true. 

    end select

  end select
  
  !
  ! General code
  !
  if (.not.done_spmm) then 
    call psb_symbmm(a,b,c,info)
    if (info == psb_success_) call psb_numbmm(a,b,c)
  end if
  
  if (info /= psb_success_) then 
    call psb_errpush(info,name) 
    goto 9999
  end if
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_zspspmm

