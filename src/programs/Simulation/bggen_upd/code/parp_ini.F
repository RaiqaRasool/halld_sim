      SUBROUTINE PARP_INI(IAD,VAL)
C
C---    For PYTHIA: set a PARP value
C
      IMPLICIT NONE
      INTEGER IAD
      REAL VAL
C
      INCLUDE 'include/pypars.inc'
C
C      PARP(2)=2.  ! should be set in pythia.dat
      IF(IAD.GT.0.AND.IAD.LE.200) THEN
         PARP(IAD)=VAL
      ENDIF
      END
