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
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!	Module to   define PREC_DATA,           !!
!!      structure for preconditioning.          !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module psb_prec_type

  ! Reduces size of .mod file.
  use psb_base_mod, only : psb_dspmat_type, psb_zspmat_type, psb_desc_type,&
       & psb_sizeof

  integer, parameter :: psb_min_prec_=0, psb_noprec_=0, psb_diag_=1, &
       & psb_bjac_=2, psb_max_prec_=2

  ! Entries in iprcparm: preconditioner type, factorization type,
  ! prolongation type, restriction type, renumbering algorithm,
  ! number of overlap layers, pointer to SuperLU factors, 
  ! levels of fill in for ILU(N), 
  integer, parameter :: p_type_=1, f_type_=2
  integer, parameter :: ilu_fill_in_=8
  !Renumbering. SEE BELOW
  integer, parameter :: renum_none_=0, renum_glb_=1, renum_gps_=2
  integer, parameter :: ifpsz=10
  ! Entries in dprcparm: ILU(E) epsilon, smoother omega
  integer, parameter :: fact_eps_=1
  integer, parameter :: dfpsz=4
  ! Factorization types: none, ILU(N), ILU(E)
  integer, parameter :: f_none_=0,f_ilu_n_=1,f_ilu_e_=2
  ! Fields for sparse matrices ensembles: 
  integer, parameter :: l_pr_=1, u_pr_=2, bp_ilu_avsz=2
  integer, parameter :: ap_nd_=3, ac_=4, sm_pr_t_=5, sm_pr_=6
  integer, parameter :: smth_avsz=6, max_avsz=smth_avsz 


  type psb_dprec_type
    type(psb_dspmat_type), allocatable :: av(:) 
    real(kind(1.d0)), allocatable      :: d(:)  
    type(psb_desc_type)                :: desc_data 
    integer, allocatable               :: iprcparm(:) 
    real(kind(1.d0)), allocatable      :: dprcparm(:) 
    integer, allocatable               :: perm(:),  invperm(:) 
    integer                       :: prec, base_prec
  end type psb_dprec_type

  type psb_zprec_type
    type(psb_zspmat_type), allocatable :: av(:) 
    complex(kind(1.d0)), allocatable   :: d(:)  
    type(psb_desc_type)                :: desc_data 
    integer, allocatable               :: iprcparm(:) 
    real(kind(1.d0)), allocatable      :: dprcparm(:) 
    integer, allocatable               :: perm(:),  invperm(:) 
    integer                       :: prec, base_prec
  end type psb_zprec_type


  character(len=15), parameter, private :: &
       &  fact_names(0:2)=(/'None          ','ILU(n)        ',&
       &  'ILU(eps)      '/)

  interface psb_precfree
    module procedure psb_d_precfree, psb_z_precfree
  end interface

  interface psb_nullify_prec
    module procedure psb_nullify_dprec, psb_nullify_zprec
  end interface

  interface psb_check_def
    module procedure psb_icheck_def, psb_dcheck_def
  end interface

  interface psb_prec_descr
    module procedure psb_out_prec_descr, psb_file_prec_descr, &
         &  psb_zout_prec_descr, psb_zfile_prec_descr
  end interface

  interface psb_sizeof
    module procedure psb_dprec_sizeof, psb_zprec_sizeof
  end interface

