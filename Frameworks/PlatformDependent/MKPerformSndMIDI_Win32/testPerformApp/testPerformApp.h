// testPerformApp.h : main header file for the TESTPERFORMAPP application
//

#if !defined(AFX_TESTPERFORMAPP_H__57533764_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_)
#define AFX_TESTPERFORMAPP_H__57533764_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppApp:
// See testPerformApp.cpp for the implementation of this class
//

class CTestPerformAppApp : public CWinApp
{
public:
	CTestPerformAppApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTestPerformAppApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CTestPerformAppApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_TESTPERFORMAPP_H__57533764_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_)
