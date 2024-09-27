      program Tornado_GM_Haz45

      implicit none
      include 'tornado.h'
      
      real*8 haz(MAX_PROB, MAX_ATTENTYPE, MAX_ATTEN, MAX_INTEN)
      real haz_GMC(MAX_NODE, MAX_BR, MAX_INTEN) 
      real*8 haz1(MAX_INTEN), haz2(MAX_INTEN)
      real testInten(MAX_INTEN)
      integer nInten
      integer iInten, iBR, jj
      character*80 filein, file1,filebmode
      character*80 dummy
      integer attentype(MAX_FLT), nGM_model(MAX_PROB,MAX_ATTENTYPE), iFlag, iAttenType
      integer jAttenType, jAtten, jType, iAtten, kType, iNode1
      real wt_tree(MAX_NODE,MAX_BR), wt1(MAX_ATTENTYPE, MAX_ATTEN)

      real*4 hazmean(MAX_INTEN) 
      real*4 hazmean1(MAX_ATTENTYPE,MAX_INTEN)
      integer nProb, nSite, iSite
 
      real lgTestInten(MAX_INTEN), period
      integer bnum,bnumflag, ibnum
      real sum
      integer iPer, nAttenType
      real contrib_min
      integer iNode, nNode_GMC, iBR1, iBR2, iBR3, iBR4
      integer nBR_GMC(MAX_NODE)
      integer j, k, j2
      real gm_wt(MAX_ATTENTYPE,MAX_ATTEN)
      real ratio1, ratio2

      real hazLevel, GM_ratio(100), GM0, GM1
      integer kAtten(MAX_ATTENTYPE,MAX_MED,MAX_epistemic,MAX_SIGMA,2)
      
      write (*,*) '*****************************'
      write (*,*) '*    Tornado Code for GMC   *'
      write (*,*) '*   compatible with Haz45.3 *'
      write (*,*) '*        July 2021          *'
      write (*,*) '*****************************'

      write (*,*) 'Enter number of cases to run in batch mode.'
      write (*,*) '         (For a single run enter 0)'
      read (*,*) bnum
      if (bnum .eq. 0) then
          bnumflag = 0 
          bnum = 1
      else
          bnumflag = 1
      endif

      if ( bnumflag .eq. 1) then
         write (*,*) 'Enter the batch mode filename.'
         read (*,'(a80)') filebmode
         open (77,file=filebmode,status='old')
      endif
    
c     Start loop over number of batch mode runs
      do 2000 ibnum=1,bnum
         if (bnumflag .eq. 1) then
            write (*,*) 'Looping over Number of Batch Mode Cases: ', ibnum, bnum
         endif

c      if (bnumflag .eq. 0) then
         write (*,*) 'Enter the input file name'
         if (bnumflag .eq. 0 ) then
           read (*,'( A80)') filein
         else 
           read (77, '(a80)') filein
         endif
         
         open (31,file=filein,status='old')




!      write (*,*) 'Enter the input filename.'
!      
!      read (*,'(a80)') filein
!      open (31,file=filein,status='old')

      read (31,*) iPer
      read (31,*) contrib_min
      read (31,*) Hazlevel
 
c     Read Input File
      call RdInput ( nInten, testInten, lgTestInten, nGM_model, nAttenType, 
     1       attenType, nProb, iPer, gm_wt, period)

c     Read header
c      read (31,'( a80)') dummy
c      write (*,'( a80)') dummy
c      read (31,'( a80)') dummy
c      write (*,'( a80)') dummy

      nNode_GMC = nAttenType*4
      write (*,'( 2i5)') nNode_GMC, nAttenType
c     read the weights for the GMC logic tree (for each attenType)
      do iNode=1,nNode_GMC
        read (31,*,err=200) nBR_GMC(iNode), (wt_tree(iNode,iBR), iBR=1,nBR_GMC(iNode))
      enddo

