#!/bin/sh


TARFILE="jhugensub.tar"
echo "SCRAM_ARCH: ${SCRAM_ARCH}"

HERE=$(pwd)
echo "The tarball will appear in $HERE"

pushd $CMSSW_BASE

# Check metis/UserTarball for which directories to include from CMSSW_BASE
# Or just use it
tar Jcvf ${TARFILE} \
lib \
biglib \
cfipython \
config \
external \
bin \
src/JHUGen \
src/ZZMatrixElement \
src/CMSDataTools \
src/JHUGenSubmitter \
--exclude=lib/${SCRAM_ARCH}/* \
--exclude=src/JHUGenSubmitter/Submitter/test/output \
--exclude=src/JHUGen/JHUGenerator/output \
--exclude=src/JHUGen/JHUGenMELA/MELA/test \
--exclude=src/JHUGen/JHUGenerator/VBFoffshell_test \
--exclude=src/JHUGen/JHUGenerator/VBFoffshell_orig \
--exclude=src/JHUGen/JHUGenerator/tmp \
--exclude=src/JHUGen/MCFM-JHUGen/Bin/mcfm \
--exclude=src/ZZMatrixElement/MELA/test/reference \
--exclude=src/HiggsAnalysis/CombinedLimit/data \
--exclude={.git,.gitignore,*.tar,libmcfm*,libjhugenmela*,libcollier*,NNPDF30_lo_as_0130.LHgrid,*.so,*.o,*.f~,*mod,mstw*.dat,*.err,*.sub,log*,Logs,DONE}

mv $TARFILE $HERE/

popd
