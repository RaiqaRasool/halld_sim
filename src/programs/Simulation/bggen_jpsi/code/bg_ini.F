      SUBROUTINE BG_INI(IERR)
C
C---      Initialize the FFREAD and the relevant variables
C
      IMPLICIT NONE
      INTEGER IERR
C
      INCLUDE 'bg_ctrl.inc'
      INCLUDE 'bg_partc.inc'
      INCLUDE 'bg_reac.inc'
C
      INTEGER mxffr,jffr
      PARAMETER (mxffr=10000)
      COMMON/CFREAD/ jffr(mxffr)
C
      INTEGER ier
C
      INTEGER i,j,lun,lout,iost,ip,kd(4),kf,lenc,idgea
      REAL am,wg
      CHARACTER cline*132
C
      lout=6
      IERR=1
C
      CALL HBOOK_INI
C
      NEVENT=0
      RUNNO=2
      IWROUT(1)=1
      IWROUT(2)=0
      IWROUT(3)=0
      IRND_SEQ=0
      NPRIEV=0
      EPH_LIM(1)=0.15
      EPH_LIM(2)=12.
      EELEC=12.  ! electron energy
      EPEAK=9.   ! peak right edge
      ZCOLL=7600.
      DCOLL=0.0034
      EPYMIN=3.  ! min energy for PYTHIA
      ELOWMIN=0.15
      ISIMUL=0  ! regular BG (=1 - J/psi)
      IPINIT(1)=1  ! photon
      IPINIT(2)=14 ! proton
      RADINI=0
      RADCORR=0
C
      LUNWR(1)=0   ! HDDS file - LUN not used
      LUNWR(2)=2   ! sequential file
      LUNWR(3)=3   ! NTUPLE file
C
      DO i=1,2
         IPREAC(i)=-1
      ENDDO
      TSLREAC=-1.
      ELREAC(1)=-1.
      ELREAC(2)=-1.
      NPXREAC=0
      DO i=1,MXPNTR
         XSREAC(i)=0.
         ESREAC(i)=0.
      ENDDO
C---    Redefine FFREAD settings
C
      CALL FFINIT(mxffr)
      CALL FFSET('LINP',15)
      CALL FFSET('LOUT',6)
      CALL FFSET('SIZE',16)
      CALL FFSET('LENG',120)
C
      CALL FFKEY('TRIG'      , NEVENT     , 1,'INTEGER')
      CALL FFKEY('RUNNO'     , RUNNO      , 1,'INTEGER')
      CALL FFKEY('WROUT'     , IWROUT(1)  , 3,'INTEGER')
      CALL FFKEY('RNDMSEQ'   , IRND_SEQ   , 1,'INTEGER')
      CALL FFKEY('NPRIEV'    , NPRIEV     , 1,'INTEGER')
      CALL FFKEY('EPHLIM'    , EPH_LIM(1) , 2,'REAL')
      CALL FFKEY('EELEC'     , EELEC      , 1,'REAL')
      CALL FFKEY('EPEAK'     , EPEAK      , 1,'REAL')
      CALL FFKEY('ZCOLLIM'   , ZCOLL      , 1,'REAL')
      CALL FFKEY('DCOLLIM'   , DCOLL      , 1,'REAL')      
      CALL FFKEY('EPYTHMIN'  , EPYMIN     , 1,'REAL')
      CALL FFKEY('ELOWMIN'   , ELOWMIN    , 1,'REAL')
      CALL FFKEY('VERTEX'    , VERTEX(1) , 3,'REAL')
      CALL FFKEY('SIMUL'     , ISIMUL     , 1,'INTEGER')
      CALL FFKEY('PARTINIT'  , IPINIT(1)  , 2,'INTEGER')
      CALL FFKEY('REACPAR'   , IPREAC(1)  , MXPNTR+6,'MIXED')
      CALL FFKEY('RADCORR'   , RADCORR    , 1,'INTEGER')
