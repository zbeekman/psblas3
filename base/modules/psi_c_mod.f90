!!$ 
!!$              Parallel Sparse BLAS  version 3.0
!!$    (C) Copyright 2006, 2007, 2008, 2009, 2010, 2012
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        CNRS-IRIT, Toulouse
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the PSBLAS group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
module psi_c_mod
  use psb_descriptor_type, only : psb_desc_type, psb_spk_, psb_ipk_
  use psb_c_vect_mod,  only : psb_c_base_vect_type

  interface psi_swapdata
    subroutine psi_cswapdatam(flag,n,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag, n
      integer(psb_ipk_), intent(out)        :: info
      complex(psb_spk_)           :: y(:,:), beta
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswapdatam
    subroutine psi_cswapdatav(flag,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag
      integer(psb_ipk_), intent(out)        :: info
      complex(psb_spk_)           :: y(:), beta 
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswapdatav
    subroutine psi_cswapdata_vect(flag,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag
      integer(psb_ipk_), intent(out)        :: info
      class(psb_c_base_vect_type) :: y
      complex(psb_spk_)           :: beta 
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswapdata_vect
    subroutine psi_cswapidxm(ictxt,icomm,flag,n,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)      :: ictxt,icomm,flag, n
      integer(psb_ipk_), intent(out)     :: info
      complex(psb_spk_)        :: y(:,:), beta
      complex(psb_spk_),target :: work(:)
      integer(psb_ipk_), intent(in)      :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_cswapidxm
    subroutine psi_cswapidxv(ictxt,icomm,flag,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)      :: ictxt,icomm,flag
      integer(psb_ipk_), intent(out)     :: info
      complex(psb_spk_)        :: y(:), beta
      complex(psb_spk_),target :: work(:)
      integer(psb_ipk_), intent(in)      :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_cswapidxv
    subroutine psi_cswapidx_vect(ictxt,icomm,flag,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: ictxt,icomm,flag
      integer(psb_ipk_), intent(out)        :: info
      class(psb_c_base_vect_type) :: y
      complex(psb_spk_)           :: beta
      complex(psb_spk_),target    :: work(:)
      integer(psb_ipk_), intent(in)         :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_cswapidx_vect
  end interface


  interface psi_swaptran
    subroutine psi_cswaptranm(flag,n,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag, n
      integer(psb_ipk_), intent(out)        :: info
      complex(psb_spk_)           :: y(:,:), beta
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswaptranm
    subroutine psi_cswaptranv(flag,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag
      integer(psb_ipk_), intent(out)        :: info
      complex(psb_spk_)           :: y(:), beta
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswaptranv
    subroutine psi_cswaptran_vect(flag,beta,y,desc_a,work,info,data)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: flag
      integer(psb_ipk_), intent(out)        :: info
      class(psb_c_base_vect_type) :: y
      complex(psb_spk_)           :: beta
      complex(psb_spk_),target    :: work(:)
      type(psb_desc_type), target :: desc_a
      integer(psb_ipk_), optional           :: data
    end subroutine psi_cswaptran_vect
    subroutine psi_ctranidxm(ictxt,icomm,flag,n,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)      :: ictxt,icomm,flag, n
      integer(psb_ipk_), intent(out)     :: info
      complex(psb_spk_)        :: y(:,:), beta
      complex(psb_spk_),target :: work(:)
      integer(psb_ipk_), intent(in)       :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_ctranidxm
    subroutine psi_ctranidxv(ictxt,icomm,flag,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)      :: ictxt,icomm,flag
      integer(psb_ipk_), intent(out)     :: info
      complex(psb_spk_)        :: y(:), beta
      complex(psb_spk_),target :: work(:)
      integer(psb_ipk_), intent(in)      :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_ctranidxv
    subroutine psi_ctranidx_vect(ictxt,icomm,flag,beta,y,idx,&
         & totxch,totsnd,totrcv,work,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      integer(psb_ipk_), intent(in)         :: ictxt,icomm,flag
      integer(psb_ipk_), intent(out)        :: info
      class(psb_c_base_vect_type) :: y
      complex(psb_spk_)           :: beta
      complex(psb_spk_),target    :: work(:)
      integer(psb_ipk_), intent(in)         :: idx(:),totxch,totsnd,totrcv
    end subroutine psi_ctranidx_vect
  end interface

  interface psi_ovrl_upd
    subroutine  psi_covrl_updr1(x,desc_a,update,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout), target :: x(:)
      type(psb_desc_type), intent(in)          :: desc_a
      integer(psb_ipk_), intent(in)                      :: update
      integer(psb_ipk_), intent(out)                     :: info
    end subroutine psi_covrl_updr1
    subroutine  psi_covrl_updr2(x,desc_a,update,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout), target :: x(:,:)
      type(psb_desc_type), intent(in)          :: desc_a
      integer(psb_ipk_), intent(in)                      :: update
      integer(psb_ipk_), intent(out)                     :: info
    end subroutine psi_covrl_updr2
    subroutine  psi_covrl_upd_vect(x,desc_a,update,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      class(psb_c_base_vect_type)       :: x
      type(psb_desc_type), intent(in)   :: desc_a
      integer(psb_ipk_), intent(in)               :: update
      integer(psb_ipk_), intent(out)              :: info
    end subroutine psi_covrl_upd_vect
  end interface

  interface psi_ovrl_save
    subroutine  psi_covrl_saver1(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout) :: x(:)
      complex(psb_spk_), allocatable   :: xs(:)
      type(psb_desc_type), intent(in)  :: desc_a
      integer(psb_ipk_), intent(out)             :: info
    end subroutine psi_covrl_saver1
    subroutine  psi_covrl_saver2(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout) :: x(:,:)
      complex(psb_spk_), allocatable   :: xs(:,:)
      type(psb_desc_type), intent(in)  :: desc_a
      integer(psb_ipk_), intent(out)             :: info
    end subroutine psi_covrl_saver2
    subroutine  psi_covrl_save_vect(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      class(psb_c_base_vect_type)     :: x
      complex(psb_spk_), allocatable  :: xs(:)
      type(psb_desc_type), intent(in) :: desc_a
      integer(psb_ipk_), intent(out)            :: info
    end subroutine psi_covrl_save_vect
  end interface

  interface psi_ovrl_restore
    subroutine  psi_covrl_restrr1(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout)  :: x(:)
      complex(psb_spk_)                 :: xs(:)
      type(psb_desc_type), intent(in)  :: desc_a
      integer(psb_ipk_), intent(out)             :: info
    end subroutine psi_covrl_restrr1
    subroutine  psi_covrl_restrr2(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      complex(psb_spk_), intent(inout) :: x(:,:)
      complex(psb_spk_)                :: xs(:,:)
      type(psb_desc_type), intent(in)  :: desc_a
      integer(psb_ipk_), intent(out)             :: info
    end subroutine psi_covrl_restrr2
    subroutine  psi_covrl_restr_vect(x,xs,desc_a,info)
      import :: psb_desc_type, psb_ipk_, psb_spk_, psb_c_base_vect_type
      class(psb_c_base_vect_type)     :: x
      complex(psb_spk_)               :: xs(:)
      type(psb_desc_type), intent(in) :: desc_a
      integer(psb_ipk_), intent(out)            :: info
    end subroutine psi_covrl_restr_vect
  end interface

end module psi_c_mod

