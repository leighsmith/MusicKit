/* 
  $Id$
  Description:
    Include file for standard system include files,
    or project specific include files that are used frequently, but are changed infrequently

  Original Author: Leigh M. Smith, tomandandy <leigh@tomandandy.com>

  30 July 1999, Copyright (c) 1999 tomandandy.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.

  Just to cover my ass: DirectMusic and DirectX are registered trademarks
  of Microsoft Corp and they can have them.
*/
/*
 $Log$
 Revision 1.1  1999/11/17 17:57:14  leigh
 Initial revision

*/
//

#if !defined(AFX_STDAFX_H__0DBA4822_46A0_11D3_93E2_00A0CC26DBF7__INCLUDED_)
#define AFX_STDAFX_H__0DBA4822_46A0_11D3_93E2_00A0CC26DBF7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


// Insert your headers here
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers

//#include <windows.h>

// TODO: reference additional headers your program requires here

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

// additional headers we require.

#define VC_EXTRALEAN		// Exclude rarely-used stuff from Windows headers

// these may cause link problems.
#include <afxwin.h>         // MFC core and standard components
#include <afxext.h>         // MFC extensions
#include <afxdisp.h>        // MFC OLE automation classes
#ifndef _AFX_NO_AFXCMN_SUPPORT
#include <afxcmn.h>			// MFC support for Windows Common Controls
#endif // _AFX_NO_AFXCMN_SUPPORT

#include <mmsystem.h>
#include <mmreg.h>

#endif // !defined(AFX_STDAFX_H__0DBA4822_46A0_11D3_93E2_00A0CC26DBF7__INCLUDED_)






