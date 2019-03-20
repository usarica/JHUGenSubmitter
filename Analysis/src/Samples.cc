#include <cassert>
#include <string>
#include <stdexcept>
#include "Samples.h"
#include "MELAStreamHelpers.hh"


namespace SampleHelpers{
  int theDataYear=2016;
  DataVersion theDataVersion=kCMSSW_8_0_X;
  TString theDataPeriod="2016"; // Initialize the extern here to 2016
  TString theInputDirectory=""; // Initialize the extern here to empty string
}


using namespace std;
using namespace MELAStreamHelpers;


bool SampleHelpers::testDataPeriodIsLikeData(){
  int try_year=-1;
  bool has_exception = false;
  try{ try_year = std::stoi(theDataPeriod.Data()); }
  catch (std::invalid_argument& e){ has_exception = true; }
  if (!has_exception && try_year>0){
    // Check if the data period string contains just the year
    if (theDataPeriod == Form("%i", try_year)) return false;
    else{
      const char test_chars[]="ABCDEFGHIJK";
      const unsigned int n_test_chars = strlen(test_chars);
      for (unsigned int ic=0; ic<n_test_chars; ic++){
        TString test_data_period = Form("%i%c", try_year, test_chars[ic]);
        if (theDataPeriod.Contains(test_data_period)) return true;
      }
      return false;
    }
  }
  else return false;
}

std::vector<TString> SampleHelpers::getValidDataPeriods(){
  std::vector<TString> res;
  if (theDataYear == 2016) res = std::vector<TString>{ "2016B", "2016C", "2016D", "2016E", "2016F", "2016G", "2016H" };
  else if (theDataYear == 2017) res = std::vector<TString>{ "2017B", "2017C", "2017D", "2017E", "2017F" };
  else if (theDataYear == 2018) res = std::vector<TString>{ "2018A", "2018B", "2018C", "2018D" };
  else{
    MELAerr << "SampleHelpers::getValidDataPeriods: Data periods for year " << theDataYear << " are undefined." << endl;
    assert(0);
  }
  return res;
}

float SampleHelpers::getIntegratedLuminosity(TString const& period){
  // To install brilcalc, do
  // export PATH=$HOME/.local/bin:/cvmfs/cms-bril.cern.ch/brilconda/bin:$PATH
  // pip install brilws --user --upgrade (pip install brilws --user if running for the first time)
  // and then run the different brilcalc lumi ... commands
  // Using brilcalc lumi --normtag /cvmfs/cms-bril.cern.ch/cms-lumi-pog/Normtags/normtag_PHYSICS.json -u /fb -i /afs/cern.ch/cms/CAF/CMSCOMM/COMM_DQM/certification/Collisions16/13TeV/Final/Cert_271036-284044_13TeV_PromptReco_Collisions16_JSON.txt
  if (period == "2016") return 35.882515397;
  else if (period == "2016B") return 5.711130443;
  else if (period == "2016C") return 2.572903492;
  else if (period == "2016D") return 4.242291558;
  else if (period == "2016E") return 4.025228139;
  else if (period == "2016F") return 3.104509131;
  else if (period == "2016G") return 7.575824256;
  else if (period == "2016H") return 8.650628378;
  // Using brilcalc lumi --normtag /cvmfs/cms-bril.cern.ch/cms-lumi-pog/Normtags/normtag_PHYSICS.json -u /fb -i /afs/cern.ch/cms/CAF/CMSCOMM/COMM_DQM/certification/Collisions17/13TeV/ReReco/Cert_294927-306462_13TeV_EOY2017ReReco_Collisions17_JSON.txt
  else if (period == "2017") return 41.529152052;
  else if (period == "2017B") return 4.793969901;
  else if (period == "2017C") return 9.632746391;
  else if (period == "2017D") return 4.247792713;
  else if (period == "2017E") return 9.314581018;
  else if (period == "2017F") return 13.540062029;
  //// Using brilcalc lumi --normtag /cvmfs/cms-bril.cern.ch/cms-lumi-pog/Normtags/normtag_PREAPPROVED.json -u /fb -i /afs/cern.ch/cms/CAF/CMSCOMM/COMM_DQM/certification/Collisions18/13TeV/PromptReco/Cert_314472-325175_13TeV_PromptReco_Collisions18_JSON.txt
  // Using brilcalc lumi --normtag /cvmfs/cms-bril.cern.ch/cms-lumi-pog/Normtags/normtag_PHYSICS.json -u /fb -i /afs/cern.ch/cms/CAF/CMSCOMM/COMM_DQM/certification/Collisions18/13TeV/ReReco/Cert_314472-325175_13TeV_17SeptEarlyReReco2018ABC_PromptEraD_Collisions18_JSON.txt
  else if (period == "2018") return 59.740565209;
  else if (period == "2018A") return 14.027614284;
  else if (period == "2018B") return 7.066552173;
  else if (period == "2018C") return 6.898816878;
  else if (period == "2018D") return 31.747581874;
  else if (period == "2018_HEMaffected") return 38.662770627;
  else{
    MELAerr << "SampleHelpers::getIntegratedLuminosity(" << period << "): Period is not defined." << endl;
    assert(0);
    return -1;
  }
}