C
      CALL FFGO
C
C
C---   Read the particle masses (GEANT numbering)
C
cc
      DO ip=1,MXPART
         IFLPART(ip)=0
         AM_PART(ip)=0.
         WG_PART(ip)=0.
         DO i=1,4
            KD_PART(i,ip)=0
         ENDDO
      ENDDO
C
      lun=9
      OPEN(lun,FILE='particle.dat',STATUS='OLD',IOSTAT=iost
     +       ,FORM='FORMATTED')
      IF(iost.NE.0) THEN
         WRITE(lout,*) ' *** ERROR: Missing file particle.dat'
         GO TO 999
      ENDIF
 10   READ(lun,FMT='(A)',IOSTAT=iost) cline
      IF(iost.EQ.0) THEN
C
         IF(cline(1:1).NE.'*'.AND.cline(1:1).NE.'C') THEN
            READ(cline,*) ip,am,wg,kd
C            write(6,*) ip,am,wg,kd
            IF(ip.GT.0.AND.ip.LE.MXPART) THEN
               IFLPART(ip)=1
               AM_PART(ip)=am
               WG_PART(ip)=wg
               DO i=1,4
                  KD_PART(i,ip)=kd(i)
               ENDDO
            ELSE
               WRITE(lout,*) ' --- ERROR: Reading file particle.dat ',
     +              'GEANT index is out of range ',ip 
            ENDIF
         ENDIF
C
         GO TO 10
C
      ELSE IF(iost.GT.0) THEN
         WRITE(lout,*) ' *** ERROR: Reading file particle.dat'
         GO TO 999
      ENDIF
C
      DO i=1,2
         ier=1
         IF(IPINIT(i).GT.0.OR.IPINIT(i).LE.MXPART) THEN
            IF(IFLPART(IPINIT(i)).NE.0) THEN
               ier=0
            ENDIF
         ENDIF
         IF(ier.NE.0) THEN
            WRITE(6,1001) i,IPINIT(i)
 1001              FORMAT('  *** Init. error: PARTINIT:',I1,I5,
     +                                    ' not defined')
            GO TO 999
         ENDIF
      ENDDO
C
C---   Read the GEANT<->PYTHIA particle table
C      
      DO i=1,MXPGEANT
         IPLUND(i)=0
         IDECLUND(i)=0
      ENDDO
      DO i=-MXPKC,MXPKC
         KCGEAN(i)=0
      ENDDO
C
      OPEN(lun,FILE='pythia-geant.map',STATUS='OLD',IOSTAT=iost
     +       ,FORM='FORMATTED')
      IF(iost.NE.0) THEN
         WRITE(lout,*) ' *** ERROR: Missing file pythia-geant.map'
         GO TO 999
      ENDIF
 15   READ(lun,'(A)',IOSTAT=iost) cline
      IF(iost.EQ.0) THEN
C
         lenc=0
         DO i=1,LEN_TRIM(cline)
            IF(cline(i:i).EQ.'!') GO TO 20
            lenc=i
         ENDDO
 20      CONTINUE
         IF(lenc.GE.3) THEN
            READ(cline(1:lenc),*) j,kf
            idgea=ABS(j)
         ENDIF
         IF(idgea.GT.0.AND.idgea.LE.MXPGEANT) THEN
            IF(kf.NE.0) THEN
               IPLUND(idgea) =kf
               IF(j.LT.0) IDECLUND(idgea)=1
            ENDIF
         ENDIF
C
         GO TO 15
C
      ELSE IF(iost.GT.0) THEN
         WRITE(lout,*) ' *** ERROR: Reading file pythia-geant.map'
         GO TO 999
      ENDIF
      CLOSE(lun)
C
      CALL RND_INI(IRND_SEQ)  ! random number initialization
