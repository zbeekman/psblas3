module psb_base_tools_cbind_mod
  use iso_c_binding
  use psb_base_mod
  use psb_objhandle_mod
  use psb_base_string_cbind_mod
    
contains
  
  function psb_c_error() bind(c) result(res)
    implicit none 
    integer(psb_c_int) :: res   
    res = 0
    call psb_error()
  end function psb_c_error
  
  function psb_c_clean_errstack() bind(c) result(res)
    implicit none 
    integer(psb_c_int) :: res   
    res = 0
    call psb_clean_errstack()
  end function psb_c_clean_errstack
  
  function psb_c_cdall_vg(ng,vg,ictxt,cdh) bind(c,name='psb_c_cdall_vg') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    integer(psb_c_int), value :: ng, ictxt
    integer(psb_c_int)        :: vg(*)
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1
    if (ng <=0) then 
      write(0,*) 'Invalid size'
      return
    end if

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call descp%free(info)
      if (info == 0) deallocate(descp,stat=info)
      if (info /= 0) return
    end if

    allocate(descp,stat=info)
    if (info < 0) return 
      
    call psb_cdall(ictxt,descp,info,vg=vg(1:ng))
    cdh%item = c_loc(descp)
    res = info

  end function psb_c_cdall_vg
  
  
  function psb_c_cdall_vl(nl,vl,ictxt,cdh) bind(c,name='psb_c_cdall_vl') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    integer(psb_c_int), value :: nl, ictxt
    integer(psb_c_int)        :: vl(*)
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1
    if (nl <=0) then 
      write(0,*) 'Invalid size'
      return
    end if

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call descp%free(info)
      if (info == 0) deallocate(descp,stat=info)
      if (info /= 0) return
    end if

    allocate(descp,stat=info)
    if (info < 0) return 
      
    call psb_cdall(ictxt,descp,info,vl=vl(1:nl))
    cdh%item = c_loc(descp)
    res = info

  end function psb_c_cdall_vl

  function psb_c_cdall_nl(nl,ictxt,cdh) bind(c,name='psb_c_cdall_nl') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    integer(psb_c_int), value :: nl, ictxt
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1
    if (nl <=0) then 
      write(0,*) 'Invalid size'
      return
    end if

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call descp%free(info)
      if (info == 0) deallocate(descp,stat=info)
      if (info /= 0) return
    end if

    allocate(descp,stat=info)
    if (info < 0) return 
      
    call psb_cdall(ictxt,descp,info,nl=nl)
    cdh%item = c_loc(descp)
    res = info

  end function psb_c_cdall_nl

  function psb_c_cdall_repl(n,ictxt,cdh) bind(c,name='psb_c_cdall_repl') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    integer(psb_c_int), value :: n, ictxt
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1
    if (n <=0) then 
      write(0,*) 'Invalid size'
      return
    end if

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call descp%free(info)
      if (info == 0) deallocate(descp,stat=info)
      if (info /= 0) return
    end if

    allocate(descp,stat=info)
    if (info < 0) return 
    
    call psb_cdall(ictxt,descp,info,mg=n,repl=.true.)
    cdh%item = c_loc(descp)
    res = info

  end function psb_c_cdall_repl
  
  function psb_c_cdasb(cdh) bind(c,name='psb_c_cdasb') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call psb_cdasb(descp,info)
      res = info
    end if

  end function psb_c_cdasb


 function psb_c_cdfree(cdh) bind(c,name='psb_c_cdfree') result(res)

    implicit none 
    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh
    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1
    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call descp%free(info)
      if (info == 0) deallocate(descp,stat=info)
      if (info /= 0) return
      cdh%item = c_null_ptr
    end if
    
    res = info
    return
  end function psb_c_cdfree

  function psb_c_cdins(nz,ia,ja,cdh) bind(c,name='psb_c_cdins') result(res)

    implicit none 
    integer(psb_c_int) :: res   
    integer(psb_c_int), value   :: nz
    type(psb_c_object_type) :: cdh
    integer(psb_c_int)          :: ia(*),ja(*)
    
    type(psb_desc_type), pointer :: descp
    integer                 :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      call psb_cdins(nz,ia(1:nz),ja(1:nz),descp,info)
      res = info
    end if
    return
  end function psb_c_cdins



  function psb_c_cd_get_local_rows(cdh) bind(c,name='psb_c_cd_get_local_rows') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh

    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      res = descp%get_local_rows()

    end if

  end function psb_c_cd_get_local_rows



  function psb_c_cd_get_local_cols(cdh) bind(c,name='psb_c_cd_get_local_cols') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh

    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      res = descp%get_local_cols()

    end if

  end function psb_c_cd_get_local_cols

  function psb_c_cd_get_global_rows(cdh) bind(c,name='psb_c_cd_get_global_rows') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh

    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      res = descp%get_global_rows()

    end if

  end function psb_c_cd_get_global_rows



  function psb_c_cd_get_global_cols(cdh) bind(c,name='psb_c_cd_get_global_cols') result(res)
    implicit none 

    integer(psb_c_int) :: res   
    type(psb_c_object_type) :: cdh

    type(psb_desc_type), pointer :: descp
    integer               :: info

    res = -1

    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
      res = descp%get_global_cols()

    end if

  end function psb_c_cd_get_global_cols


end module psb_base_tools_cbind_mod

