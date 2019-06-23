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
  string const strMatch_htccopyend = "end copying output";

  //for (int i=0; i<argc; i++) cout << "arg[" << i << "]: " << argv[i] << endl;

  if (argc<2) return 0;

  ifstream fin;
  fin.open(argv[argc-1]);

  if (fin.good()){
    //int fline = 0;

    bool writeXsec = false;
    bool inside_htccopy = false;
    bool htccopy_success=false;
    string site_htc_copy="";
    string dir_htc_copy="";
    string file_htc_copy="";

    while (!fin.eof()){
      string strin="";
      getline(fin, strin);/* fline++;*/
      cout << "Analyzing " << strin << endl;

      if (!writeXsec && strin.find(strMatch_xsec.c_str())!=string::npos){
        vector<string> linesplit;
        splitOptionRecursive(strin, linesplit, ' ', false);
        {
          size_t ipos=0;
          for (auto const& tl:linesplit){
            cout << tl << endl;
            if (tl=="+-") break;
            ipos++;
          }
          //cout << "xsec: " << linesplit.at(ipos-1) << "\n" << "xsec_error: " << linesplit.at(ipos+1) << endl;
        }
        writeXsec = true;
      }

      if (inside_htccopy){
        if (strin.find(strMatch_htccopyend.c_str())!=string::npos){
          if (!htccopy_success) cout << "Failed to copy " << site_htc_copy << ':' << dir_htc_copy << '/' << file_htc_copy << endl;
          else cout << "Successful to copy " << site_htc_copy << ':' << dir_htc_copy << '/' << file_htc_copy << endl;
          inside_htccopy=htccopy_success=false;
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
      }
      else if (strin.find(strMatch_htccopybegin.c_str())!=string::npos) inside_htccopy=true;

    }
  }

  fin.close();
}
