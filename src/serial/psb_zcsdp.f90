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
! File:  psb_zcsdp.f90 
!
! Subroutine: psb_zcsdp
!    This subroutine performs the assembly of
!    the local part of a sparse distributed matrix
!
! Parameters:
!   a      -  type(<psb_spmat_type>).         The input matrix to be assembled.
!   b      -  type(<psb_spmat_type>).         The assembled output matrix.
!   info   -  integer.                        Eventually returns an error code.
!   ifc    -  integer(optional).              ???
!   check  -  character(optional).            ???
!   trans  -  character(optional).            ???
!   unitd  -  character(optional).            ???
!
subroutine psb_zcsdp(a, b,info,ifc,check,trans,unitd)
  use psb_const_mod
  use psb_error_mod
  use psb_spmat_type

  implicit none
  !....Parameters...
  Type(psb_zspmat_type), intent(in)    :: A
  Type(psb_zspmat_type), intent(inout) :: B
  Integer, intent(out)                 :: info
  Integer, intent(in), optional        :: ifc
  character, intent(in), optional      :: check,trans,unitd

  !...Locals...
  complex(kind(1.d0))              :: d(1)
  complex(kind(1.d0)), allocatable :: work(:)
  type(psb_zspmat_type)         :: temp_a
  Integer                       :: nzr, ntry, ifc_,ierror, ia1_size,&
       & ia2_size, aspk_size,size_req,n_row,n_col,iup
  integer                       :: ip1, ip2, nnz, iflag, ichk, nnzt,&
       & ipc, i, count, err_act, ierrv(5)
  character                     :: check_,trans_,unitd_, up
  Integer, Parameter            :: maxtry=8
  logical, parameter            :: debug=.false.
  character(len=20)             :: name, ch_err

  interface psb_cest
     subroutine psb_cest(afmt, m,n,nnz, lia1, lia2, lar, up, info)
       integer, intent(in) ::  m,n,nnz 
       integer, intent(out) :: lia1, lia2, lar, info
       character, intent(inout) :: afmt*5
       character, intent(in) :: up
     end subroutine psb_cest
  end interface

  interface psb_spinfo
    subroutine psb_zspinfo(ireq,a,ires,info,iaux)
      use psb_spmat_type
      type(psb_zspmat_type), intent(in) :: a
      integer, intent(in)               :: ireq
      integer, intent(out)              :: ires, info
      integer, intent(in), optional     :: iaux
    end subroutine psb_zspinfo
  end interface

  name='psb_zcsdp'
  info  = 0
  call psb_erractionsave(err_act)

  ntry=0
  if (present(ifc)) then 
    ifc_  = max(1,ifc)
  else 
    ifc_ = 1
  endif
  if (present(check)) then 
    check_ = check 
  else 
    check_ = 'N'
  endif
  if (present(trans)) then 
    trans_ = trans 
  else 
    trans_ = 'N'
  endif
  if (present(unitd)) then 
    unitd_ = unitd 
  else 
    unitd_ = 'U'
  endif

  if (check_=='R') then 
    allocate(work(max(size(a%aspk),size(b%aspk))+1000),stat=info)
  else
    allocate(work(max(size(a%ia1),size(b%ia1),&
         &     size(a%ia2),size(b%ia2))+max(a%m,b%m)+1000),stat=info)
  endif
  if (info /= 0) then
    info=2040
    call psb_errpush(info,name)
    goto 9999
  end if
  if (ifc_<1) then 
    write(0,*) 'dcsdp90 Error: invalid ifc ',ifc_
    info = -4
    call psb_errpush(info,name)
    goto 9999
  endif

  if((check_=='Y').or.(check_=='C')) then
    if(a%fida(1:3)=='CSR') then
      call zcsrck(trans,a%m,a%k,a%descra,a%aspk,a%ia1,a%ia2,work,size(work),info)
      if(info /= 0) then
        info=4010
        ch_err='dcsrck'
        call psb_errpush(info,name,a_err=ch_err)
        goto 9999
      end if

    else
      write(0,'("Check not yet suported for the ",a3," storage format")')a%fida(1:3)
    end if

  end if

  if (check_/='R') then
    !  ...matrix conversion...
    b%m=a%m
    b%k=a%k
    call psb_spinfo(psb_nztotreq_,a,size_req,info)
    if (debug) write(0,*) 'DCSDP : size_req 1:',size_req
    !! PULL IUP FROM INFOA FIELD
    iup = iand(b%infoa(psb_upd_),4) 
    if (iup > 0) then 
      up = 'Y'
    else
      up = 'N'
    endif
    n_row=b%m 
    n_col=b%k
    call psb_cest(b%fida, n_row,n_col,size_req,&
         & ia1_size, ia2_size, aspk_size, up,info)

