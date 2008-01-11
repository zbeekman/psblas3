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
!!$ CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!!$ C                                                                      C
!!$ C  References:                                                         C
!!$ C          [1] Duff, I., Marrone, M., Radicati, G., and Vittoli, C.    C
!!$ C              Level 3 basic linear algebra subprograms for sparse     C
!!$ C              matrices: a user level interface                        C
!!$ C              ACM Trans. Math. Softw., 23(3), 379-401, 1997.          C
!!$ C                                                                      C
!!$ C                                                                      C
!!$ C         [2]  S. Filippone, M. Colajanni                              C
!!$ C              PSBLAS: A library for parallel linear algebra           C
!!$ C              computation on sparse matrices                          C
!!$ C              ACM Trans. on Math. Softw., 26(4), 527-550, Dec. 2000.  C
!!$ C                                                                      C
!!$ C         [3] M. Arioli, I. Duff, M. Ruiz                              C
!!$ C             Stopping criteria for iterative solvers                  C
!!$ C             SIAM J. Matrix Anal. Appl., Vol. 13, pp. 138-144, 1992   C
!!$ C                                                                      C
!!$ C                                                                      C
!!$ C         [4] R. Barrett et al                                         C
!!$ C             Templates for the solution of linear systems             C
!!$ C             SIAM, 1993                                          
!!$ C                                                                      C
!!$ C                                                                      C
!!$ CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
! File:  psb_zcgstab.f90
!
! Subroutine: psb_zcgstab
!    This subroutine implements the BiCG Stabilized method.
!
!    
! Arguments:
!
!    a      -  type(psb_zspmat_type)      Input: sparse matrix containing A.
!    prec   -  type(psb_zprec_type)       Input: preconditioner
!    b      -  complex,dimension(:)       Input: vector containing the
!                                         right hand side B
!    x      -  complex,dimension(:)       Input/Output: vector containing the
!                                         initial guess and final solution X.
!    eps    -  real                       Input: Stopping tolerance; the iteration is
!                                         stopped when the error estimate |err| <= eps
!    desc_a -  type(psb_desc_type).       Input: The communication descriptor.
!    info   -  integer.                   Output: Return code
!
!    itmax  -  integer(optional)          Input: maximum number of iterations to be
!                                         performed.
!    iter   -  integer(optional)          Output: how many iterations have been
!                                         performed.
!                                         performed.
!    err    -  real   (optional)          Output: error estimate on exit. If the
!                                         denominator of the estimate is exactly
!                                         0, it is changed into 1. 
!    itrace -  integer(optional)          Input: print an informational message
!                                         with the error estimate every itrace
!                                         iterations
!    istop  -  integer(optional)          Input: stopping criterion, or how
!                                         to estimate the error. 
!                                         1: err =  |r|/|b|; here the iteration is
!                                            stopped when  |r| <= eps * |b|
!                                         2: err =  |r|/(|a||x|+|b|);  here the iteration is
!                                            stopped when  |r| <= eps * (|a||x|+|b|)
!                                         where r is the (preconditioned, recursive
!                                         estimate of) residual. 
!
subroutine psb_zcgstab(a,prec,b,x,eps,desc_a,info,itmax,iter,err,itrace,istop)
  use psb_base_mod
  use psb_prec_mod
  use psb_krylov_mod, psb_protect_name => psb_zcgstab
  Implicit None
!!$  parameters 
  Type(psb_zspmat_type), Intent(in)  :: a
  Type(psb_zprec_type), Intent(in)   :: prec 
  Type(psb_desc_type), Intent(in)    :: desc_a
  Complex(Kind(1.d0)), Intent(in)       :: b(:)
  Complex(Kind(1.d0)), Intent(inout)    :: x(:)
  Real(Kind(1.d0)), Intent(in)       :: eps
  integer, intent(out)               :: info
  Integer, Optional, Intent(in)      :: itmax, itrace, istop
  Integer, Optional, Intent(out)     :: iter
  Real(Kind(1.d0)), Optional, Intent(out) :: err
!!$   Local data
  Complex(Kind(1.d0)), allocatable, target   :: aux(:),wwrk(:,:)
  Complex(Kind(1.d0)), Pointer  :: q(:),&
       & r(:), p(:), v(:), s(:), t(:), z(:), f(:)
  Integer          :: litmax, naux, mglob, it,itrace_,&
       & np,me, n_row, n_col
  integer            :: debug_level, debug_unit
  Logical, Parameter :: exchange=.True., noexchange=.False., debug1 = .False.
  Integer, Parameter :: irmax = 8
  Integer            :: itx, isvch, ictxt, err_act, int_err(5)
  Integer            :: istop_
  complex(Kind(1.d0)) :: alpha, beta, rho, rho_old, sigma, omega, tau
  Real(Kind(1.d0))   :: rni, xni, bni, ani, rn0, bn2
  real(kind(1.d0))   :: errnum, errden
