!!  Copyright (C)  Stichting Deltares, 2012-2023.
!!
!!  This program is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License version 3,
!!  as published by the Free Software Foundation.
!!
!!  This program is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with this program. If not, see <http://www.gnu.org/licenses/>.
!!
!!  contact: delft3d.support@deltares.nl
!!  Stichting Deltares
!!  P.O. Box 177
!!  2600 MH Delft, The Netherlands
!!
!!  All indications and logos of, and references to registered trademarks
!!  of Stichting Deltares remain the property of Stichting Deltares. All
!!  rights reserved.
      module m_integration_scheme_24
      use m_zercum
      use m_setset
      use m_proint
      use m_proces
      use m_hsurf
      use m_dlwqtr
      use m_dlwqt0


      implicit none

      contains


      subroutine integration_scheme_24 (buffer, lun   , lchar  ,
     &                    action, dlwqd , gridps)

!       Deltares Software Centre

!>\file
!>                         FCT horizontal, central implicit vertical, with adaptive timestep (24)
!>
!>                         Performs time dependent integration. Flux Corrected Transport
!>                         (Boris and Book) horizontally, central implicit vertically.\n
!>                         The timestep is locally adjusted if the stability for a segment requires this.\n
!>                         Method has the option to treat additional velocities, like
!>                         settling of suspended matter, upwind to avoid wiggles.\n

      use m_dlwqo2
      use m_dlwqf8
      use m_dlwqce
      use m_dlwqb3
      use m_dlwq41
      use m_dlwq19
      use m_dlwq17
      use m_dlwq15a
      use m_dlwq14
      use m_dlwq13
      use m_delpar01
      use m_move
      use m_fileutils
      use dlwqgrid_mod
      use timers
      use delwaq2_data
      use m_waq_openda_exchange_items, only : get_openda_buffer
      use waqmem          ! module with the more recently added arrays
      use m_actions
      use m_sysn          ! System characteristics
      use m_sysi          ! Timer characteristics
      use m_sysa          ! Pointers in real array workspace
      use m_sysj          ! Pointers in integer array workspace
      use m_sysc          ! Pointers in character array workspace
      use m_dlwqdata_save_restore

      implicit none


C
C     Declaration of arguments
C
      type(waq_data_buffer), target :: buffer      !< System total array space
      INTEGER, DIMENSION(*)       :: LUN
      CHARACTER*(*), DIMENSION(*) :: LCHAR
      INTEGER                     :: ACTION
      TYPE(DELWAQ_DATA), TARGET   :: DLWQD
      type(GridPointerColl)       :: GridPs               ! collection of all grid definitions

C
C     Local declarations
C
      LOGICAL         IMFLAG , IDFLAG , IHFLAG
      LOGICAL         LREWIN , LDUMM2
      REAL            RDUMMY(1)
      INTEGER         NSTEP
      INTEGER         IBND
      INTEGER         ISYS
      INTEGER         IERROR

      INTEGER         LAREA
      INTEGER         LDISP
      INTEGER         LDIFF
      INTEGER         LFLOW
      INTEGER         LNOQ
      INTEGER         LQDMP
      INTEGER         LVELO
      INTEGER         LXPNT
      INTEGER         sindex
      integer         i

      associate ( a => buffer%rbuf, j => buffer%ibuf, c => buffer%chbuf )

      if ( action == ACTION_FINALISATION ) then
          call dlwqdata_restore(dlwqd)
          if ( timon ) call timstrt ( "integration_scheme_24", ithandl )
          goto 20
      endif

      IF ( ACTION == ACTION_INITIALISATION  .OR.
     &     ACTION == ACTION_FULLCOMPUTATION        ) THEN

C
C          some initialisation
C
          ithandl = 0
          ITIME   = ITSTRT
          NSTEP   = (ITSTOP-ITSTRT)/IDT
          IFFLAG  = 0
          IAFLAG  = 0
          IBFLAG  = 0
          IF ( MOD(INTOPT,16) .GE. 8 ) IBFLAG = 1
          LDUMMY = .FALSE.
          IF ( NDSPN .EQ. 0 ) THEN
             NDDIM = NODISP
          ELSE
             NDDIM = NDSPN
          ENDIF
          IF ( NVELN .EQ. 0 ) THEN
             NVDIM = NOVELO
          ELSE
             NVDIM = NVELN
          ENDIF
          LSTREC = ICFLAG .EQ. 1
          FORESTER = BTEST(INTOPT,6)
          NOWARN   = 0

