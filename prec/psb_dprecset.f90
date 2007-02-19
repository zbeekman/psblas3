!!$ 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
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
subroutine psb_dprecset(p,ptype,info,iv,rs,rv)

  use psb_base_mod
  use psb_prec_type
  implicit none
  type(psb_dprec_type), intent(inout)    :: p
  character(len=*), intent(in)           :: ptype
  integer, intent(out)                   :: info
  integer, optional, intent(in)          :: iv(:)
  real(kind(1.d0)), optional, intent(in) :: rs
  real(kind(1.d0)), optional, intent(in) :: rv(:)

  character(len=len(ptype))              :: typeup
  integer                                :: isz, err, nlev_, ilev_, i

  info = 0


  call psb_realloc(ifpsz,p%iprcparm,info)
  if (info == 0) call psb_realloc(dfpsz,p%dprcparm,info)
  if (info /= 0) return
  p%iprcparm(:) = 0

  select case(toupper(ptype(1:len_trim(ptype))))
  case ('NONE','NOPREC') 
    p%iprcparm(:)           = 0
    p%iprcparm(p_type_)     = noprec_
    p%iprcparm(f_type_)     = f_none_
    p%iprcparm(iren_)       = 0
    p%iprcparm(jac_sweeps_) = 1

  case ('DIAG')
    p%iprcparm(:)           = 0
    p%iprcparm(p_type_)     = diag_
    p%iprcparm(f_type_)     = f_none_
    p%iprcparm(iren_)       = 0 
    p%iprcparm(jac_sweeps_) = 1

  case ('BJAC') 
    p%iprcparm(:)            = 0
    p%iprcparm(p_type_)      = bjac_
    p%iprcparm(f_type_)      = f_ilu_n_
    p%iprcparm(iren_)        = 0
    p%iprcparm(ilu_fill_in_) = 0
    p%iprcparm(jac_sweeps_)  = 1

  case default
    write(0,*) 'Unknown preconditioner type request "',ptype,'"'
    err = 2

  end select

  info = err

end subroutine psb_dprecset