C
      IF(EPH_LIM(1).LT.ELOWMIN) THEN
         WRITE(6,1005) ELOWMIN
 1005    FORMAT('  --- Initialization warning: EPH_LIM(1) is set'
     +         ,' to ELOWMIN:',F10.4)
         EPH_LIM(1)=ELOWMIN
      ENDIF
C
      IF(EPH_LIM(1).GT.EPH_LIM(2)) THEN
         WRITE(6,1000) EPH_LIM
 1000    FORMAT('  *** Initialization error: energy limits:',2F10.4)
         GO TO 999
      ELSE IF(EPH_LIM(1).EQ.EPH_LIM(2)) THEN
C
C---      Increase E2 slightly in order to make a valid histogram
C
         EPH_LIM(2)=EPH_LIM(1)*1.0001
C
      ELSE
C
C---       Bremsstrahlung beam: the E0 and Epeak should be cosistent
C
         IF(EELEC.LT.EPH_LIM(2)) THEN
            WRITE(6,1010) EELEC,EPH_LIM(2)
 1010       FORMAT('  *** Initialization error: Ee<E2:',2F10.4)
            GO TO 999
         ENDIF
C
         IF(EPEAK.GE.EELEC) THEN
            WRITE(6,1020) EPEAK,EELEC
 1020       FORMAT('  *** Initialization error: peak>Ee:',2F10.4)
            GO TO 999
         ENDIF
C
      ENDIF
C
      IF(ISIMUL.EQ.1) THEN   ! J/psi and other binary reactions
        ier=0
        DO i=1,2
           IF(IPREAC(i).LT.1.OR.IPREAC(i).GT.MXPART) ier=1
        ENDDO
        IF(ELREAC(1).GT.EPH_LIM(2).OR.ELREAC(2).LT.EPH_LIM(1).OR.
     +     ELREAC(1).LT.0..OR.ELREAC(2).LT.0.) ier=2 
        IF(NPXREAC.LT.2) ier=3
        IF(ier.NE.0) THEN
           WRITE(6,1030) IPREAC,TSLREAC,ELREAC,NPXREAC
 1030            FORMAT('  *** Initialization error REAC: :',
     +                                  4I4,3E11.3,I6)
           GO TO 999
        ENDIF
        DO i=1,NPXREAC
           ESREAC(i)=ELREAC(1)+(ELREAC(2)-ELREAC(1))/(NPXREAC-1)*(i-1)
C           write(6,*) i,ESREAC(i)
        ENDDO
C
      ENDIF
C
C---    Beam spectrum
C
      IDBEAM=9000
      NHBEA=0
      CALL COHBEAM_INI(IDBEAM,EELEC,EPEAK,EPH_LIM,ZCOLL,DCOLL)
C
C---   Pythia
C
      IFPYTH=0
      IF(EPH_LIM(2).GT.EPYMIN) THEN
         CALL PYTH_INI(ier)
         IF(ier.NE.0) GO TO 999
         IFPYTH=1
      ENDIF
C
C---   Low energy processes
C
      IDLOWEN=0
      IF(EPH_LIM(1).LT.EPYMIN) THEN
         IDLOWEN=10000
         CALL LOWEN_INI(ier)
         IF(ier.NE.0) GO TO 999
      ENDIF
C
C---   Output file for HDDM
C
      IF(IWROUT(1).NE.0) THEN
         CALL OPEN_HDDM_OUTPUT('bggen.hddm')
      ENDIF
C
C---   Sequential output file
C
      IF(IWROUT(2).NE.0) THEN
         OPEN(LUNWR(2),FILE='bggen.dat',STATUS='UNKNOWN'
     +       ,FORM='UNFORMATTED')
      ENDIF
C
C---   NTUPLE
C
      IF(IWROUT(3).NE.0) THEN
         CALL BG_NTUP_INI(ier)
         IF(ier.NE.0) GO TO 999
      ENDIF
C
      IERR=0
 999  RETURN
      END

      
