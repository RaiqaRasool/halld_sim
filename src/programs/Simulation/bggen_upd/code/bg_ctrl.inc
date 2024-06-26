C
C--- Flags to control the job
C
C
      INTEGER    MXRADP,MXEVSEL
      PARAMETER (MXRADP=10,MXEVSEL=5)
C
      COMMON/PHCTRL/ NEVENT,RUNNO,EPH_LIM(2),EELEC,EPEAK
     +              ,ZCOLL,EPYMIN,ELOWMIN
     +              ,DCOLL,EEMIT,RADT
     +              ,IWROUT(3),LUNWR(3),IRND_SEQ,NPRIEV
     +              ,IDBEAM,NHBEA,PHLIM(2),IBEATYP
     +              ,IFPYTH,LISTPYTH,AMLIST
     +              ,IDLOWEN
     +              ,RATESEC
     +              ,VERTEX(3)
     +              ,ISIMUL,IPINIT(2)
     +              ,NRADCOR,IRADCORR(MXRADP)
     +              ,IDTDIST
     +              ,KFEVSEL(MXEVSEL),PAREVSEL(4),NFEVSEL(MXEVSEL)
     +              ,NFEFINAL
     +              ,NUCLTARG,IGNUCLT,IDNUCLT,AMNUCLS,AMNUCLN,SFSCALE
      INTEGER   NEVENT    ! number of events to simulate (F)
     +         ,RUNNO     ! run number to use (F)
     +         ,IWROUT    ! (1)>0 - write out the HDDS file (events) (F)
C                           (2)>0 - write out a sequential file
C                           (3)>0 - write out an ntuple file
     +         ,LUNWR     ! (1) LUN for HDDS file
C                           (2) LUN for the sequential file
C                           (3) LUN for the ntuple file
     +         ,IRND_SEQ  ! the random number sequence (each integer number gives a different sequence) (F)
     +         ,NPRIEV    ! number of events to print (F)
     +         ,IDBEAM    ! histogram ID for the beam (=0 - fixed energy) 
     +         ,NHBEA     ! number of bins in IDBEAM (calculated)
     +         ,IBEATYP   ! =0 fixed energy, =1 - Bremsstrahlung spectrum, =2 user-defined
     +         ,IFPYTH    ! PYTHIA is used
     +         ,LISTPYTH  ! (F) 0 - nothing; (print at the initialization phase)
C                             -11 or -12: at PYLIST(11) or PYLIST(12) 
C                               1 - only particles with masses < AMLIST 
C                               2 - as 1 plus the decay modes for decaying particles
C                               3 - as 2 plus decay modes for not decaying particles
     +         ,IDLOWEN   ! <>0 - starting ID of histograms for the low energy generator
     +         ,ISIMUL    ! (F) =0 - regular BGGEN (background low_en+PYTHIA), =1 - J/psi
     +         ,IPINIT    ! 1:2 initial particles GEANT numbers (1 - photon, 14 - proton) (F)
     +         ,IRADCORR  ! =0 - no final state radiation (F)
C                           ip1 ip2 ip3 .... (>0) use PHOTOS to the decays of the particles ip1 - GEANT types ( as 7 for pi0)
     +         ,NRADCOR   ! calculated number of consequent. non-zeroes from IRADCORR
     +         ,IDTDIST   ! <>0 - starting ID of histograms for t-distributions for ISIMUL>0 (exclusive production)
     +         ,KFEVSEL   ! (F) kf1 kf2 kf3 ... kf5 select events that contain particles kf1 (kf<>0) AND kf2 AND ... 
C                                                (see the KF code), useful for PYTHIA
     +         ,NFEVSEL   ! (F) (i) - the exact number of particles of KFEVSEL(i) type, =0 - at least one particle 
     +         ,NFEFINAL  ! (F) >0 - the number of particles in the final state (KS = 1)
     +         ,NUCLTARG  ! (F) >0 A of the nuclear target for "quasielastic" reactions, say 4 or 12 or 56 or 197 
     +         ,IGNUCLT   ! calculated: >0 ig (GEANT) number for the target nucleus (optional, gives the correct mass)
     +         ,IDNUCLT   ! >0 ID for the histogram for the spectral function (if NUCLTARG>0) 
      REAL      EPH_LIM ! limits on the photon beam energy GeV (F)
     +         ,PHLIM   ! beam momentum (=energy for photons) spectrum histogram x limits
     +         ,EELEC   ! electron beam energy (F)
     +         ,EPEAK   ! energy of the coherent peak (the right edge) (F) 
     +         ,DCOLL   ! collimator diameter (m) (F)
     +         ,ZCOLL   ! distance to the collimator (cm) (F)
     +         ,EEMIT   ! emittance of the electron beam (m rad) (F)
     +         ,RADT    ! thickness of the diamond radiator (m) (F)
     +         ,EPYMIN  ! minimal energy for PYTHIA, (F)
C                         below that the low energy generator is used
C                         the value may be adjusted to the bin boundary of IDBEA
     +         ,ELOWMIN ! minimal energy for the low energy generator (F) 
     +         ,RATESEC ! reference interation rate (Hz), calculated
     +         ,VERTEX  ! Vertex set in HDDM output file (cm)  n.b. 0,0,0 is the default which means hdgeant will use its default, 0,0,65
     +         ,AMLIST  ! (F) (def=6.) if LISTPYTH>0 - print only particles with mass < AMLIST
     +         ,PAREVSEL ! (F) _Pmin P_max theta_min theta_max (degrees) of particles to select (see KFEVSEL)
     +         ,AMNUCLS  ! mass of the nucleus (for NUCLTARG>0)
     +         ,AMNUCLN  ! average mass of the nucleon in this nucleus (for NUCLTARG>0)
     +         ,SFSCALE  ! (F) default =1. scale factor for the "Fermi" momentum and removal energy, for testing
C
