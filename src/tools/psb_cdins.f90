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
! File: psb_cdins.f90
!
! Subroutine: psb_cdins
!   Takes as input a cloud of points and updates the descriptor accordingly.
! 
! Parameters: 
!    nz       - integer.                       The number of points to insert.
!    ia       - integer,dimension(:).          The row indices of the points.
!    ja       - integer,dimension(:).          The column indices of the points.
!    desc_a   - type(<psb_desc_type>).         The communication descriptor to be freed.
!    info     - integer.                       Eventually returns an error code.
!    is       - integer(optional).             The row offset.
!    js       - integer(optional).             The column offset.
subroutine psb_cdins(nz,ia,ja,desc_a,info,is,js)

  use psb_descriptor_type
  use psb_serial_mod
  use psb_const_mod
  use psb_error_mod
  implicit none

  !....PARAMETERS...
  Type(psb_desc_type), intent(inout) :: desc_a
  Integer, intent(in)                :: nz,IA(:),JA(:)
  integer, intent(out)               :: info
  integer, intent(in), optional      :: is,js

  !LOCALS.....

  integer :: i,icontxt,nprocs ,glob_row,row,k,start_row,end_row,&
       & first_loc_row,j, ierror,locix,locjx,&
       & dectype,mglob, nnza, nglob,err
  integer,pointer        :: tia1(:),tia2(:), temp(:)
  integer                :: nprow,npcol, me ,mypcol, iflag, isize, irlc
  integer                :: m,n, pnt_halo,nrow,ncol, nh, ip,jp, err_act
  logical, parameter     :: debug=.false.
  integer, parameter     :: relocsz=200
  character(len=20)             :: name,ch_err

  info = 0
  name = 'psb_cdins'
  call psb_erractionsave(err_act)

  icontxt = desc_a%matrix_data(psb_ctxt_)
  dectype = desc_a%matrix_data(psb_dec_type_)
  mglob   = desc_a%matrix_data(psb_m_)
  nglob   = desc_a%matrix_data(psb_n_)
  nrow    = desc_a%matrix_data(psb_n_row_)
  ncol    = desc_a%matrix_data(psb_n_col_)

  ! check on blacs grid 
  call blacs_gridinfo(icontxt, nprow, npcol, me, mypcol)
  if (npcol.ne.1) then
    info = 2030
    call psb_errpush(info,name)
    goto 9999
  endif
  if (.not.psb_is_bld_dec(dectype)) then 
    info = 3110
    call psb_errpush(info,name)
    goto 9999
  endif

  if (nz <= 0) then 
    info = 1111
    call psb_errpush(info,name)
    goto 9999
  end if
  if (size(ia) < nz) then 
    info = 1111
    call psb_errpush(info,name)
    goto 9999
  end if
    
  if (size(ja) < nz) then 
    info = 1111
    call psb_errpush(info,name)
    goto 9999
  end if
    

  if (.not.associated(desc_a%halo_index)) then
    allocate(desc_a%halo_index(relocsz))
    desc_a%halo_index(:) = -1
  endif
  pnt_halo=1
  do while (desc_a%halo_index(pnt_halo) .ne.  -1 )
    pnt_halo = pnt_halo + 1
  end do
  isize = size(desc_a%halo_index)

  do i = 1, nz
    ip = ia(i) 
    jp = ja(i)
    if ((ip < 1 ).or.(ip>mglob).or.(jp<1).or.(jp>mglob)) then 
!      write(0,*) 'wrong input ',i,ip,jp
      info = 1133
      call psb_errpush(info,name)
      goto 9999
    endif
    if ((1<=desc_a%glob_to_loc(ip)).and.(desc_a%glob_to_loc(ip))<=nrow) then
      k  = desc_a%glob_to_loc(jp)
      if (k.lt.-nprow) then
        k = k + nprow
        k = - k - 1
        ncol = ncol + 1      
        desc_a%glob_to_loc(jp)   = ncol
        isize = size(desc_a%loc_to_glob)
        if (ncol > isize) then 
          nh = ncol + max(nz,relocsz)
          call psb_realloc(nh,desc_a%loc_to_glob,info,pad=-1)
          if (me==0) then 
            if (debug) write(0,*) 'done realloc ',nh
          end if
          if (info /= 0) then
             info=4010
             ch_err='psb_realloc'
             call psb_errpush(info,name)
             goto 9999
          end if
          isize = nh
        endif
        desc_a%loc_to_glob(ncol) = jp
        isize = size(desc_a%halo_index)
        if ((pnt_halo+3).gt.isize) then
          nh = isize + max(nz,relocsz)
          call psb_realloc(nh,desc_a%halo_index,info,pad=-1)
          if (info /= 0) then
             info=4010
             ch_err='psb_realloc'
             call psb_errpush(info,name)
             goto 9999
          end if
          isize = nh 
        endif
        desc_a%halo_index(pnt_halo)   = k
        desc_a%halo_index(pnt_halo+1) = 1
        desc_a%halo_index(pnt_halo+2) = ncol
        pnt_halo                      = pnt_halo + 3
      endif
    else
      ! currently we ignore items not belonging to us. 
    endif
  enddo
  desc_a%matrix_data(psb_n_col_) = ncol
  
  call psb_erractionrestore(err_act)
  return
  
9999 continue
  call psb_erractionrestore(err_act)
  
  if (err_act.eq.act_ret) then
     return
  else
     call psb_error(icontxt)
  end if
  return

end subroutine psb_cdins