!!$  Integer   istpb, istpe, ifctb, ifcte, imerr, irank, icomm,immb,imme
!!$  Integer mpe_log_get_event_number,mpe_Describe_state,mpe_log_event
  character(len=20)           :: name
  character(len=*), parameter :: methdname='BiCGStab'

  info = 0
  name = 'psb_zcgstab'
  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  ictxt = psb_cd_get_context(desc_a)
  call psb_info(ictxt, me, np)
  if (debug_level >= psb_debug_ext_)&
       & write(debug_unit,*) me,' ',trim(name),': from psb_info',np

  mglob = psb_cd_get_global_rows(desc_a)
  n_row = psb_cd_get_local_rows(desc_a)
  n_col = psb_cd_get_local_cols(desc_a)

  If (Present(istop)) Then 
    istop_ = istop 
  Else
    istop_ = 1
  Endif
!
!  ISTOP = 1:  Normwise backward error, infinity norm 
!  ISTOP = 2:  ||r||/||b||   norm 2 
!
  
  if ((istop_ < 1 ).or.(istop_ > 2 ) ) then
    info=5001
    int_err(1)=istop_
    err=info
    call psb_errpush(info,name,i_err=int_err)
    goto 9999
  endif

  call psb_chkvect(mglob,1,size(x,1),1,1,desc_a,info)
  if(info /= 0) then
    info=4010
    call psb_errpush(info,name,a_err='psb_chkvect on X')
    goto 9999
  end if
  call psb_chkvect(mglob,1,size(b,1),1,1,desc_a,info)
  if(info /= 0) then
    info=4010    
    call psb_errpush(info,name,a_err='psb_chkvect on B')
    goto 9999
  end if

  naux=6*n_col 
  allocate(aux(naux),stat=info)
  if (info==0) call psb_geall(wwrk,desc_a,info,n=8)
  if (info==0) call psb_geasb(wwrk,desc_a,info)  
  if (info /= 0) then 
     info=4011
     call psb_errpush(info,name)
     goto 9999
  End If

  Q => WWRK(:,1)
  R => WWRK(:,2)
  P => WWRK(:,3)
  V => WWRK(:,4)
  F => WWRK(:,5)
  S => WWRK(:,6)
  T => WWRK(:,7)
  Z => WWRK(:,8)

  if (present(itmax)) then 
    litmax = itmax
  else
    litmax = 1000
  endif

  if (present(itrace)) then
     itrace_ = itrace
  else
     itrace_ = 0
  end if
  
  ! Ensure global coherence for convergence checks.
  call psb_set_coher(ictxt,isvch)

  itx   = 0

  If (istop_ == 1) Then 
    ani = psb_spnrmi(a,desc_a,info)
    bni = psb_geamax(b,desc_a,info)
  Else If (istop_ == 2) Then 
    bn2 = psb_genrm2(b,desc_a,info)
  Endif
  if (info /= 0) Then 
     info=4011
     call psb_errpush(info,name)
     goto 9999
  End If

  restart: Do 
