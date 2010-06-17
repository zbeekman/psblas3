!!$ 
!!$              Parallel Sparse BLAS  version 2.2
!!$    (C) Copyright 2006/2007/2008
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
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
! File: psb_znrm2.f90
!
! Function: psb_znrm2
!    Forms the norm2 of a distributed vector,
!
!    norm2 := sqrt ( sub( X )**T * sub( X ) )
!
!    where sub( X ) denotes X(:,JX).
!
! Arguments:
!    x(:,:) -  complex              The input vector containing the entries of sub( X ).
!    desc_a -  type(psb_desc_type). The communication descriptor.
!    info   -  integer.             Return code
!    jx     -  integer(optional).   The column offset for sub( X ).
!
function psb_znrm2(x, desc_a, info, jx)  
  use psb_descriptor_type
  use psb_check_mod
  use psb_error_mod
  use psb_penv_mod
  implicit none

  complex(psb_dpk_), intent(in)      ::  x(:,:)
  type(psb_desc_type), intent(in)   :: desc_a
  integer, intent(in), optional     :: jx
  integer, intent(out)              :: info
  real(psb_dpk_)                  :: psb_znrm2

  ! locals
  integer                  :: ictxt, np, me,&
       & err_act, iix, jjx, ndim, ix, ijx, i, m, id, idx, ndm
  real(psb_dpk_)         :: nrm2, dznrm2, dd

!!$  external dcombnrm2
  character(len=20)        :: name, ch_err

  name='psb_znrm2'
  if(psb_get_errstatus() /= 0) return 
  info=psb_success_
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)

  call psb_info(ictxt, me, np)
  if (np == -1) then
    info=psb_err_context_error_
    call psb_errpush(info,name)
    goto 9999
  endif

  ix = 1
  if (present(jx)) then
    ijx = jx
  else
    ijx = 1
  endif

  m = psb_cd_get_global_rows(desc_a)
  call psb_chkvect(m,1,size(x,1),ix,ijx,desc_a,info,iix,jjx)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='psb_chkvect'
    call psb_errpush(info,name,a_err=ch_err)
  end if

  if (iix /= 1) then
    info=psb_err_ix_n1_iy_n1_unsupported_
    call psb_errpush(info,name)
    goto 9999
  end if

  if(m /= 0) then
    if (psb_cd_get_local_rows(desc_a) > 0) then 
      ndim = psb_cd_get_local_rows(desc_a)
      nrm2 = dznrm2( ndim, x(iix:,jjx), ione )

      ! adjust  because overlapped elements are computed more than once
      do i=1,size(desc_a%ovrlap_elem,1)
        idx = desc_a%ovrlap_elem(i,1)
        ndm = desc_a%ovrlap_elem(i,2)
        dd  = dble(ndm-1)/dble(ndm)
        nrm2 = nrm2 * sqrt(done - dd*(abs(x(idx,jjx))/nrm2)**2) 
      end do
    else 	    
      nrm2 = dzero
    end if
  else 	    
    nrm2 = dzero
  end if

!!$  call pdtreecomb(ictxt,'All',1,nrm2,-1,-1,dcombnrm2)
  call psb_nrm2(ictxt,nrm2)

  psb_znrm2 = nrm2  

  call psb_erractionrestore(err_act)
  return  

9999 continue
  call psb_erractionrestore(err_act)

  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end function psb_znrm2



!!$ 
!!$              Parallel Sparse BLAS  version 2.2
!!$    (C) Copyright 2006/2007/2008
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
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
!
! Function: psb_znrm2
!    Forms the norm2 of a distributed vector,
!
!    norm2 := sqrt ( X**T * X)
!
! Arguments:
!    x(:)   -  complex               The input vector containing the entries of X.
!    desc_a -  type(psb_desc_type).  The communication descriptor.
!    info   -  integer.              Return code
!
function psb_znrm2v(x, desc_a, info)  
  use psb_descriptor_type
  use psb_check_mod
  use psb_error_mod
  use psb_penv_mod
  implicit none

  complex(psb_dpk_), intent(in)   :: x(:)
  type(psb_desc_type), intent(in)   :: desc_a
  integer, intent(out)              :: info
  real(psb_dpk_)                  :: psb_znrm2v

  ! locals
  integer                  :: ictxt, np, me,&
       & err_act, iix, jjx, ndim, ix, jx, i, m, id, idx, ndm
  real(psb_dpk_)         :: nrm2, dznrm2, dd