!!$    write(0,*) 'ESTIMATE : ',ia1_size,ia2_size,aspk_Size,iup
    if (info /= no_err) then    
      info=4010
      ch_err='psb_cest'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    endif
    if ((size(b%aspk)  < aspk_size) .or.&
         &(size(b%ia1) < ia1_size) .or.&
         &(size(b%ia2) < ia2_size) .or.&
         &(size(b%pl)  < b%m) .or.&
         &(size(b%pr) < b%k )) then 
      call psb_sp_reall(b,ia1_size,ia2_size,aspk_size,info)
    endif
    if (info /= no_err) then    
      info=4010
      ch_err='psb_sp_reall'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    endif
    
    b%pl(:)  = 0
    b%pr(:)  = 0
    

    select case (a%fida(1:3))

    case ('CSR')

      select case (b%fida(1:3))

      case ('CSR')


        call zcrcr(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
             & a%ia1, a%ia2, a%infoa, b%pl, b%descra, b%aspk, b%ia1,&
             & b%ia2, b%infoa, b%pr, size(b%aspk), size(b%ia1),&
             & size(b%ia2), work, size(work), info)


        if (info/=0) then
          info=4010
          ch_err='dcrcr'
          call psb_errpush(info,name,a_err=ch_err)
          goto 9999
        end if

      case ('JAD')

        !...converting to JAD
        !...output matrix may not be big enough

        do

          call zcrjd(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
               & a%ia1, a%ia2, a%infoa, b%pl, b%descra, b%aspk, b%ia1,&
               & b%ia2, b%infoa, b%pr, size(b%aspk), size(b%ia1),&
               & size(b%ia2), work, size(work), nzr, info)
          if (info /= 0) then
            call psb_errpush(4010,name,a_err='dcrjd')
            goto 9999
          endif

          ntry = ntry + 1
          if (debug) then 
            write(0,*) 'On out from dcrjad ',nzr,info
          end if
          if (nzr == 0) exit
          if (ntry > maxtry ) then 
            write(0,*) 'Tried reallocating for DCRJAD for ',maxtry,': giving up now.'
            info=2040
            call psb_errpush(info,name)
            goto 9999
          endif

          call psb_sp_reall(b,nzr,info,ifc=ifc_)
          if (info /= 0) then
            info=2040
            call psb_errpush(info,name)
            goto 9999
          endif

        end do

        if (info/=0) then
          call psb_errpush(info,name)
          goto 9999
        end if

      case ('COO')

        call zcrco(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
             & a%ia1, a%ia2, a%infoa, b%pl, b%descra, b%aspk, b%ia1,&
             & b%ia2, b%infoa, b%pr, size(b%aspk), size(b%ia1),&
             & size(b%ia2), work, size(work), info)

        if (info/=0) then
          call psb_errpush(4010,name,a_err='dcrco')
          goto 9999
        end if

      end select

    case ('COO','COI')

      select case (b%fida(1:3))

      case ('CSR')

        call zcocr(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
             & a%ia2, a%ia1, a%infoa, b%pl, b%descra, b%aspk, b%ia1,&
             & b%ia2, b%infoa, b%pr, size(b%aspk), size(b%ia1),&
             & size(b%ia2), work, 2*size(work), info)

        if (info/=0) then
          call psb_errpush(4010,name,a_err='dcocr')
          goto 9999
        end if

      case ('JAD')

        call psb_sp_all(temp_a, size(b%ia1),size(b%ia2),size(b%aspk),info)
        if (info /= 0) then
          info=2040
          call psb_errpush(info,name)
          goto 9999
        endif
        temp_a%m = a%m
        temp_a%k = a%k

        !...Dirty trick: converting to CSR and then to JAD

        call zcocr(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
             & a%ia2, a%ia1, a%infoa, temp_a%pl, temp_a%descra, &
             & temp_a%aspk, temp_a%ia1, temp_a%ia2, temp_a%infoa, temp_a%pr, &
             & size(temp_a%aspk), size(temp_a%ia1),&
             & size(temp_a%ia2), work, 2*size(work), info)

        if (info/=0) then
          call psb_errpush(4010,name,a_err='dcocr')
          goto 9999
        end if

        do
          call zcrjd(trans_, temp_a%m, temp_a%k, unitd_, d, temp_a%descra, &
               & temp_a%aspk, temp_a%ia1, temp_a%ia2, temp_a%infoa, &
               & b%pl, b%descra, b%aspk, b%ia1, b%ia2, b%infoa, b%pr, &
               & size(b%aspk), size(b%ia1),&
               & size(b%ia2), work, size(work), nzr, info)
          if (info/=0) then
            call psb_errpush(4010,name,a_err='dcrjd')
            goto 9999
          end if

          ntry = ntry + 1
          if (debug) then 
            write(0,*) 'On out from dcrjad ',nzr,info
          end if
          if (nzr == 0) exit
          if (ntry > maxtry ) then 
            write(0,*) 'Tried reallocating for DCRJAD for ',maxtry,&
                 & ': giving up now.'
            info=2040
            call psb_errpush(info,name)
            goto 9999
          endif

          call psb_sp_reall(b,nzr,info,ifc=ifc_)
          if (info /= 0) then
            info=2040
            call psb_errpush(info,name)
            goto 9999
          endif

        end do



      case ('COO')

        call zcoco(trans_, a%m, a%k, unitd_, d, a%descra, a%aspk,&
             & a%ia1, a%ia2, a%infoa, b%pl, b%descra, b%aspk, b%ia1,&
             & b%ia2, b%infoa, b%pr, size(b%aspk), size(b%ia1),&
             & size(b%ia2), work, 2*size(work), info)
        if (info/=0) then
          call psb_errpush(4010,name,a_err='dcoco')
          goto 9999
        end if

      end select

    end select

  else if (check_=='R') then
    !...Regenerating matrix    
    if (b%infoa(psb_state_) /= psb_spmat_upd_) then 
      info = 8888
      call psb_errpush(info,name)
      goto 9999
    endif
    if (ibits(b%infoa(psb_upd_),2,1).eq.0) then 
      !
      !       Nothing to be done......
      !
      info = 8888
      call psb_errpush(info,name)
      goto 9999
    endif


    if (b%fida(1:3)/='JAD') then
      ip1   = b%infoa(psb_upd_pnt_) 
      ip2   = b%ia2(ip1+psb_ip2_)
      nnz   = b%ia2(ip1+psb_nnz_)
      iflag = b%ia2(ip1+psb_iflag_)
      ichk  = b%ia2(ip1+psb_ichk_)
      nnzt  = b%ia2(ip1+psb_nnzt_)
      if (debug) write(*,*) 'Regeneration start: ',&
           &   b%infoa(psb_upd_),psb_perm_update_,nnz,nnzt ,iflag,info

      if ((ichk/=nnzt+iflag).or.(nnz/=nnzt)) then               
        info = 8889
        write(*,*) 'Regeneration start error: ',&
             &   b%infoa(psb_upd_),psb_perm_update_,nnz,nnzt ,iflag,ichk              
        call psb_errpush(info,name)
        goto 9999
      endif
      do i= 1, nnz
        work(i) = 0.d0
      enddo
      if (iflag.eq.2) then 
        do i=1, nnz 
          work(b%ia2(ip2+i-1)) = b%aspk(i) 
        enddo
      else if (iflag.eq.3) then 
        do i=1, nnz 
          work(b%ia2(ip2+i-1)) = b%aspk(i) + work(b%ia2(ip2+i-1)) 
        enddo
      endif
      do i=1, nnz
        b%aspk(i) = work(i)
      enddo

    else if (b%fida(1:3) == 'JAD') then

      ip1   = b%infoa(psb_upd_pnt_) 
      ip2   = b%ia1(ip1+psb_ip2_)
      count = b%ia1(ip1+psb_zero_)
      ipc   = b%ia1(ip1+psb_ipc_)
      nnz   = b%ia1(ip1+psb_nnz_)
      iflag = b%ia1(ip1+psb_iflag_)
      ichk  = b%ia1(ip1+psb_ichk_)
      nnzt  = b%ia1(ip1+psb_nnzt_)
      if (debug) write(*,*) 'Regeneration start: ',&
           &  b%infoa(psb_upd_),psb_perm_update_,nnz,nnzt,count, &
           &  iflag,info

      if ((ichk/=nnzt+iflag).or.(nnz/=nnzt)) then               
        info = 10
        write(*,*) 'Regeneration start error: ',&
             &  b%infoa(psb_upd_),psb_perm_update_,nnz,nnzt ,iflag,ichk     
        call psb_errpush(info,name)
        goto 9999
      endif

      do i= 1, nnz+count
        work(i) = 0.d0
      enddo
      if (iflag.eq.2) then 
        do i=1, nnz 
          work(b%ia1(ip2+i-1)) = b%aspk(i) 
        enddo
      else if (iflag.eq.3) then 
        do i=1, nnz 
          work(b%ia1(ip2+i-1)) = b%aspk(i) + work(b%ia1(ip2+i-1)) 
        enddo
      endif
      do i=1, nnz+count 
        b%aspk(i) = work(i)
      enddo
      do i=1, count
        b%aspk(b%ia1(ipc+i-1)) = 0.d0
      end do
    endif


  end if
  b%infoa(psb_state_) = psb_spmat_asb_
  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act.eq.act_abort) then
    call psb_error()
    return
  end if
  return

end subroutine psb_zcsdp