C
C          initialize second volume array with the first one
C
          nosss  = noseg + nseg2
          CALL MOVE   ( A(IVOL: ), A(IVOL2:) , nosss   )
      ENDIF

C
C     Save/restore the local persistent variables,
C     if the computation is split up in steps
C
C     Note: the handle to the timer (ithandl) needs to be
C     properly initialised and restored
C
      IF ( ACTION == ACTION_INITIALISATION ) THEN
          if ( timon ) call timstrt ( "integration_scheme_24", ithandl )
          call dlwqdata_save(dlwqd)
          if ( timon ) call timstop ( ithandl )
          RETURN
      ENDIF

      IF ( ACTION == ACTION_SINGLESTEP ) THEN
          call dlwqdata_restore(dlwqd)
      ENDIF

!          adaptations for layered bottom 08-03-2007  lp

      nosss  = noseg + nseg2
      NOQTT  = NOQ + NOQ4
      inwtyp = intyp + nobnd
C
C          set alternating set of pointers
C
      NOQT  = NOQ1+NOQ2
      LNOQ  = noqtt - noqt
      LDISP = IDISP+2
      LDIFF = IDNEW+NDDIM*NOQT
      LAREA = IAREA+NOQT
      LFLOW = IFLOW+NOQT
      LLENG = ILENG+NOQT*2
      LVELO = IVNEW+NVDIM*NOQT
      LXPNT = IXPNT+NOQT*4
      LQDMP = IQDMP+NOQT

      if ( timon ) call timstrt ( "integration_scheme_24", ithandl )

!======================= simulation loop ============================

   10 continue

!        Determine the volumes and areas that ran dry at start of time step

         call hsurf  ( nosss    , nopa     , c(ipnam:) , a(iparm:) , nosfun   ,
     &                 c(isfna:) , a(isfun:) , surface  , lun(19)  )
         call dryfld ( noseg    , nosss    , nolay    , a(ivol:)  , noq1+noq2,
     &                 a(iarea:) , nocons   , c(icnam:) , a(icons:) , surface  ,
     &                 j(iknmr:) , iknmkv   )

!          user transport processes

         call dlwqtr ( notot    , nosys    , nosss    , noq      , noq1     ,
     &                 noq2     , noq3     , nopa     , nosfun   , nodisp   ,
     &                 novelo   , j(ixpnt:) , a(ivol:)  , a(iarea:) , a(iflow:) ,
     &                 a(ileng:) , a(iconc:) , a(idisp:) , a(icons:) , a(iparm:) ,
     &                 a(ifunc:) , a(isfun:) , a(idiff:) , a(ivelo:) , itime    ,
     &                 idt      , c(isnam:) , nocons   , nofun    , c(icnam:) ,
     &                 c(ipnam:) , c(ifnam:) , c(isfna:) , ldummy   , ilflag   )

!jvb  Temporary ? set the variables grid-setting for the DELWAQ variables

         call setset ( lun(19)  , nocons   , nopa     , nofun    , nosfun   ,
     &                 nosys    , notot    , nodisp   , novelo   , nodef    ,
     &                 noloc    , ndspx    , nvelx    , nlocx    , nflux    ,
     &                 nopred   , novar    , nogrid   , j(ivset:) )

!        return conc and take-over from previous step or initial condition,
!        and do particle tracking of this step (will be back-coupled next call)

         call delpar01( itime   , noseg    , nolay    , noq      , nosys    ,
     &                  notot   , a(ivol:)  , surface  , a(iflow:) , c(isnam:) ,
     &                  nosfun  , c(isfna:) , a(isfun:) , a(imass:) , a(iconc:) ,
     &                  iaflag  , intopt   , ndmps    , j(isdmp:) , a(idmps:) ,
     &                  a(imas2:))

