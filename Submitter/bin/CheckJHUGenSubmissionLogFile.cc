#include <string>
#include <sstream>
#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip>
#include <cstdlib>
#include "HostHelpersCore.h"
#include "HelperFunctions.h"


using namespace std;
using namespace HostHelpers;
using namespace HelperFunctions;


int main(int argc, char** argv){
  string const strMatch_xsec = "Total xsec with weights (use for physics)";

  string const strMatch_htccopybegin = "Copy from Condor is called with";
  string const strMatch_htccopyoutsite = "OUTPUTSITE";
  string const strMatch_htccopyoutdir = "OUTPUTDIR";
  string const strMatch_htccopyfname = "RENAMEFILE";
  string const strMatch_htccopysuccess = "Copied successfully";
  string const strMatch_htccopyfail = "Removing output file because gfal-copy crashed with code ";
  string const strMatch_htcrmfail = "gfal-copy crashed and then the gfal-rm also crashed with code ";
  string const strMatch_htccopyend = "end copying output";
  string const strMatch_htccopyend_ALT = "Transfer crashed with exit code ";

  constexpr int iarg_offset=1; // argv[0]==[Executable name]
  for (int iarg=iarg_offset; iarg<argc; iarg++){
    cout << "CheckJHUGenSubmissionLogFile: Checking file " << argv[iarg] << endl;

    ifstream fin;
    fin.open(argv[iarg]);

    if (fin.good()){
      //int fline = 0;

      bool writeXsec = false;
      bool inside_htccopy = false;
      bool htccopy_success = false;
      bool htccopyfail_rmsuccess = false;
      string site_htc_copy="";
      string dir_htc_copy="";
      string file_htc_copy="";

      while (!fin.eof()){
        string strin="";
        getline(fin, strin);/* fline++;*/
        //cout << "Analyzing " << strin << endl;

        if (!writeXsec && strin.find(strMatch_xsec.c_str())!=string::npos){
          vector<string> linesplit;
          splitOptionRecursive(strin, linesplit, ' ', false);
          {
            size_t ipos=0;
            for (auto const& tl:linesplit){
              //cout << '|' << tl << '|' << endl;
              if (tl=="+-" || tl=="+/-") break;
              ipos++;
            }
            if (ipos!=0 && ipos!=linesplit.size()-1){
              string strinputfile = argv[iarg];
              vector<string> linesplit_strinputfile;
              splitOptionRecursive(strinputfile, linesplit_strinputfile, '/', false);
              string strfxsec="xsec.txt";
              if (linesplit_strinputfile.size()>1){
                strfxsec=strinputfile;
                replaceString<std::string, const std::string>(strfxsec, linesplit_strinputfile.back(), string("xsec.txt"));
              }
              ofstream fxsec(strfxsec.c_str());
              fxsec << "xsec: " << linesplit.at(ipos-1) << "\n" << "xsec_error: " << linesplit.at(ipos+1) << endl;
              cout << "=> xsec: " << linesplit.at(ipos-1) << " +- " << linesplit.at(ipos+1) << endl;
              fxsec.close();
            }
          }
          writeXsec = true;
        }

        if (inside_htccopy){
          if (
            strin.find(strMatch_htccopyend.c_str())!=string::npos
            ||
            strin.find(strMatch_htccopyend_ALT.c_str())!=string::npos
            ){
            if (!htccopy_success){
              cout << "=> Failed to copy " << site_htc_copy << ':' << dir_htc_copy << '/' << file_htc_copy;
              if (strin.find(strMatch_htccopyend_ALT.c_str())!=string::npos){
                vector<string> linesplit;
                splitOptionRecursive(strin, linesplit, ' ', false);
                if (!linesplit.empty()) cout << " with error code " << linesplit.back();
                if (!htccopyfail_rmsuccess) cout << " (failed to copy and remove the file)";
                else cout << " (failed to copy the file)";
              }
              cout << endl;
            }
            //else cout << "=> Successful to copy " << site_htc_copy << ':' << dir_htc_copy << '/' << file_htc_copy << endl;
            inside_htccopy=htccopy_success=htccopyfail_rmsuccess=false;
            site_htc_copy=dir_htc_copy=file_htc_copy="";
          }
          else if (strin.find(strMatch_htccopyoutsite.c_str())!=string::npos){
            vector<string> linesplit;
            splitOptionRecursive(strin, linesplit, ' ', false);
            if (linesplit.size()==2) site_htc_copy = linesplit.back();
          }
          else if (strin.find(strMatch_htccopyoutdir.c_str())!=string::npos){
            vector<string> linesplit;
            splitOptionRecursive(strin, linesplit, ' ', false);
            if (linesplit.size()==2) dir_htc_copy = linesplit.back();
          }
          else if (strin.find(strMatch_htccopyfname.c_str())!=string::npos){
            vector<string> linesplit;
            splitOptionRecursive(strin, linesplit, ' ', false);
            if (linesplit.size()==2) file_htc_copy = linesplit.back();
          }
          else if (strin.find(strMatch_htccopysuccess.c_str())!=string::npos){
            htccopy_success=FileReadable((dir_htc_copy+'/'+file_htc_copy).c_str());
          }
          else if (strin.find(strMatch_htccopyfail.c_str())!=string::npos){ htccopy_success=false; htccopyfail_rmsuccess=true; }
          else if (strin.find(strMatch_htcrmfail.c_str())!=string::npos) htccopyfail_rmsuccess=false;
        }
        else if (strin.find(strMatch_htccopybegin.c_str())!=string::npos) inside_htccopy=true;

      }
    }

    fin.close();
  }
}