!!$  external dcombnrm2
  character(len=20)        :: name, ch_err

  name='psb_znrm2v'
  if(psb_get_errstatus() /= 0) return 
  info=psb_success_
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)

  call psb_info(ictxt, me, np)
  if (np == -1) then
    info=psb_err_context_error_
    call psb_errpush(info,name)
    goto 9999
  endif

  ix = 1
  jx=1
  m = psb_cd_get_global_rows(desc_a)

  call psb_chkvect(m,1,size(x),ix,jx,desc_a,info,iix,jjx)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='psb_chkvect'
    call psb_errpush(info,name,a_err=ch_err)
  end if

  if (iix /= 1) then
    info=psb_err_ix_n1_iy_n1_unsupported_
    call psb_errpush(info,name)
    goto 9999
  end if

  if(m /= 0) then
    if (psb_cd_get_local_rows(desc_a) > 0) then 
      ndim = psb_cd_get_local_rows(desc_a)
      nrm2 = dznrm2( ndim, x, ione )
      ! adjust  because overlapped elements are computed more than once
      do i=1,size(desc_a%ovrlap_elem,1)
        idx = desc_a%ovrlap_elem(i,1)
        ndm = desc_a%ovrlap_elem(i,2)
        dd  = dble(ndm-1)/dble(ndm)
        nrm2 = nrm2 * sqrt(done - dd*(abs(x(idx))/nrm2)**2) 
      end do
    else 	    
      nrm2 = dzero
    end if
  else 	    
    nrm2 = dzero
  end if

!!$  call pdtreecomb(ictxt,'All',1,nrm2,-1,-1,dcombnrm2)
  call psb_nrm2(ictxt,nrm2)

  psb_znrm2v = nrm2  

  call psb_erractionrestore(err_act)
  return  

9999 continue
  call psb_erractionrestore(err_act)

  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end function psb_znrm2v




!!$ 
!!$              Parallel Sparse BLAS  version 2.2
!!$    (C) Copyright 2006/2007/2008
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
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
!
! Subroutine: psb_znrm2vs
!    Forms the norm2 of a distributed vector,
!
!    norm2 := sqrt ( X**T * X)
!
! Arguments:
!    res    -  real                  The result.
!    x(:)   -  complex               The input vector containing the entries of X.
!    desc_a -  type(psb_desc_type).  The communication descriptor.
!    info   -  integer.              Return code
!
subroutine psb_znrm2vs(res, x, desc_a, info)
  use psb_descriptor_type
  use psb_check_mod
  use psb_error_mod
  use psb_penv_mod
  implicit none

  complex(psb_dpk_), intent(in)   :: x(:)
  real(psb_dpk_), intent(out)     :: res
  type(psb_desc_type), intent(in)   :: desc_a
  integer, intent(out)              :: info

  ! locals
  integer                  :: ictxt, np, me,&
       & err_act, iix, jjx, ndim, ix, jx, i, m, id, idx, ndm
  real(psb_dpk_)         :: nrm2, dznrm2, dd

!!$  external dcombnrm2
  character(len=20)        :: name, ch_err

  name='psb_znrm2'
  if(psb_get_errstatus() /= 0) return 
  info=psb_success_
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)

  call psb_info(ictxt, me, np)
  if (np == -1) then
    info=psb_err_context_error_
    call psb_errpush(info,name)
    goto 9999
  endif

  ix = 1
  jx = 1
  m = psb_cd_get_global_rows(desc_a)

  call psb_chkvect(m,1,size(x),ix,jx,desc_a,info,iix,jjx)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='psb_chkvect'
    call psb_errpush(info,name,a_err=ch_err)
  end if

  if (iix /= 1) then
    info=psb_err_ix_n1_iy_n1_unsupported_
    call psb_errpush(info,name)
    goto 9999
  end if

  if(m /= 0) then
    if (psb_cd_get_local_rows(desc_a) > 0) then 
      ndim = psb_cd_get_local_rows(desc_a)
      nrm2 = dznrm2( ndim, x, ione )
      ! adjust  because overlapped elements are computed more than once
      do i=1,size(desc_a%ovrlap_elem,1)
        idx = desc_a%ovrlap_elem(i,1)
        ndm = desc_a%ovrlap_elem(i,2)
        dd  = dble(ndm-1)/dble(ndm)
        nrm2 = nrm2 * sqrt(done - dd*(abs(x(idx))/nrm2)**2) 
      end do
    else 	    
      nrm2 = dzero
    end if
  else 	    
    nrm2 = dzero
  end if

!!$  call pdtreecomb(ictxt,'All',1,nrm2,-1,-1,dcombnrm2)
  call psb_nrm2(ictxt,nrm2)

  res = nrm2  

  call psb_erractionrestore(err_act)
  return  

9999 continue
  call psb_erractionrestore(err_act)

  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end subroutine psb_znrm2vs