!          call PROCES subsystem

         call proces ( notot    , nosss    , a(iconc:) , a(ivol:)  , itime    ,
     &                 idt      , a(iderv:) , ndmpar   , nproc    , nflux    ,
     &                 j(iipms:) , j(insva:) , j(iimod:) , j(iiflu:) , j(iipss:) ,
     &                 a(iflux:) , a(iflxd:) , a(istoc:) , ibflag   , ipbloo   ,
     &                 ioffbl   ,  a(imass:) , nosys    ,
     &                 itfact   , a(imas2:) , iaflag   , intopt   , a(iflxi:) ,
     &                 j(ixpnt:) , iknmkv   , noq1     , noq2     , noq3     ,
     &                 noq4     , ndspn    , j(idpnw:) , a(idnew:) , nodisp   ,
     &                 j(idpnt:) , a(idiff:) , ndspx    , a(idspx:) , a(idsto:) ,
     &                 nveln    , j(ivpnw:) , a(ivnew:) , novelo   , j(ivpnt:) ,
     &                 a(ivelo:) , nvelx    , a(ivelx:) , a(ivsto:) , a(idmps:) ,
     &                 j(isdmp:) , j(ipdmp:) , ntdmpq   , a(idefa:) , j(ipndt:) ,
     &                 j(ipgrd:) , j(ipvar:) , j(iptyp:) , j(ivarr:) , j(ividx:) ,
     &                 j(ivtda:) , j(ivdag:) , j(ivtag:) , j(ivagg:) , j(iapoi:) ,
     &                 j(iaknd:) , j(iadm1:) , j(iadm2:) , j(ivset:) , j(ignos:) ,
     &                 j(igseg:) , novar    , a        , nogrid   , ndmps    ,
     &                 c(iprna:) , intsrt   ,
     &                 j(iprvpt:), j(iprdon:), nrref    , j(ipror:) , nodef    ,
     &                 surface  , lun(19)  )

!        set new boundaries

         if ( itime .ge. 0   ) then
!           first: adjust boundaries by OpenDA
            if ( dlwqd%inopenda ) then
               do ibnd = 1,nobnd
                  do isys = 1,nosys
                      call get_openda_buffer(isys,ibnd, 1,1,
     &                                A(ibset:+(ibnd-1)*nosys + isys-1))
                  enddo
               enddo
            endif
            call dlwq17 ( a(ibset:), a(ibsav:), j(ibpnt:), nobnd   , nosys   ,
     &                    notot   , idt     , a(iconc:), a(iflow:), a(iboun:))
         endif
C
C     Call OUTPUT system
C
      CALL DLWQO2 ( NOTOT   , nosss   , NOPA    , NOSFUN  , ITIME   ,
     +              C(IMNAM:), C(ISNAM:), C(IDNAM:), J(IDUMP:), NODUMP  ,
     +              A(ICONC:), A(ICONS:), A(IPARM:), A(IFUNC:), A(ISFUN:),
     +              A(IVOL:) , NOCONS  , NOFUN   , IDT     , NOUTP   ,
     +              LCHAR   , LUN     , J(IIOUT:), J(IIOPO:), A(IRIOB:),
     +              C(IOSNM:), C(IOUNI:), C(IODSC:), C(ISSNM:), C(ISUNI:), C(ISDSC:),
     +              C(IONAM:), NX      , NY      , J(IGRID:), C(IEDIT:),
     +              NOSYS   , A(IBOUN:), J(ILP:)  , A(IMASS:), A(IMAS2:),
     +              A(ISMAS:), NFLUX   , A(IFLXI:), ISFLAG  , IAFLAG  ,
     +              IBFLAG  , IMSTRT  , IMSTOP  , IMSTEP  , IDSTRT  ,
     +              IDSTOP  , IDSTEP  , IHSTRT  , IHSTOP  , IHSTEP  ,
     +              IMFLAG  , IDFLAG  , IHFLAG  , NOLOC   , A(IPLOC:),
     +              NODEF   , A(IDEFA:), ITSTRT  , ITSTOP  , NDMPAR  ,
     +              C(IDANA:), NDMPQ   , NDMPS   , J(IQDMP:), J(ISDMP:),
     +              J(IPDMP:), A(IDMPQ:), A(IDMPS:), A(IFLXD:), NTDMPQ  ,
     +              C(ICBUF:), NORAAI  , NTRAAQ  , J(IORAA:), J(NQRAA:),
     +              J(IQRAA:), A(ITRRA:), C(IRNAM:), A(ISTOC:), NOGRID  ,
     +              NOVAR   , J(IVARR:), J(IVIDX:), J(IVTDA:), J(IVDAG:),
     +              J(IAKND:), J(IAPOI:), J(IADM1:), J(IADM2:), J(IVSET:),
     +              J(IGNOS:), J(IGSEG:), A       , NOBND   , NOBTYP  ,
     +              C(IBTYP:), J(INTYP:), C(ICNAM:), noqtt   , J(IXPNT:),
     +              INTOPT  , C(IPNAM:), C(IFNAM:), C(ISFNA:), J(IDMPB:),
     +              NOWST   , NOWTYP  , C(IWTYP:), J(IWAST:), J(INWTYP:),
     +              A(IWDMP:), iknmkv  , isegcol )