c      write(*,*) 'OK to here'
        
c     Read in the nodes for GMC as given in the input file
      read (31,'( a80)') dummy        
      do iAttenType=1,nAttenType
       do j=1, nGM_model(iPer, iAttenType) 
         write (*,'( 2i5)') iAttenType, j
c        read Median branch, epistemic branch, sigma branch, mixture model branch
         read (31,*,err=201) iBR1, iBR2, iBR3, iBR4
         write(*,*) iBR1, iBR2, iBR3, iBR4
         kAtten(iAttenType,iBR1, iBR2, iBR3,iBR4) = j
       enddo
      enddo
     
      write(*,*) 'OK to here'     
      
      read (31,'( a80)') file1
      write (*,'( a80)') file1
      open (43,file=file1,status='unknown')
      write (43,'( ''45.3. GMC Tornado v45.3 output'')')
      write (43,'( ''GMC Nodes: 1 = Median, 2=Epistemic, 3=Sigma, 4=Mixture'')')
      write (43,'( 2x,''period index, period: '',i5, f10.4)') iPer, period
      write (43,'( 2x,''Min contribution to GM uncertainty: '',f10.5)') contrib_min
      write (43,'( 2x,''Hazard level: '',e12.4)') Hazlevel
      write (43,'( 2x,''Site, Node, GM ratios...'')')

      read (31,*) nSite
      write (*,*) nSite, ' nSite'

c     Loop Over Number of  sites d
      do 1000 iSite = 1, nSite

c      Read the out6 file
       write (*,'( 2x,''reading logic tree file out6'')')
       call read_logichaz_out6 ( haz, nProb,nAttenType, nGM_model, nInten, iSIte)
       write (*,'( 2x,''out of logichaz_out6'')')
     
            
c      Compute the mean hazard for each atten TYPE
       do jType=1,nAttenType
         do iInten=1,nInten
           sum = 0.
           do iAtten=1,nGM_Model(iPer,jType)
c           write(*,*) 'haz and wt, iPer,jType,iAtten,iInten', haz(iPer,jType,iAtten,iInten), gm_wt(jType,iAtten),iPer,jType,iAtten
             sum = sum + haz(iPer,jType,iAtten,iInten)*gm_wt(jType,iAtten)
           enddo
           hazMean1(jType,iInten) = sum
         enddo
c         do iAtten=1,nGM_Model(iPer,jType)
c           write (44,'( i5,20e12.3)') jtype, gm_wt(jType,iAtten), 
c     1      (haz(iPer,jType,iAtten,iInten),iInten=1,nInten )
c         enddo
c         write (*,'( i5,20e12.3)') jtype, (hazMean1(jType,iInten), iInten=1,nInten)
       enddo

c       Compute the mean total hazard
         do iInten=1,nInten
           hazmean(iInten) = 0.
         enddo
         
         do jType=1,nAttenType
           do iInten=1,nInten
             hazMean(iInten) = hazMean(iInten) + hazMean1(jType,iInten)
           enddo
         enddo
c         write (44,'( 5x,20e12.3)') (hazMean(iInten), iInten=1,nInten)


c      Initialize hazard array for sensitivity
       do iNode=1,nNode_GMC
        do iBR=1,NBR_GMC(iNode)
         do iInten=1,nInten
           haz_GMC(iNode,iBR,iInten) =  0.0
           
c           write(*,*) 'iNode,nNode_GMC,iBr,NBR_GMC,iInten,nInten',iNode,nNode_GMC,iBR,NBR_GMC(iNode),iInten,nInten
         enddo
        enddo
       enddo

c      Isolate each branch for each node and reset wt for one branch to unity
       do iNode=1,nNode_GMC
        do iBR=1,nBR_GMC(iNode)

