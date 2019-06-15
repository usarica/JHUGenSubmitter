#!/bin/sh


TARFILE="jhugensub.tar"
echo "SCRAM_ARCH: ${SCRAM_ARCH}"

HERE=$(pwd)

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
src/CMSDataTools \
src/JHUGenSubmitter \
--exclude=lib/${SCRAM_ARCH}/* \
--exclude=src/JHUGen/JHUGenMELA/MELA/test \
--exclude=src/JHUGen/JHUGenerator/VBFoffshell_test \
--exclude=src/JHUGen/JHUGenerator/VBFoffshell_orig \
--exclude=src/JHUGen/JHUGenerator/tmp \
--exclude=src/JHUGen/MCFM-JHUGen \
--exclude={.git,.gitignore,*.tar,libmcfm*,libjhugenmela*,libcollier*,NNPDF30_lo_as_0130.LHgrid,*.so,*.o,*mod,mstw*,DONE}

mv $TARFILE $HERE/

popd