!        zero cummulative array's

         if ( imflag .or. ( ihflag .and. noraai .gt. 0 ) ) then
            call zercum ( notot   , nosys   , nflux   , ndmpar  , ndmpq   ,
     &                    ndmps   , a(ismas:), a(iflxi:), a(imas2:), a(iflxd:),
     &                    a(idmpq:), a(idmps:), noraai  , imflag  , ihflag  ,
     &                    a(itrra:), ibflag  , nowst   , a(iwdmp:))
         endif

!        simulation done ?

         if ( itime .lt. 0      ) goto 9999
         if ( itime .ge. itstop ) goto 20

!        add processes

         call dlwq14 ( a(iderv:), notot   , nosss   , itfact  , a(imas2:),
     &                 idt     , iaflag  , a(idmps:), intopt  , j(isdmp:))

!        get new volumes

         itimel = itime
         itime  = itime + idt
         select case ( ivflag )
            case ( 1 )                 !     computation of volumes for computed volumes only
               call move   ( a(ivol:) , a(ivol2:), noseg   )
               call dlwqb3 ( a(iarea:), a(iflow:), a(ivnew:), j(ixpnt:), notot   ,
     &                       noq     , nvdim   , j(ivpnw:), a(ivol2:), intopt  ,
     &                       a(imas2:), idt     , iaflag  , nosys   , a(idmpq:),
     &                       ndmpq   , j(iqdmp:))
               updatr = .true.
            case ( 2 )                 !     the fraudulent computation option
               call dlwq41 ( lun     , itime   , itimel  , a(iharm:), a(ifarr:),
     &                       j(inrha:), j(inrh2:), j(inrft:), noseg   , a(ivoll:),
     &                       j(ibulk:), lchar   , ftype   , isflag  , ivflag  ,
     &                       updatr  , j(inisp:), a(inrsp:), j(intyp:), j(iwork:),
     &                       lstrec  , lrewin  , a(ivol2:), dlwqd   )
               call dlwqf8 ( noseg   , noq     , j(ixpnt:), idt     , iknmkv  ,
     &                       a(ivol: ), a(iflow:), a(ivoll:), a(ivol2:))
               updatr = .true.
               lrewin = .true.
               lstrec = .true.
            case default               !     read new volumes from files
               call dlwq41 ( lun     , itime   , itimel  , a(iharm:), a(ifarr:),
     &                       j(inrha:), j(inrh2:), j(inrft:), noseg   , a(ivol2:),
     &                       j(ibulk:), lchar   , ftype   , isflag  , ivflag  ,
     &                       updatr  , j(inisp:), a(inrsp:), j(intyp:), j(iwork:),
     &                       lstrec  , lrewin  , a(ivoll:) , dlwqd   )
         end select

!        update the info on dry volumes with the new volumes

         call dryfle ( noseg    , nosss    , a(ivol2:) , nolay    , nocons   ,
     &                 c(icnam:) , a(icons:) , surface  , j(iknmr:) , iknmkv   )