c        First, reset the GMC Weights to starting values
         do jAttenType=1,nAttenType 
          do jAtten=1,nGM_model(iPer,jAttenType)     
           Wt1(jAttenType,jAtten) = gm_wt(jAttenType,jAtten)
          enddo
         enddo
         
          iAttenType = (iNode-1)/4 + 1
          iNode1 = iNode - ( (iNode-1)/4) * 4
          jj = (iAttenType-1) * 4

c          write (*,'( 3i5)') iNode, iBR, iAttenType
        
c        Reset the weight for the selected branch to unity and the others to zero
         do iBR1=1,nBR_GMC(1+jj)
          do iBR2=1,nBR_GMC(2+jj)
           do iBR3=1,nBR_GMC(3+jj)
            do iBR4=1,nBR_GMC(4+jj)
              jAtten = kAtten(iAttenType,iBR1,iBR2,iBR3,iBR4)
              write (*,'( 6i5)') iAttenType,iBR1,iBR2,iBR3,iBR4, jAtten
              
              iNode1 = iNode - ( (iNode-1)/4) * 4
              jj = (iAttenType-1) * 4

             if ( iNode1 .eq. 1) then
              if ( iBR1 .eq. iBR ) then
               wt1(iAttenType,jAtten) = wt_tree(jj+2,iBR2)*wt_tree(jj+3,iBR3)*wt_tree(jj+4,iBR4)
              else
               wt1(iAttenType,jAtten) = 0.
              endif
             endif

             if ( iNode1 .eq. 2) then
              if ( iBR2 .eq. iBR ) then
               wt1(iAttenType,jAtten) = wt_tree(jj+1,iBR1)*wt_tree(jj+3,iBR3)*wt_tree(jj+4,iBR4)
              else
               wt1(iAttenType,jAtten) = 0.
              endif
             endif

             if ( iNode1 .eq. 3) then
              if ( iBR3 .eq. iBR ) then
               wt1(iAttenType,jAtten) = wt_tree(jj+1,iBR1)*wt_tree(jj+2,iBR2)*wt_tree(jj+4,iBR4)
              else
               wt1(iAttenType,jAtten) = 0.
              endif
            endif
            
            if ( iNode1 .eq. 4) then
              if ( iBR4 .eq. iBR ) then
               wt1(iAttenType,jAtten) = wt_tree(jj+1,iBR1)*wt_tree(jj+2,iBR2)*wt_tree(jj+3,iBR3)
              else
               wt1(iAttenType,jAtten) = 0.
              endif
            endif
           enddo
          enddo
         enddo
         enddo
            
c        Compute the hazard for the modified weights         
         do iInten=1,nInten
           sum = 0.
           do iAtten=1,nGM_model(iPer,iAttenType)
             sum = sum + haz(iPer,iAttenType,iAtten,iInten)*wt1(iAttenType,iAtten)
c             if ( iInten .eq. 7 ) write (45,'( 4i5,f10.4,e12.4)') inode, ibr, iAtten,iAttenType,
c     1         wt1(iAttenType,iAtten)  , haz(iPer,iAttenType,iAtten,iInten)  
           enddo
           haz1(iInten) = sum
           haz2(iInten) = sum

c          Add the mean hazard from the other source types to get the total hazard                               
           do kType=1,nAttenType
c           write(*,*) 'kType, nAttenType', kType, nAttenType
             if ( kType .ne. iAttenType ) then
                haz2(iInten) =   haz2(iInten)  + hazMean1(kType,iInten)
             endif
           enddo
         enddo   

         do iInten=1,nInten
              haz_GMC(iNode,iBR,iInten) = sngl(haz2(iInten))
         enddo
         
        enddo
       enddo