contains

  subroutine psb_out_prec_descr(p)
    use psb_base_mod
    type(psb_dprec_type), intent(in) :: p
    call psb_file_prec_descr(6,p)
  end subroutine psb_out_prec_descr

  subroutine psb_zout_prec_descr(p)
    use psb_base_mod
    type(psb_zprec_type), intent(in) :: p
    call psb_zfile_prec_descr(6,p)
  end subroutine psb_zout_prec_descr

  subroutine psb_file_prec_descr(iout,p)
    use psb_base_mod
    integer, intent(in)              :: iout
    type(psb_dprec_type), intent(in) :: p
    
    write(iout,*) 'Preconditioner description'
    select case(p%iprcparm(p_type_))
    case(psb_noprec_)
      write(iout,*) 'No preconditioning'
    case(psb_diag_)
      write(iout,*) 'Diagonal scaling'
    case(psb_bjac_)
      write(iout,*) 'Block Jacobi with: ',&
           &  fact_names(p%iprcparm(f_type_))
    end select
    
  end subroutine psb_file_prec_descr

  subroutine psb_zfile_prec_descr(iout,p)
    use psb_base_mod
    integer, intent(in)              :: iout
    type(psb_zprec_type), intent(in) :: p

    write(iout,*) 'Preconditioner description'
    select case(p%iprcparm(p_type_))
    case(psb_noprec_)
      write(iout,*) 'No preconditioning'
    case(psb_diag_)
      write(iout,*) 'Diagonal scaling'
    case(psb_bjac_)
      write(iout,*) 'Block Jacobi with: ',&
           &  fact_names(p%iprcparm(f_type_))
    end select
  end subroutine psb_zfile_prec_descr


  function is_legal_prec(ip)
    use psb_base_mod
    integer, intent(in) :: ip
    logical             :: is_legal_prec

    is_legal_prec = ((ip>=noprec_).and.(ip<=bjac_))
    return
  end function is_legal_prec
  function is_legal_ml_fact(ip)
    use psb_base_mod
    integer, intent(in) :: ip
    logical             :: is_legal_ml_fact

    is_legal_ml_fact = ((ip>=f_ilu_n_).and.(ip<=f_ilu_e_))
    return
  end function is_legal_ml_fact
  function is_legal_ml_eps(ip)
    use psb_base_mod
    real(kind(1.d0)), intent(in) :: ip
    logical             :: is_legal_ml_eps

    is_legal_ml_eps = (ip>=0.0d0)
    return
  end function is_legal_ml_eps


  subroutine psb_icheck_def(ip,name,id,is_legal)
    use psb_base_mod
    integer, intent(inout) :: ip
    integer, intent(in)    :: id
    character(len=*), intent(in) :: name
    interface 
      function is_legal(i)
        integer, intent(in) :: i
        logical             :: is_legal
      end function is_legal
    end interface

    if (.not.is_legal(ip)) then     
      write(0,*) 'Illegal value for ',name,' :',ip, '. defaulting to ',id
      ip = id
    end if
  end subroutine psb_icheck_def

  subroutine psb_dcheck_def(ip,name,id,is_legal)
    use psb_base_mod
    real(kind(1.d0)), intent(inout) :: ip
    real(kind(1.d0)), intent(in)    :: id
    character(len=*), intent(in) :: name
    interface 
      function is_legal(i)
        real(kind(1.d0)), intent(in) :: i
        logical             :: is_legal
      end function is_legal
    end interface

    if (.not.is_legal(ip)) then     
      write(0,*) 'Illegal value for ',name,' :',ip, '. defaulting to ',id
      ip = id
    end if
  end subroutine psb_dcheck_def

  subroutine psb_d_precfree(p,info)
    use psb_base_mod
    type(psb_dprec_type), intent(inout) :: p
    integer, intent(out)                :: info
    integer             :: me, err_act,i
    character(len=20)   :: name
    if(psb_get_errstatus() /= 0) return 
    info=0
    name = 'psb_precfree'
    call psb_erractionsave(err_act)

    me=-1

    ! Actually we migh just deallocate the top level array, except 
    ! for the inner UMFPACK or SLU stuff

    if (allocated(p%d)) then 
      deallocate(p%d,stat=info)
    end if

    if (allocated(p%av))  then 
      do i=1,size(p%av) 
        call psb_sp_free(p%av(i),info)
        if (info /= 0) then 
          ! Actually, we don't care here about this.
          ! Just let it go.
          ! return
        end if
      enddo
      deallocate(p%av,stat=info)
    end if

    if (allocated(p%desc_data%matrix_data)) &
         & call psb_cdfree(p%desc_data,info)

    if (allocated(p%dprcparm)) then 
      deallocate(p%dprcparm,stat=info)
    end if

    if (allocated(p%perm)) then 
      deallocate(p%perm,stat=info)
    endif

    if (allocated(p%invperm)) then 
      deallocate(p%invperm,stat=info)
    endif

    if (allocated(p%iprcparm)) then 
      deallocate(p%iprcparm,stat=info)
    end if
    call psb_nullify_prec(p)

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine psb_d_precfree

  subroutine psb_nullify_dprec(p)
    use psb_base_mod
    type(psb_dprec_type), intent(inout) :: p