!          add the waste loads

         call dlwq15a( nosys    , notot    , noseg    , noq      , nowst    ,
     &                 nowtyp   , ndmps    , intopt   , idt      , itime    ,
     &                 iaflag   , c(isnam:) , a(iconc:) , a(ivol:)  , a(ivol2:) ,
     &                 a(iflow: ), j(ixpnt:) , c(iwsid:) , c(iwnam:) , c(iwtyp:) ,
     &                 j(inwtyp:), j(iwast:) , iwstkind , a(iwste:) , a(iderv:) ,
     &                 wdrawal  , iknmkv   , nopa     , c(ipnam:) , a(iparm:) ,
     &                 nosfun   , c(isfna: ), a(isfun:) , j(isdmp:) , a(idmps:) ,
     &                 a(imas2:) , a(iwdmp:) , 1        , notot    )

!        self adjusting time step size method

         call dlwq19 ( lun(19)  , nosys    , notot    , nototp   , noseg    ,
     &                 nosss    , noq1     , noq2     , noq3     , noq      ,
     &                 noq4     , nddim    , nvdim    , a(idisp:) , a(idnew:) ,
     &                 a(ivnew:) , a(ivol:)  , a(ivol2:) , a(iarea:) , a(iflow:) ,
     &                 surface  , a(ileng:) , j(ixpnt:) , j(idpnw:) , j(ivpnw:) ,
     &                 a(imass:) , a(iconc:) , dconc2   , a(iboun:) , idt      ,
     &                 ibas     , ibaf     , dwork    , volint   , iords    ,
     &                 iordf    , a(iderv:) , wdrawal  , iaflag   , a(imas2:) ,
     &                 ndmpq    , ndmps    , nowst    , j(iqdmp:) , a(idmpq:) ,
     &                 j(isdmp:) , a(idmps:) , j(iwast:) , a(iwdmp:) , intopt   ,
     &                 ilflag   , arhs     , adiag    , acodia   , bcodia   ,
     &                 nvert    , ivert    , nocons   , c(icnam:) , a(icons:) )

!          new time values, volumes excluded

         call dlwqt0 ( lun      , itime    , itimel   , a(iharm:) , a(ifarr:) ,
     &                 j(inrha:) , j(inrh2:) , j(inrft:) , idt      , a(ivol:)  ,
     &                 a(idiff:) , a(iarea:) , a(iflow:) , a(ivelo:) , a(ileng:) ,
     &                 a(iwste:) , a(ibset:) , a(icons:) , a(iparm:) , a(ifunc:) ,
     &                 a(isfun:) , j(ibulk:) , lchar    , c(ilunt:) , ftype    ,
     &                 intsrt   , isflag   , ifflag   , ivflag   , ilflag   ,
     &                 ldumm2   , j(iktim:) , j(iknmr:) , j(inisp:) , a(inrsp:) ,
     &                 j(intyp:) , j(iwork:) , .false.  , ldummy   , rdummy   ,
     &                 .false.  , gridps   , dlwqd    )

!        calculate closure error
         if ( lrewin .and. lstrec ) then
            call dlwqce ( a(imass:), a(ivoll:), a(ivol2:), nosys , notot ,
     &                       noseg   , lun(19) )
            call move   ( a(ivoll:), a(ivol:) , noseg   )
         else
!           replace old by new volumes
            call move   ( a(ivol2:), a(ivol:) , noseg   )
         endif

!          integrate the fluxes at dump segments fill ASMASS with mass

         if ( ibflag .gt. 0 ) then
            call proint ( nflux   , ndmpar  , idt     , itfact  , a(iflxd:),
     &                    a(iflxi:), j(isdmp:), j(ipdmp:), ntdmpq  )
         endif

!          end of loop

         if ( ACTION == ACTION_FULLCOMPUTATION ) goto 10

   20 continue

      if ( ACTION == ACTION_FINALISATION    .or.
     &     ACTION == ACTION_FULLCOMPUTATION      ) then

!            close files, except monitor file

             call CloseHydroFiles( dlwqd%collcoll )
             call close_files( lun )

!            write restart file

             CALL DLWQ13 ( LUN      , LCHAR , A(ICONC:) , ITIME , C(IMNAM:) ,
     *                     C(ISNAM:) , NOTOT , NOSSS    )
      endif

      end associate
 9999 if ( timon ) call timstop ( ithandl )

      dlwqd%iaflag = iaflag
      dlwqd%itime = itime

      RETURN
      END

      end module m_integration_scheme_24