c       Write out sensitivity hazard curves for GMC
        read (31,'( a80)') file1
        open (42,file=file1,status='unknown')
        write (42,'( ''45.1 GMC Tornado v45.1 sensitivity output'')')
        write (42,'( ''GMC Nodes: 1 = Median, 2 = Epistemic, 3 = Sigma, 4 = Mixture'')')

        write (42,'( 2x,'' Z values:'')')
        write(42,'(6x,25f12.4)') (testInten(J2),J2=1,nInten)
        write (42,'( 2x,''Mean hazard'')')
        write(42,'( 25e12.4)') (hazmean(j),j=1,nInten)

        write (42,'( /,2x,''Sensitivity hazard'')')
        write (42,'( 2x,''Number of Nodes, Number of Branches for each Node'')')
        write (42,'( 2x,'' iNode, iBranch, hazard(z) '')')
        
c        write(*,*) 'nNode_GMC nBR_GMC',nNode_GMC,nBR_GMC(iNode)
        
         do iNode=1,nNode_GMC
          do iBR=1,nBR_GMC(iNode)
            if ( nBR_GMC(iNode) .eq. 1 ) goto 990
            write (42,'( 6x, 2i5,25e12.4)') iNode, iBR, (haz_GMC(iNode,iBR,iInten),iInten=1,nInten)
 990        continue
          enddo
         enddo
        close (42)
        

c      Interpolate the desired hazard level for tornado plot
c      First find the GM for the mean hazard, interpolated to desired haz level
       iFlag = 0
       do iInten=2,nInten
         if ( hazmean(iInten-1) .ge. hazLevel .and. hazmean(iInten) .le. hazLevel ) then
          GM0 = exp( alog(hazLevel / hazmean(iInten-1)) / 
     1                  alog( hazmean(iInten)/ hazmean(iInten-1))
     2                  * alog( testInten(iInten)/testInten(iInten-1) ) + alog(testInten(iInten-1)) )
         iFlag = 1
         endif
        enddo
         
         if (iFlag .eq. 0) then 
           write (*,'(''Hazard level outside of hazard curves'')')
           stop 99
         endif
         
         do iNode=1,nNode_GMC

          k = 0
          do iBR=1,nBR_GMC(iNode)
            if ( nBR_GMC(iNode) .eq. 1 ) goto 995
 
c           Interpolate
            k = k + 1
            GM_ratio(k) = -999.
            do iInten=2,nInten
              if ( haz_GMC(iNode,iBR,iInten-1) .ge. hazLevel
     1        .and. haz_GMC(iNode,iBR,iInten)  .le. hazLevel ) then
                 GM1 = exp( alog(hazLevel / haz_GMC(iNode,iBR,iInten-1)) / 
     1                  alog( haz_GMC(iNode,iBR,iInten)/ haz_GMC(iNode,iBR,iInten-1))
     2                  * alog( testInten(iInten)/testInten(iInten-1) ) + alog(testInten(iInten-1)) )
                 GM_ratio(k) = GM1 / GM0
                 goto 995 
              endif
            enddo
 995        continue
          enddo

c         Check if the range is large enought to be relevant
          ratio1 = 1 - contrib_min
          ratio2 = 1 + contrib_min
          
c          write(*,*) ratio1, ratio2
          iFlag = 0
          do iBR=1,k
c              write(*,*)  GM_ratio(iBr)
            if (GM_ratio(iBR) .gt. 0. ) then
              if ( GM_ratio(iBR) .lt. ratio1 .or. GM_ratio(iBR) .gt. ratio2 ) iFlag = 1         
            endif
          enddo
          if ( iFlag .eq. 1 ) write (43,'( 6x, 2i5,25f10.3)') iSite, iNode,  (GM_ratio(iBR), iBR=1,k)
         enddo

 1000 continue
 2000 continue
      write (*,*) 
      write (*,*) '*** Tornado Code (45) Completed with Normal Termination ***'
      stop

 200  write (*,'( 2x,''Error in reading the branch weights, iNode'', i5)') iNode
      stop
 201  write (*,'( 2x,''Error in reading the branch indexes, iAttenType, j:'', 2i5)') iAttenType, j
      stop
      
      end

