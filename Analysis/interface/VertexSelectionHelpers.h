#ifndef VERTEXSELECTIONHELPERS_H
#define VERTEXSELECTIONHELPERS_H


#include "VertexObject.h"


namespace VertexSelectionHelpers{
  constexpr float vtx_rho_thr = 2.;
  constexpr float vtx_z_thr = 24.;
  constexpr float vtx_ndof_thr = 5.;

  enum SelectionBits{
    kGoodVertex=0
  };

  bool testGoodVertex(VertexObject const& vtx);

  void setSelectionBits(VertexObject& vtx);

}


#endif