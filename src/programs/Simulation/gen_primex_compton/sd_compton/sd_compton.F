CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                 C
C   Main Progrilasam that integrates radiative	  C
C   corrections to Klein-Nishina and generates	  C
C   appropriate final state distributions.	  C
C                                                 C
C   PART I : Virtual/Soft Corrections + K-N       C
C   PART II: Hard Corrections                     C
C        					  C
C   Code uses BASES/SPRING v5.1			  C
C                                                 C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

	program main
C
	implicit real*8 (a-h,o-z)
C
	include 'hbook.inc'
	include 'constants.inc'
	include 'kinem.cmn'
C
        real*8 E0,Br(500),dEg
	integer*8 i,j,imax,ipoint
	logical brem_init,cobrems
C
	integer ic
	real tmin,tmax
	real etag(400)
C
	integer      iargc
C
	integer opt
C
	integer*4    lenocc
	external     lenocc
C
	external bornfd
	external vsoftfd
	external hardfd
C
	character*20 str_ifirst
	character*20 str_ilast
	character*20 str_eg
	character*20 str_evtnb
	character*20 str_chnb
	character*20 str_opt
	character*80 infile
	character*80 tagfile
	character*80 outfile
	character*80 binfile
	character*80 hbkfile
	character*80 fileroot
C
	real*8 csec1
	real*8 csec2
C
	real*8 egam
C
	integer pos
	save pos
	data pos /1/
C
        if (iargc().NE.7) then
	   print*, '===> USAGE: comprc inputfile outfile egam [GeV] evtnb tagfile chnb opt<==='
	   print*, '            if opt=0 use egam'
	   print*, '            if opt=1 use etag(chnb)'
	   print*, '            if opt not 0 or 1 use all etag(i)'
	   stop
	endif
	call getarg(1,infile)
	call getarg(2,outfile)
	call getarg(3,str_eg)
	call getarg(4,str_evtnb)
	call getarg(5,tagfile)
	call getarg(6,str_chnb)
	call getarg(7,str_opt)
	read(str_Eg,*) eg
	read(str_evtnb,*) evtnb
	read(str_chnb,*) chnb
	read(str_opt,*) opt
 1000	format(I3)
C
	call hlimit(iPawSize)
	call init_parms(infile)
C
	print*,'infile ',infile
	print*,'outfile ',outfile
	print*,'str_eg ',eg
	print*,'str_evtnb ',evtnb
	print*,'str_chnb ',chnb
C
	if (chnb>0) then
	   print*,'tagfile ',tagfile,' ch nb ',chnb
	   open(24, file=tagfile,form='formatted', status='old')
	   do i = 1, chnb
	      read(24,'(1(i6,1x),5(x,F15.6))')ic,tmin,tmax
*       
	      etag(i) = eg*(tmin+tmax)/2
	      print*,'ic ', ic,' tmin ',tmin,' tmax ',tmax,' eg ',etag(i)
	   enddo
	   close(24)
	endif
	if (opt==0) then
	   chnb = 1
	   etag(1) = eg 
	   print*,'no tagfile ',tagfile,' ch nb ',chnb, ' eg ',eg
	endif
	if (opt==1) then
	   etag(1) = etag(chnb)
	   chnb = 1
	   print*,'no tagfile ',tagfile,' ch nb ',chnb, ' eg ',eg
	endif
C       
	ipos = index(outfile,'.')
	if (ipos.EQ.0) then
	   fileroot = outfile(1:lenocc(outfile))
	   outfile = fileroot(1:lenocc(fileroot))//'.dat'
	   binfile = fileroot(1:lenocc(fileroot))//'.bin'
	   hbkfile = fileroot(1:lenocc(fileroot))//'.hbook'
	else
	   fileroot = outfile(1:ipos)
	   outfile = fileroot(1:lenocc(fileroot))//'.dat'
	   binfile = fileroot(1:lenocc(fileroot))//'.bin'
	   hbkfile = fileroot(1:lenocc(fileroot))//'.hbook'
	endif
C
C       Open a text file for writing results ...
C
	open(unit=ichtxt, file=outfile, status='unknown', iostat=iok)
	if(iok.ne.0) then
	   write(6,*) 'Not able to open ',outfile(1:lenocc(outfile)),' !'
	   stop 
	endif
C
C       Open a binary file to transfer results to gkprim ...
C
	open(unit=ichbin, form='unformatted', recl=reclen, access='direct', file=binfile,
     &       status='unknown', iostat=iok)
	if(iok.ne.0) then
	   write(6,*) 'Not able to open ',binfile(1:lenocc(binfile)),' !'
	   stop 
	endif
C
	mxtry = 50
C
	if (nton) then
	   call NtupleInit(hbkfile)
	   write(*,*)'Filling in file: ',hbkfile(1:lenocc(hbkfile))
	endif
C
	do iEbin = chnb, 1, -1
	   egam=etag(iEbin)
	   print*, egam
C
	   call bsinit
C       
	   ndim  = 2
	   nwild = 1
C       
C       Cosine theta of the scattered photon
	   xl(2) = -1.0d0
	   xu(2) =  1.0d0
C       
C       Energy of the initial photon
	   xl(1) = egam
	   xu(1) = egam + dE
C
	   call init_parms(infile)
	   acc1 = acc(1)
	   acc2 = acc(2)
	   itmx1 = itmx(1)
	   itmx2 = itmx(2)
	   call bsparm(ncall, acc1, acc2, itmx1, itmx2)
