module psb_d_nullprec
  use psb_prec_type

  
  type, extends(psb_d_base_prec_type) :: psb_d_null_prec_type
  contains
    procedure, pass(prec) :: apply     => d_null_apply
    procedure, pass(prec) :: precbld   => d_null_precbld
    procedure, pass(prec) :: precinit  => d_null_precinit
    procedure, pass(prec) :: d_base_precseti  => d_null_precseti
    procedure, pass(prec) :: d_base_precsetr  => d_null_precsetr
    procedure, pass(prec) :: d_base_precsetc  => d_null_precsetc
    procedure, pass(prec) :: precfree         => d_null_precfree
    procedure, pass(prec) :: precdescr        => d_null_precdescr
    procedure, pass(prec) :: sizeof           => d_null_sizeof
  end type psb_d_null_prec_type


contains
  

  subroutine d_null_apply(alpha,prec,x,beta,y,desc_data,info,trans,work)
    use psb_base_mod
    type(psb_desc_type),intent(in)    :: desc_data
    class(psb_d_null_prec_type), intent(in)  :: prec
    real(psb_dpk_),intent(in)         :: x(:)
    real(psb_dpk_),intent(in)         :: alpha, beta
    real(psb_dpk_),intent(inout)      :: y(:)
    integer, intent(out)              :: info
    character(len=1), optional        :: trans
    real(psb_dpk_),intent(inout), optional, target :: work(:)
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_prec_apply'

    call psb_erractionsave(err_act)

    !
    ! This is the base version and we should throw an error. 
    ! Or should it be the NULL preonditioner???
    !
    info = 0 
    
    nrow = psb_cd_get_local_rows(desc_data)
    if (size(x) < nrow) then 
      info = 36
      call psb_errpush(info,name,i_err=(/2,nrow,0,0,0/))
      goto 9999
    end if
    if (size(y) < nrow) then 
      info = 36
      call psb_errpush(info,name,i_err=(/3,nrow,0,0,0/))
      goto 9999
    end if

    call psb_geaxpby(alpha,x,beta,y,desc_data,info)
    if (info /= 0 ) then 
      info = 4010
      call psb_errpush(infoi,name,a_err="psb_geaxpby")
      goto 9999
    end if
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine d_null_apply


  subroutine d_null_precinit(prec,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_d_null_prec_type),intent(inout) :: prec
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precinit'

    call psb_erractionsave(err_act)

    info = 0

    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_null_precinit

  subroutine d_null_precbld(a,desc_a,prec,info,upd)
    
    use psb_base_mod
    Implicit None
    
    type(psb_d_sparse_mat), intent(in), target :: a
    type(psb_desc_type), intent(in), target  :: desc_a
    class(psb_d_null_prec_type),intent(inout) :: prec
    integer, intent(out)                     :: info
    character, intent(in), optional          :: upd
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precbld'

    call psb_erractionsave(err_act)

    info = 0

    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_null_precbld

  subroutine d_null_precseti(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_d_null_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    integer, intent(in)                      :: val 
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precset'

    call psb_erractionsave(err_act)

    info = 0
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_null_precseti

  subroutine d_null_precsetr(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_d_null_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    real(psb_dpk_), intent(in)               :: val 
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precset'

    call psb_erractionsave(err_act)

    info = 0
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_null_precsetr

  subroutine d_null_precsetc(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_d_null_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    character(len=*), intent(in)             :: val
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precset'

    call psb_erractionsave(err_act)

    info = 0
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_null_precsetc

  subroutine d_null_precfree(prec,info)
    
    use psb_base_mod
    Implicit None

    class(psb_d_null_prec_type), intent(inout) :: prec
    integer, intent(out)                :: info
    
    Integer :: err_act, nrow
    character(len=20)  :: name='d_null_precset'
    
    call psb_erractionsave(err_act)
    
    info = 0
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine d_null_precfree
  

  subroutine d_null_precdescr(prec,iout)
    
    use psb_base_mod
    Implicit None

    class(psb_d_null_prec_type), intent(in) :: prec
    integer, intent(in), optional    :: iout

    Integer :: err_act, nrow, info
    character(len=20)  :: name='d_null_precset'
    integer :: iout_

    call psb_erractionsave(err_act)

    info = 0
   
    if (present(iout)) then 
      iout_ = iout
    else
      iout_ = 6 
    end if

    write(iout_,*) 'No preconditioning'

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine d_null_precdescr

  function d_null_sizeof(prec) result(val)
    use psb_base_mod
    class(psb_d_null_prec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val
    
    val = 0

    return
  end function d_null_sizeof

end module psb_d_nullprec