!!$    nullify(p%av,p%d,p%iprcparm,p%dprcparm,p%perm,p%invperm,p%mlia,&
!!$         & p%nlaggr,p%base_a,p%base_desc,p%dorig,p%desc_data, p%desc_ac)

  end subroutine psb_nullify_dprec

  subroutine psb_z_precfree(p,info)
    use psb_base_mod
    type(psb_zprec_type), intent(inout) :: p
    integer, intent(out)                :: info
    integer             :: err_act,i
    character(len=20)   :: name
    if(psb_get_errstatus() /= 0) return 
    info=0
    name = 'psb_precfree'
    call psb_erractionsave(err_act)

    if (allocated(p%d)) then 
      deallocate(p%d,stat=info)
    end if

    if (allocated(p%av))  then 
      do i=1,size(p%av) 
        call psb_sp_free(p%av(i),info)
        if (info /= 0) then 
          ! Actually, we don't care here about this.
          ! Just let it go.
          ! return
        end if
      enddo
      deallocate(p%av,stat=info)

    end if
    if (allocated(p%desc_data%matrix_data)) &
         & call psb_cdfree(p%desc_data,info)

    if (allocated(p%dprcparm)) then 
      deallocate(p%dprcparm,stat=info)
    end if

    if (allocated(p%perm)) then 
      deallocate(p%perm,stat=info)
    endif

    if (allocated(p%invperm)) then 
      deallocate(p%invperm,stat=info)
    endif

    if (allocated(p%iprcparm)) then 
      deallocate(p%iprcparm,stat=info)
    end if
    call psb_nullify_prec(p)
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_z_precfree

  subroutine psb_nullify_zprec(p)
    use psb_base_mod
    type(psb_zprec_type), intent(inout) :: p


  end subroutine psb_nullify_zprec


  function pr_to_str(iprec)
    use psb_base_mod

    integer, intent(in)  :: iprec
    character(len=10)     :: pr_to_str

    select case(iprec)
    case(psb_noprec_)
      pr_to_str='NOPREC'
    case(psb_diag_)         
      pr_to_str='DIAG'
    case(psb_bjac_)         
      pr_to_str='BJAC'
    case default
      pr_to_str='???'
    end select

  end function pr_to_str


  function psb_dprec_sizeof(prec)
    use psb_base_mod
    type(psb_dprec_type), intent(in) :: prec
    integer             :: psb_dprec_sizeof
    integer             :: val,i
    
    val = 0
    if (allocated(prec%iprcparm)) val = val + 4 * size(prec%iprcparm)
    if (allocated(prec%dprcparm)) val = val + 8 * size(prec%dprcparm)
    if (allocated(prec%d))        val = val + 8 * size(prec%d)
    if (allocated(prec%perm))     val = val + 4 * size(prec%perm)
    if (allocated(prec%invperm))  val = val + 4 * size(prec%invperm)
                                  val = val + psb_sizeof(prec%desc_data)
    if (allocated(prec%av))  then 
      do i=1,size(prec%av)
        val = val + psb_sizeof(prec%av(i))
      end do
    end if
    
    psb_dprec_sizeof = val 
    
  end function psb_dprec_sizeof

  function psb_zprec_sizeof(prec)
    use psb_base_mod
    type(psb_zprec_type), intent(in) :: prec
    integer             :: psb_zprec_sizeof
    integer             :: val,i
    
    val = 0
    if (allocated(prec%iprcparm)) val = val + 4 * size(prec%iprcparm)
    if (allocated(prec%dprcparm)) val = val + 8 * size(prec%dprcparm)
    if (allocated(prec%d))        val = val + 16 * size(prec%d)
    if (allocated(prec%perm))     val = val + 4 * size(prec%perm)
    if (allocated(prec%invperm))  val = val + 4 * size(prec%invperm)
                                  val = val + psb_sizeof(prec%desc_data)
    if (allocated(prec%av))  then 
      do i=1,size(prec%av)
        val = val + psb_sizeof(prec%av(i))
      end do
    end if
    
    psb_zprec_sizeof = val 
    
  end function psb_zprec_sizeof
    

end module psb_prec_type
