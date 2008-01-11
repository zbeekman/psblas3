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
! File:  psb_dcg.f90
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
! File:  psb_dcg.f90
!
! Subroutine: psb_dcg
!    This subroutine implements the Conjugate Gradient method.
!
!
! Arguments:
!
!    a      -  type(psb_dspmat_type)      Input: sparse matrix containing A.
!    prec   -  type(psb_dprec_type)       Input: preconditioner
!    b      -  real,dimension(:)          Input: vector containing the
!                                         right hand side B
!    x      -  real,dimension(:)          Input/Output: vector containing the
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
!
subroutine psb_dcg(a,prec,b,x,eps,desc_a,info,itmax,iter,err,itrace,istop)
  use psb_base_mod
  use psb_prec_mod
  use psb_krylov_mod, psb_protect_name => psb_dcg
  implicit none

!!$  Parameters 
  Type(psb_dspmat_type), Intent(in)  :: a
  Type(psb_dprec_type), Intent(in)   :: prec 
  Type(psb_desc_type), Intent(in)    :: desc_a
  Real(Kind(1.d0)), Intent(in)       :: b(:)
  Real(Kind(1.d0)), Intent(inout)    :: x(:)
  Real(Kind(1.d0)), Intent(in)       :: eps
  integer, intent(out)               :: info
  Integer, Optional, Intent(in)      :: itmax, itrace, istop
  Integer, Optional, Intent(out)     :: iter
  Real(Kind(1.d0)), Optional, Intent(out) :: err
!!$   Local data
  real(kind(1.d0)), allocatable, target   :: aux(:), wwrk(:,:)
  real(kind(1.d0)), pointer  :: q(:), p(:), r(:), z(:), w(:)
  real(kind(1.d0))    ::alpha, beta, rho, rho_old, rni, xni, bni, ani,bn2,& 
       & sigma
  integer         :: litmax, istop_, naux, mglob, it, itx, itrace_,&
       & np,me, n_col, isvch, ictxt, n_row,err_act, int_err(5)
  logical, parameter :: exchange=.true., noexchange=.false.  
  real(kind(1.d0))   :: errnum, errden
  character(len=20)           :: name
  character(len=*), parameter :: methdname='CG'

  info = 0
  name = 'psb_dcg'
  call psb_erractionsave(err_act)

  ictxt = psb_cd_get_context(desc_a)

  call psb_info(ictxt, me, np)


  mglob = psb_cd_get_global_rows(desc_a)
  n_row = psb_cd_get_local_rows(desc_a)
  n_col = psb_cd_get_local_cols(desc_a)

  if (present(istop)) then 
    istop_ = istop 
  else
    istop_ = 1
  endif
  !
  !  ISTOP_ = 1:  Normwise backward error, infinity norm 
  !  ISTOP_ = 2:  ||r||/||b||   norm 2 
  !

  if ((istop_ < 1 ).or.(istop_ > 2 ) ) then
    write(0,*) 'psb_cg: invalid istop',istop_ 
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

  naux=4*n_col
  allocate(aux(naux), stat=info)
  if (info == 0) call psb_geall(wwrk,desc_a,info,n=5)
  if (info == 0) call psb_geasb(wwrk,desc_a,info)  
  if (info /= 0) then 
    info=4011
    call psb_errpush(info,name)
    goto 9999
  end if

  p  => wwrk(:,1)
  q  => wwrk(:,2)
  r  => wwrk(:,3)
  z  => wwrk(:,4) 
  w  => wwrk(:,5)


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

  itx=0

  ! Ensure global coherence for convergence checks.
  call psb_set_coher(ictxt,isvch)

  restart: do 
!!$   
!!$    r0 = b-Ax0
!!$   
    if (itx>= litmax) exit restart 
    it = 0
    call psb_geaxpby(done,b,dzero,r,desc_a,info)
    call psb_spmm(-done,a,x,done,r,desc_a,info,work=aux)
    if (info /= 0) then 
      info=4011
      call psb_errpush(info,name)
      goto 9999
    end if

    rho = dzero
    if (istop_ == 1) then 
      ani = psb_spnrmi(a,desc_a,info)
      bni = psb_geamax(b,desc_a,info)
    else if (istop_ == 2) then 
      bn2 = psb_genrm2(b,desc_a,info)
    endif
    errnum = dzero
    errden = done
    if (info /= 0) then 
      info=4011
      call psb_errpush(info,name)
      goto 9999
    end if


    iteration:  do 
      it   = it + 1
      itx = itx + 1

      call psb_precaply(prec,r,z,desc_a,info,work=aux)
      rho_old = rho
      rho     = psb_gedot(r,z,desc_a,info)

      if (it==1) then
        call psb_geaxpby(done,z,dzero,p,desc_a,info)
      else
        if (rho_old==dzero) then
          write(0,*) 'CG Iteration breakdown'
          exit iteration
        endif
        beta = rho/rho_old
        call psb_geaxpby(done,z,beta,p,desc_a,info)
      end if

      call psb_spmm(done,a,p,dzero,q,desc_a,info,work=aux)
      sigma = psb_gedot(p,q,desc_a,info)
      if (sigma==dzero) then
        write(0,*) 'CG Iteration breakdown'
        exit iteration
      endif

      alpha = rho/sigma
      call psb_geaxpby(alpha,p,done,x,desc_a,info)
      call psb_geaxpby(-alpha,q,done,r,desc_a,info)


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
      if (itx>= litmax) exit restart 

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

  call psb_gefree(wwrk,desc_a,info)
  if (info /= 0) then 
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
    call psb_error()
    return
  end if
  return

end subroutine psb_dcg


