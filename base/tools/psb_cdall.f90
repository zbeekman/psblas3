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
! File: psb_cdall.f90
!
! Subroutine: psb_cdall
!    Allocate descriptor
!    and checks correctness of PARTS subroutine
! 
! Parameters: 
!    m       - integer.                       The number of rows.
!    n       - integer.                       The number of columns.
!    parts   - external subroutine.           The routine that contains the partitioning scheme.
!    ictxt - integer.                       The communication context.
!    desc_a  - type(<psb_desc_type>).         The communication descriptor.
!    info    - integer.                       Eventually returns an error code
subroutine psb_cdall(m, n, parts, ictxt, desc_a, info)
  use psb_error_mod
  use psb_descriptor_type
  use psb_realloc_mod
  use psb_serial_mod
  use psb_const_mod
  use psb_penv_mod
  implicit None
  include 'parts.fh'
  !....Parameters...
  Integer, intent(in)                 :: M,N,ictxt
  Type(psb_desc_type), intent(out)    :: desc_a
  integer, intent(out)                :: info

  !locals
  Integer             :: counter,i,j,np,me,loc_row,err,loc_col,nprocs,&
       & l_ov_ix,l_ov_el,idx, err_act, itmpov, k, ns, glx
  integer             :: int_err(5),exch(2)
  integer, allocatable  :: prc_v(:), temp_ovrlap(:), ov_idx(:),ov_el(:)
  logical, parameter  :: debug=.false.
  character(len=20)   :: name, char_err

  if(psb_get_errstatus() /= 0) return 
  info=0
  err=0
  name = 'psb_cdall'
  call psb_erractionsave(err_act)

  call psb_info(ictxt, me, np)
  if (debug) write(*,*) 'psb_cdall: ',np,me
  !     ....verify blacs grid correctness..

  !... check m and n parameters....
  if (m < 1) then
    info = 10
    err=info
    int_err(1) = 1
    int_err(2) = m
    call psb_errpush(err,name,int_err)
    goto 9999
  else if (n < 1) then
    info = 10
    err=info
    int_err(1) = 2
    int_err(2) = n
    call psb_errpush(err,name,int_err)
    goto 9999
  endif


  if (debug) write(*,*) 'psb_cdall:  doing global checks'  
  !global check on m and n parameters
  if (me == psb_root_) then
    exch(1)=m
    exch(2)=n
    call psb_bcast(ictxt,exch(1:2),root=psb_root_)
  else
    call psb_bcast(ictxt,exch(1:2),root=psb_root_)
    if (exch(1) /= m) then
      err=550
      int_err(1)=1
      call psb_errpush(err,name,int_err)
      goto 9999
    else if (exch(2) /= n) then
      err=550
      int_err(1)=2
      call psb_errpush(err,name,int_err)
      goto 9999
    endif
  endif

  call psb_nullify_desc(desc_a)

  !count local rows number
  ! allocate work vector
  if (m > psb_cd_get_large_threshold()) then 
    allocate(desc_a%matrix_data(psb_mdata_size_),&
         & temp_ovrlap(m),prc_v(np),stat=info)
  else
    allocate(desc_a%glob_to_loc(m),desc_a%matrix_data(psb_mdata_size_),&
         & temp_ovrlap(m),prc_v(np),stat=info)
  end if
  if (info /= 0) then     
    info=2025
    int_err(1)=m
    call psb_errpush(info,name,i_err=int_err)
    goto 9999
  endif


  if (debug) write(*,*) 'PSB_CDALL:  starting main loop' ,info
  counter = 0
  itmpov  = 0
  temp_ovrlap(:) = -1
  if ( m >psb_cd_get_large_threshold()) then 
    desc_a%matrix_data(psb_dec_type_) = psb_desc_large_bld_
    loc_col = (m+np-1)/np
        allocate(desc_a%loc_to_glob(loc_col), desc_a%lprm(1),&
         & desc_a%ptree(2),stat=info)  
    if (info == 0) call InitPairSearchTree(desc_a%ptree,info)
    if (info /= 0) then
      info=2025
      int_err(1)=loc_col
      call psb_errpush(info,name,i_err=int_err)
      goto 9999
    end if

    ! set LOC_TO_GLOB array to all "-1" values
    desc_a%lprm(1) = 0
    desc_a%loc_to_glob(:) = -1
    k = 0
    do i=1,m
      if (info == 0) then
        call parts(i,m,np,prc_v,nprocs)
        if (nprocs > np) then
          info=570
          int_err(1)=3
          int_err(2)=np
          int_err(3)=nprocs
          int_err(4)=i
          err=info
          call psb_errpush(err,name,int_err)
          goto 9999
        else if (nprocs <= 0) then
          info=575
          int_err(1)=3
          int_err(2)=nprocs
          int_err(3)=i
          err=info
          call psb_errpush(err,name,int_err)
          goto 9999
        else
          do j=1,nprocs
            if ((prc_v(j) > np-1).or.(prc_v(j) < 0)) then
              info=580
              int_err(1)=3
              int_err(2)=prc_v(j)
              int_err(3)=i
              err=info
              call psb_errpush(err,name,int_err)
              goto 9999
            end if
          end do
        endif
        j=1
        do 
          if (j > nprocs) exit
          if (prc_v(j) == me) exit
          j=j+1
        enddo
        
        if (j <= nprocs) then 
          if (prc_v(j) == me) then
            ! this point belongs to me
            k = k + 1 
            call psb_check_size((k+1),desc_a%loc_to_glob,info,pad=-1)
            if (info /= 0) then
              info=4010
              call psb_errpush(info,name,a_err='psb_check_size')
              goto 9999
            end if
            desc_a%loc_to_glob(k) = i
            call SearchInsKeyVal(desc_a%ptree,i,k,glx,info)
            if (nprocs > 1)  then
              call psb_check_size((itmpov+3+nprocs),temp_ovrlap,info,pad=-1)
              if (info /= 0) then
                info=4010
                call psb_errpush(info,name,a_err='psb_check_size')
                goto 9999
              end if
              itmpov = itmpov + 1
              temp_ovrlap(itmpov) = i
              itmpov = itmpov + 1
              temp_ovrlap(itmpov) = nprocs
              temp_ovrlap(itmpov+1:itmpov+nprocs) = prc_v(1:nprocs)
              itmpov = itmpov + nprocs
            endif
          end if
        end if        
      end if
    enddo
    if (info /= 0) then 
      info=4000
      call psb_errpush(info,name)
      goto 9999
    endif
    loc_row = k 

  else

    desc_a%matrix_data(psb_dec_type_) = psb_desc_bld_
    do i=1,m
      if (info == 0) then
        call parts(i,m,np,prc_v,nprocs)
        if (nprocs > np) then
          info=570
          int_err(1)=3
          int_err(2)=np
          int_err(3)=nprocs
          int_err(4)=i
          err=info
          call psb_errpush(err,name,int_err)
          goto 9999
        else if (nprocs <= 0) then
          info=575
          int_err(1)=3
          int_err(2)=nprocs
          int_err(3)=i
          err=info
          call psb_errpush(err,name,int_err)
          goto 9999
        else
          do j=1,nprocs
            if ((prc_v(j) > np-1).or.(prc_v(j) < 0)) then
              info=580
              int_err(1)=3
              int_err(2)=prc_v(j)
              int_err(3)=i
              err=info
              call psb_errpush(err,name,int_err)
              goto 9999
            end if
          end do
        endif
        desc_a%glob_to_loc(i) = -(np+prc_v(1)+1)
        j=1
        do 
          if (j > nprocs) exit
          if (prc_v(j) == me) exit
          j=j+1
        enddo
        if (j <= nprocs) then 
          if (prc_v(j) == me) then
            ! this point belongs to me
            counter=counter+1
            desc_a%glob_to_loc(i) = counter
            if (nprocs > 1)  then
              call psb_check_size((itmpov+3+nprocs),temp_ovrlap,info,pad=-1)
              if (info /= 0) then
                info=4010
                call psb_errpush(info,name,a_err='psb_check_size')
                goto 9999
              end if
              itmpov = itmpov + 1
              temp_ovrlap(itmpov) = i
              itmpov = itmpov + 1
              temp_ovrlap(itmpov) = nprocs
              temp_ovrlap(itmpov+1:itmpov+nprocs) = prc_v(1:nprocs)
              itmpov = itmpov + nprocs
            endif
          end if
        end if
      endif
    enddo
    ! estimate local cols number 
    loc_row=counter
    loc_col=min(2*loc_row,m)

    allocate(desc_a%loc_to_glob(loc_col),&
         &desc_a%lprm(1),stat=info)  
    if (info /= 0) then 
      call psb_errpush(4010,name,a_err='Allocate')
      goto 9999      
    end if

    ! set LOC_TO_GLOB array to all "-1" values
    desc_a%lprm(1) = 0
    desc_a%loc_to_glob(:) = -1
    do i=1,m
      k = desc_a%glob_to_loc(i) 
      if (k > 0) then 
        desc_a%loc_to_glob(k) = i
      endif
    enddo

  end if

  ! check on parts function
  if (debug) write(*,*) 'PSB_CDALL:  End main loop:' ,loc_row,itmpov,info


  if (debug) write(*,*) 'PSB_CDALL:  error check:' ,err

  l_ov_ix=0
  l_ov_el=0
  i = 1
  do while (temp_ovrlap(i) /= -1) 
    idx = temp_ovrlap(i)
    i=i+1
    nprocs = temp_ovrlap(i)
    i = i + 1
    l_ov_ix = l_ov_ix+3*(nprocs-1)
    l_ov_el = l_ov_el + 2
    i = i + nprocs     
  enddo

  l_ov_ix = l_ov_ix+3  
  l_ov_el = l_ov_el+3

  if (debug) write(*,*) 'PSB_CDALL: Ov len',l_ov_ix,l_ov_el
  allocate(ov_idx(l_ov_ix),ov_el(l_ov_el), stat=info)
  if (info /= no_err) then
    info=4010
    char_err='psb_realloc'
    err=info
    call psb_errpush(err,name,a_err=char_err)
    goto 9999
  end if

  l_ov_ix=0
  l_ov_el=0
  i = 1
  do while (temp_ovrlap(i) /= -1) 
    idx = temp_ovrlap(i)
    i   = i+1
    nprocs = temp_ovrlap(i)
    ov_el(l_ov_el+1)  = idx
    ov_el(l_ov_el+2)  = nprocs
    l_ov_el           = l_ov_el+2
    do j=1, nprocs
      if (temp_ovrlap(i+j) /= me) then
        ov_idx(l_ov_ix+1) = temp_ovrlap(i+j)
        ov_idx(l_ov_ix+2) = 1
        ov_idx(l_ov_ix+3) = idx
        l_ov_ix = l_ov_ix+3
      endif
    enddo
    i = i + nprocs +1
  enddo
  l_ov_el         = l_ov_el + 1
  ov_el(l_ov_el)  = -1
  l_ov_ix         = l_ov_ix + 1
  ov_idx(l_ov_ix) = -1

  call psb_transfer(ov_idx,desc_a%ovrlap_index,info) 
  if (info == 0) call psb_transfer(ov_el,desc_a%ovrlap_elem,info)
  if (info == 0) deallocate(prc_v,temp_ovrlap,stat=info)
  if (info /= no_err) then 
    info=4000
    err=info
    call psb_errpush(err,name)
    Goto 9999
  endif
  ! At this point overlap_elem is OK. 
  desc_a%matrix_data(psb_ovl_state_) = psb_cd_ovl_asb_

  ! set fields in desc_a%MATRIX_DATA....
  desc_a%matrix_data(psb_n_row_)  = loc_row
  desc_a%matrix_data(psb_n_col_)  = loc_row
  call psb_cd_set_bld(desc_a,info)

  call psb_realloc(1,desc_a%halo_index, info)
  if (info /= no_err) then
    info=2025
    char_err='psb_realloc'
    call psb_errpush(err,name,a_err=char_err)
    Goto 9999
  end if

  desc_a%halo_index(:) = -1

  desc_a%matrix_data(psb_m_)        = m
  desc_a%matrix_data(psb_n_)        = n
  desc_a%matrix_data(psb_ctxt_)     = ictxt
  call psb_get_mpicomm(ictxt,desc_a%matrix_data(psb_mpi_c_))

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == act_abort) then
    call psb_error(ictxt)
    return
  end if
  return

end subroutine psb_cdall