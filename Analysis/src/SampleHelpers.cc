#include "SampleHelpers.h"
#include "HelperFunctions.h"


using namespace std;
using namespace HelperFunctions;



namespace SampleHelpers{
  const DatasetInfoExtractor datasetInfoExtractor=setupDatasetInfoExtractor();
}

DatasetInfoExtractor SampleHelpers::setupDatasetInfoExtractor(){
  DatasetInfoExtractor res;
  res.loadFromFile(TString(CMSTASCOREPKGPATH + "Tools/datasetinfo/scale1fbs.txt").Data());
  return res;
}
float SampleHelpers::getDatasetXsec(const TString& strsample, const TString& strtag){ return datasetInfoExtractor.getXsecFromFile(strsample.Data(), strtag.Data()); }

TString SampleHelpers::getDatasetDirectoryName(FrameworkOptionParser const& opts){
  std::string sname = opts.sampleName();
  std::string stag = opts.sampleTag();
  if (sname.find('/')==0) sname.replace(0, 1, "");
  bool replaceAllSlashes=true;
  do{
    replaceAllSlashes = replaceString<std::string, const char*>(sname, "/", "_");
  }
  while (replaceAllSlashes);
  return Form("%s_%s", sname.c_str(), stag.c_str());
}

void SampleHelpers::setupUsingOptions(FrameworkOptionParser const& opts){
  setDataPeriod(opts.dataPeriod().c_str());
  setInputDirectory(opts.inputDir().c_str());
}