!!$   
!!$   r0 = b-Ax0
!!$ 
    if (itx >= litmax) exit restart  
    it = 0      
    call psb_geaxpby(zone,b,zzero,r,desc_a,info)
    call psb_spmm(-zone,a,x,zone,r,desc_a,info,work=aux)
    call psb_geaxpby(zone,r,zzero,q,desc_a,info)
    if (info /= 0) then 
       info=4011
       call psb_errpush(info,name)
       goto 9999
    end if
    
    rho = zzero
    if (debug_level >= psb_debug_ext_) &
         & write(debug_unit,*) me,' ',trim(name),&
         & ' On entry to AMAX: B: ',Size(b)
    
    !
    !   Must always provide norm of R into RNI below for first check on 
    !   residual
    !
    if (istop_ == 1) then 
      rni = psb_geamax(r,desc_a,info)
      xni = psb_geamax(x,desc_a,info)
    else if (istop_ == 2) then 
      rni = psb_genrm2(r,desc_a,info)
    endif
    errnum = dzero
    errden = done
    if (info /= 0) then 
       info=4011
       call psb_errpush(info,name)
       goto 9999
    end if

    if (itx == 0) then 
      rn0 = rni
    end if
    if (rn0 == 0.d0 ) exit restart
    
    if (istop_ == 1) then 
      xni  = psb_geamax(x,desc_a,info)
      errnum = rni
      errden = (ani*xni+bni)
    else  if (istop_ == 2) then 
      errnum = rni
      errden = bn2
    endif
    if (info /= 0) then 
       info=4011
       call psb_errpush(info,name)
       goto 9999
    end if

    if (errnum <= eps*errden) exit restart
    if (itrace_ > 0) &
         & call log_conv(methdname,me,itx,itrace_,errnum,errden,eps)

    iteration:  Do 
      it   = it + 1
      itx = itx + 1
      If (debug_level >= psb_debug_ext_)&
           & write(debug_unit,*) me,' ',trim(name),&
           & ' Iteration: ',itx
      rho_old = rho    
      rho = psb_gedot(q,r,desc_a,info)

      if (rho==zzero) then
         if (debug_level >= psb_debug_ext_) &
              & write(debug_unit,*) me,' ',trim(name),&
              & ' Iteration breakdown R',rho
        exit iteration
      endif

      if (it==1) then
        call psb_geaxpby(zone,r,zzero,p,desc_a,info)
      else
        beta = (rho/rho_old)*(alpha/omega)
        call psb_geaxpby(-omega,v,zone,p,desc_a,info)
        call psb_geaxpby(zone,r,beta,p,desc_a,info)
      end if

      call psb_precaply(prec,p,f,desc_a,info,work=aux)

      call psb_spmm(zone,a,f,zzero,v,desc_a,info,&
           & work=aux)

      sigma = psb_gedot(q,v,desc_a,info)
      if (sigma==zzero) then
         if (debug_level >= psb_debug_ext_) &
              & write(debug_unit,*) me,' ',trim(name),&
              & ' Iteration breakdown S1', sigma
         exit iteration
      endif
      if (debug_level >= psb_debug_ext_) &
           & write(debug_unit,*) me,' ',trim(name),&
           & ' SIGMA:',sigma
      alpha = rho/sigma
      call psb_geaxpby(zone,r,zzero,s,desc_a,info)
      if (info /= 0) then
         call psb_errpush(4010,name,a_err='psb_geaxpby')
         goto 9999
      end if
      call psb_geaxpby(-alpha,v,zone,s,desc_a,info)
      if (info /= 0) then
         call psb_errpush(4010,name,a_err='psb_geaxpby')
         goto 9999
      end if
      
      call psb_precaply(prec,s,z,desc_a,info,work=aux)
      if (info /= 0) then
         call psb_errpush(4010,name,a_err='psb_precaply')
         goto 9999
      end if

      call psb_spmm(zone,a,z,zzero,t,desc_a,info,&
           & work=aux)

      if (info /= 0) then
         call psb_errpush(4010,name,a_err='psb_spmm')
         goto 9999
      end if
      
      sigma = psb_gedot(t,t,desc_a,info)
      if (sigma==zzero) then
         if (debug_level >= psb_debug_ext_) &
              & write(debug_unit,*) me,' ',trim(name),&
              & ' Iteration breakdown S2', sigma
        exit iteration
      endif
      
      tau  = psb_gedot(t,s,desc_a,info)
      omega = tau/sigma
      
      if (omega==zzero) then
         if (debug_level >= psb_debug_ext_) &
              & write(debug_unit,*) me,' ',trim(name),&
              & ' Iteration breakdown O',omega
        exit iteration
      endif

      call psb_geaxpby(alpha,f,zone,x,desc_a,info)
      call psb_geaxpby(omega,z,zone,x,desc_a,info)
      call psb_geaxpby(zone,s,zzero,r,desc_a,info)
      call psb_geaxpby(-omega,t,zone,r,desc_a,info)
      
      if (istop_ == 1) then 
        rni = psb_geamax(r,desc_a,info)
        xni = psb_geamax(x,desc_a,info)
        errnum = rni
        errden = (ani*xni+bni)
      else  if (istop_ == 2) then 
        rni = psb_genrm2(r,desc_a,info)
        errnum = rni
        errden = bn2
      endif
      
      if (errnum <= eps*errden) exit restart
      if (itx >= litmax) exit restart
      if (itrace_ > 0) &
           & call log_conv(methdname,me,itx,itrace_,errnum,errden,eps)
      
    end do iteration
  end do restart

  if (itrace_ > 0) &
       & call log_conv(methdname,me,itx,1,errnum,errden,eps)
  
  if (present(err)) then 
    if (errden /= dzero) then 
      err = errnum/errden
    else
      err = errnum
    end if
  end if
  if (present(iter)) iter = itx
  if (errnum > eps*errden) &
       & call end_log(methdname,me,itx,errnum,errden,eps)

  deallocate(aux,stat=info)
  if (info == 0) call psb_gefree(wwrk,desc_a,info)
  if (info/=0) then
     call psb_errpush(info,name)
     goto 9999
  end if
  ! restore external global coherence behaviour
  call psb_restore_coher(ictxt,isvch)

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
     call psb_error(ictxt)
     return
  end if
  return

End Subroutine psb_zcgstab