C
	   call bases(bornfd, vint, sigma, ctime, it1, it2)
	   print*,' Value of integral = ',vint*0.389379, ' mb'
	   print*,' Standard deviation = ',sigma*0.389379, ' mb'
C
	   write(ichtxt, *) xl(1), xu(1), vint*0.389379*(egam+0.5*dE)/dE, sigma, ievent-1
C
	   call spinfo(6)
C
	   call bsinit
C       
	   ndim  = 2
	   nwild = 1
C       
C       Cosine theta of the scattered photon
	   xl(2) = -1.0d0
	   xu(2) =  1.0d0
C       
C       Energy of the initial photon
c	   xl(1) = Elow(iEbin)
c	   xu(1) = Elow(iEbin) + dE
	   xl(1) = egam
	   xu(1) = egam + dE
C
	   call init_parms(infile)
	   acc1 = acc(1)
	   acc2 = acc(2)
	   itmx1 = itmx(1)
	   itmx2 = itmx(2)
	   call bsparm(ncall, acc1, acc2, itmx1, itmx2)
C
	   call bases(vsoftfd, vint, sigma, ctime, it1, it2)
	   print*,' Value of integral = ',vint*0.389379, ' mb'
	   print*,' Standard deviation = ',sigma*0.389379, ' mb'
C
	   csec1 = vint
C
	   if (nton) then
	      corr = 0.0
	      ievent = 1
c	      DO 100 WHILE (ievent.LE.mxevnt)
	      DO 100 WHILE (ievent.LE.evtnb)
		 do i = 1, 4
		    Pe1(i) = 0.d0
		    Pg1(i) = 0.d0
		    Pg2(i) = 0.d0
		 enddo
		 call spring(vsoftfd, mxtry)
		 call comp_kin
		 call accept
C       
		 write(ichbin, rec=pos) chnb-iEbin, sngl(Egamma), 
	1	      sngl(Pe1(1)),sngl(Pe1(2)),sngl(Pe1(3)),
	2	      sngl(Pg1(1)),sngl(Pg1(2)),sngl(Pg1(3)),
	3	      sngl(Pg2(1)),sngl(Pg2(2)),sngl(Pg2(3))
		 pos = pos + reclen
		 call NtupleFill(iun_ntu)
		 if (mod(ievent,10000).EQ.0) print*, 'Event No. ',ievent
		 ievent = ievent + 1
 100	      continue
	   endif
C       
	   write(ichtxt, *) xl(1), xu(1), vint*0.389379*(egam+0.5*dE)/dE, sigma, ievent-1
C
	   call spinfo(6)
C
	   call bsinit
C
	   if (.true.) then
	   ndim  = 5
	   nwild = 3
C       
C       First wild variable: Energy of the hard photon
	   xl(1) = 0.0d0
	   xu(1) = 1.0d0
C       
C       Second wild variable: cos(theta) of the first photon
	   xl(2) = 0.0d0
	   xu(2) = 1.0d0
C       
C       Third wild variable: cos(theta) of the second photon
	   xl(3) = 0.0d0
	   xu(3) = 1.0d0
C       
C       Phi angle between two photons
	   xl(4) = 0.0d0
	   xu(4) = 2 * pi
C       
C       Energy of the initial photon
	   xl(5) = egam
	   xu(5) = egam + dE
C
	   call init_parms(infile)
	   acc1 = acc(3)
	   acc2 = acc(4)
	   itmx1 = itmx(3)
	   itmx2 = itmx(4)
	   call bsparm(ncall, acc1, acc2, itmx1, itmx2)
C
	   call bases(hardfd, vint, sigma, ctime, it1, it2)
	   print*,' Value of integral = ',vint*0.389379, ' mb'
	   print*,' Standard deviation = ',sigma*0.389379, ' mb'
C
	   csec2 = vint
c	   mxevnt = nint(csec2 * mxevnt / csec1)
	   mxevnt = nint(csec2 * evtnb / csec1)
	   vsoftcorr = 0.d0
	   print*,' Number of events to generate: ',mxevnt
	   ievent = 1
C
	   if (nton) then
	      corr = 1.0
	      DO 200 WHILE (ievent.LE.mxevnt)
		 do i = 1, 4
		    Pe1(i) = 0.d0
		    Pg1(i) = 0.d0
		    Pg2(i) = 0.d0
		 enddo
		 call spring(hardfd, mxtry)
		 call hard_kin
		 call accept
C       
		 write(ichbin, rec=pos) chnb-iEbin, sngl(Egamma), 
	1	      sngl(Pe1(1)),sngl(Pe1(2)),sngl(Pe1(3)),
	2	      sngl(Pg1(1)),sngl(Pg1(2)),sngl(Pg1(3)),
	3	      sngl(Pg2(1)),sngl(Pg2(2)),sngl(Pg2(3))
		 pos = pos + reclen
		 call NtupleFill(iun_ntu)
		 if (mod(ievent,10000).EQ.0) print*, 'Event No. ',ievent
		 ievent = ievent + 1
 200	      continue
	   endif
C
	   write(ichtxt, *) xl(5), xu(5), vint*0.389379*(egam+0.5*dE)/dE, sigma, ievent-1
C
	   call spinfo(6)

	   endif
C
	enddo
C       
	close(ichtxt)
	close(ichbin)
	if (nton) call NtupleClose(hbkfile)
C
	stop
	end
